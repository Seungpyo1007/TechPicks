import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tp_tokens.dart';
import 'package:flutter/widgets.dart';

import '../../app/theme/tp_motion.dart';
import 'tp_press.dart';

/// 눌림에 붙는 촉각 신호.
enum TpHaptic {
  /// 없음. 목록 안에서 수십 번 울릴 자리에 쓴다.
  none,

  /// 고르는 것 — 칩, 탭, 설정 줄.
  selection,

  /// 무언가 일어나는 것 — 버튼.
  impact,
}

/// 손가락이 닿은 순간부터 뗄 때까지를 0–1 하나로 내주는 위젯.
///
/// **그리는 방법은 안 정한다.** 밝기든 크기든 배경이든 [builder] 가 정한다.
/// 앱의 모든 눌림이 이걸 쓴다.
///
/// ## 왜 새로 만들었나
///
/// 여태 눌림은 `GestureDetector.onTapDown` 이었는데, 스크롤 안에서는 그게
/// **100ms 늦게** 온다. Flutter 의 탭 인식기는 `kPressTimeout` 짜리 데드라인을
/// 갖고, 스크롤 인식기와 아레나를 다투는 동안에는 데드라인이 지나야 down 을
/// 준다. 이 앱은 목록 안에 목록이 든 화면이 많아서 사실상 모든 누름이 그랬다.
///
/// 더 나쁜 건 **빠른 탭**이다. 손가락이 100ms 안에 떨어지면 아레나가 up 에서
/// 정리되며 down 과 up 이 같은 프레임에 처리된다. 빌드가 한 번도 안 일어나
/// 암시적 애니메이션은 **시작조차 안 했다** — 톡 치면 아무 일도 안 났다.
///
/// 그래서 눌림은 [Listener] 의 포인터 이벤트로 잡는다. 아레나를 안 기다린다.
/// 탭 자체와 시맨틱은 그대로 [GestureDetector] 가 맡는다 — 둘은 역할이 갈려서
/// 이중으로 불리지 않는다.
class TpPressable extends StatefulWidget {
  const TpPressable({
    super.key,
    required this.builder,
    this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = TpHaptic.selection,
    this.behavior = HitTestBehavior.opaque,
    this.semantics = true,
  });

  /// 눌린 정도 [t] (0–1) 로 그린다. [child] 는 t 가 바뀌어도 다시 안 만든다.
  final Widget Function(BuildContext context, double t, Widget? child) builder;

  final Widget? child;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 탭이 **확정될 때** 한 번 울린다. 손이 닿을 때가 아니다 — 스크롤을
  /// 시작하려고 짚은 손가락까지 울리면 목록이 시끄럽다.
  final TpHaptic haptic;

  final HitTestBehavior behavior;

  /// 이 위젯이 시맨틱 노드를 낼지.
  ///
  /// 바깥에서 [Semantics] 로 이름·버튼·액션을 다 붙였으면 꺼야 한다. 안 끄면
  /// **노드가 둘로 갈린다** — 바깥 노드는 "버튼"이라고 하는데 누르는 동작이
  /// 없고, 안쪽 노드는 누를 수 있는데 이름이 없다. 스크린 리더로는 어느
  /// 쪽으로도 못 쓴다.
  final bool semantics;

  bool get enabled => onTap != null || onLongPress != null;

  @override
  State<TpPressable> createState() => _TpPressableState();
}

/// 한 손가락은 가장 안쪽 하나만 누른다.
///
/// 히트 테스트는 깊은 쪽부터 배달되므로 먼저 잡는 쪽이 안쪽이다. 이게 없으면
/// 카드 안의 링크를 눌렀을 때 카드까지 같이 눌린다.
final Map<int, Object> _claims = <int, Object>{};

class _TpPressableState extends State<TpPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  late final CurvedAnimation _t;

  /// 지금 누르고 있는 손가락.
  int? _pointer;
  Offset _origin = Offset.zero;
  double _slop = kTouchSlop;

  /// 손가락이 아직 붙어 있는가. 뗐는데 내려가는 중이면 false 다.
  bool _held = false;

  /// 키보드로 여기 와 있는가.
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _t = CurvedAnimation(parent: _c, curve: Curves.linear);
    // 다 내려간 뒤에 손이 이미 떨어져 있으면 그때 올라온다. 톡 치고 뗀
    // 경우에도 눌림이 한 번은 보인다.
    //
    // 타이머로 하면 안 된다 — 위젯 테스트에서 pumpAndSettle 이 먼저 끝나고
    // "Timer 가 남았다"로 실패한다.
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_held) _c.reverse();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motion;
    _c.duration = motion.press.duration;
    // 뗄 때는 더 길게. 실제로 누르는 동작은 빠르고 손을 떼면 천천히 돌아온다.
    _c.reverseDuration = motion.selection.duration;
    _t
      ..curve = motion.press.curve
      ..reverseCurve = motion.selection.curve;
  }

  @override
  void dispose() {
    if (_pointer != null) _claims.remove(_pointer);
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  /// 시간이 0 이면(동작 줄이기) 값을 그냥 옮긴다.
  ///
  /// 애니메이션으로 처리하면 상태 콜백이 **같은 호출 안에서** 되돌아와,
  /// forward 안에서 reverse 를 부르는 재진입이 된다.
  bool get _instant => _c.duration == Duration.zero;

  void _down(PointerDownEvent event) {
    if (!widget.enabled || _pointer != null) return;
    // 안쪽이 이미 잡았으면 바깥은 안 누른다.
    if (_claims.containsKey(event.pointer)) return;

    _claims[event.pointer] = this;
    _pointer = event.pointer;
    _origin = event.position;
    // 마우스는 `computeHitSlop` 이 1px 을 준다(`kPrecisePointerHitSlop`).
    // 손떨림 정도로도 눌림이 취소돼서, 카드를 누르고 있으면 표시가 깜빡였다.
    // 터치 쪽은 그대로 둔다 — iOS 는 비트 단위로 같아야 한다.
    _slop = event.kind == PointerDeviceKind.mouse
        ? kTouchSlop
        : computeHitSlop(event.kind, MediaQuery.maybeGestureSettingsOf(context));
    _held = true;

    if (_instant) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    // 슬롭을 넘겼으면 누른 게 아니라 스크롤을 시작한 것이다.
    if ((event.position - _origin).distance > _slop) _release(hold: false);
  }

  void _up(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _release(hold: true);
  }

  /// [hold] 면 내려가는 애니메이션을 끝까지 보여주고 올라온다.
  void _release({required bool hold}) {
    _claims.remove(_pointer);
    _pointer = null;
    _held = false;

    if (_instant) {
      _c.value = 0;
      return;
    }
    // 아직 내려가는 중이면 다 내려간 뒤에 상태 콜백이 올려준다.
    if (!hold || _c.status != AnimationStatus.forward) _c.reverse();
  }

  void _tapped() {
    switch (widget.haptic) {
      case TpHaptic.none:
        break;
      case TpHaptic.selection:
        HapticFeedback.selectionClick();
      case TpHaptic.impact:
        HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    // 탭과 시맨틱은 그대로 GestureDetector 가 맡는다. 눌림만 포인터로 잡는다.
    final Widget gesture = GestureDetector(
      behavior: widget.behavior,
      excludeFromSemantics: !widget.semantics,
      onTap: widget.onTap == null ? null : _tapped,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) => widget.builder(context, _t.value, child),
        child: widget.child,
      ),
    );

    if (!widget.enabled) return gesture;

    final Widget pointer = Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: gesture,
    );

    // 마우스와 키보드.
    //
    // `GestureDetector` 는 포커스를 못 받는다. 그래서 Tab 으로 닿는 것이
    // 입력칸과 슬라이더 하나뿐이었다 — 버튼도, 칩도, 카드도, 탭도 키보드로는
    // 쓸 수 없었다. 커서도 어디서나 화살표였다.
    //
    // 한 곳에서 다 준다. TpPress·TpButton·TpTapTarget·TpChip 이 전부 이걸
    // 물려받으므로 호출부는 안 건드린다.
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _tapped();
            return null;
          },
        ),
      },
      child: _focused
          ? DecoratedBox(
              // 포커스가 어디 있는지 보여야 키보드로 쓸 수 있다.
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.tp.rInner),
                border: Border.all(color: context.tp.link, width: 2),
              ),
              child: pointer,
            )
          : pointer,
    );
  }
}

/// [TpPressable] 이 흔히 그리는 모양들.
abstract final class TpPressPaint {
  /// 눌린 만큼 줄인다. 히트 테스트는 원래 자리로 둔다 — 줄어드는 버튼에서
  /// 손가락이 흘러내리면 연달아 누를 때 두 번째가 빗나간다.
  static Widget scale(double t, double width, Widget child) => Transform.scale(
    scale: 1 - (1 - TpPressFeel.scaleFor(width)) * t,
    transformHitTests: false,
    child: child,
  );
}
