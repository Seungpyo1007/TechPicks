import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../copy_keys.dart';
import '../tp_haptics.dart';

/// 화면 안 안내 한 단계. [target] 은 [TpCoachTarget.id].
class TpCoachStep {
  const TpCoachStep({
    required this.target,
    required this.title,
    required this.body,
  });

  final String target;

  /// 번역 키.
  final String title;
  final String body;
}

/// 안내가 가리킬 수 있는 자리. 크기와 위치만 잰다 — 모양은 그대로 둔다.
///
/// 네이티브 유리 버튼은 플랫폼 뷰라 안을 잴 수 없다. 이 래퍼의 크기로 충분하다.
class TpCoachTarget extends StatefulWidget {
  const TpCoachTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  /// 지금 화면에 붙어 있는 자리들. 같은 id 가 둘이면 나중에 붙은 쪽.
  static final Map<String, GlobalKey> _live = <String, GlobalKey>{};

  @override
  State<TpCoachTarget> createState() => _TpCoachTargetState();
}

class _TpCoachTargetState extends State<TpCoachTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TpCoachTarget._live[widget.id] = _key;
  }

  @override
  void didUpdateWidget(TpCoachTarget old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      if (TpCoachTarget._live[old.id] == _key) {
        TpCoachTarget._live.remove(old.id);
      }
      TpCoachTarget._live[widget.id] = _key;
    }
  }

  @override
  void dispose() {
    if (TpCoachTarget._live[widget.id] == _key) {
      TpCoachTarget._live.remove(widget.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

/// 화면 안 안내(코치마크). 그 화면에 **처음** 들어왔을 때 한 번.
///
/// 라우트가 아니라 루트 오버레이에 올린다. 라우트로 올리면 네이티브 유리
/// 위젯이 "현재 라우트가 아님"으로 숨어서, 가리키려던 버튼이 사라진다.
abstract final class TpCoach {
  /// 테스트는 기본으로 끈다(`test/flutter_test_config.dart`). 안내 테스트만 켠다.
  static bool enabled = true;

  static const String _prefix = 'coach_seen_';

  /// 지금 떠 있는 것. 한 번에 하나.
  static OverlayEntry? _entry;
  static String? _screen;

  static bool get showing => _entry != null;

  static Future<bool> seen(String screen) async =>
      (await SharedPreferences.getInstance()).getBool('$_prefix$screen') ??
      false;

  /// "안내 다시 보기". 다음에 각 화면에 들어가면 다시 뜬다.
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await prefs.remove(key);
    }
  }

  /// 아직 안 봤으면 띄운다. 화면에 없는 자리는 건너뛴다. 하나도 없으면 안 띄우고
  /// 본 것으로도 치지 않는다(다음에 다시 시도).
  static Future<void> maybeShow(
    BuildContext context, {
    required String screen,
    required List<TpCoachStep> steps,
  }) async {
    if (!enabled || _entry != null) return;
    if (await seen(screen)) return;
    if (!context.mounted) return;
    // 위에 다른 화면이 밀려 있으면 이 화면 차례가 아니다.
    if (ModalRoute.of(context)?.isCurrent == false) return;
    final live = <TpCoachStep>[
      for (final s in steps)
        if (_rectOf(s.target) != null) s,
    ];
    if (live.isEmpty) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    await (await SharedPreferences.getInstance()).setBool(
      '$_prefix$screen',
      true,
    );
    if (!context.mounted || _entry != null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CoachLayer(
        steps: live,
        onDone: () {
          if (_entry != entry) return;
          entry.remove();
          _entry = null;
          _screen = null;
        },
      ),
    );
    _entry = entry;
    _screen = screen;
    overlay.insert(entry);
  }

  /// 떠 있으면 닫는다.
  static void dismiss() {
    _entry?.remove();
    _entry = null;
    _screen = null;
  }

  /// 그 화면의 안내가 떠 있으면 닫는다(탭을 떠날 때).
  static void dismissFor(String screen) {
    if (_screen == screen) dismiss();
  }

  static Rect? _rectOf(String id) {
    final box =
        TpCoachTarget._live[id]?.currentContext?.findRenderObject()
            as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    return rect.isEmpty ? null : rect;
  }
}

class _CoachLayer extends StatefulWidget {
  const _CoachLayer({required this.steps, required this.onDone});

  final List<TpCoachStep> steps;
  final VoidCallback onDone;

  @override
  State<_CoachLayer> createState() => _CoachLayerState();
}

class _CoachLayerState extends State<_CoachLayer>
    with TickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  int _index = 0;
  Rect _from = Rect.zero;
  Rect _to = Rect.zero;

  @override
  void initState() {
    super.initState();
    _to = _from = _hole(0) ?? Rect.zero;
    _move.value = 1;
  }

  @override
  void dispose() {
    _move.dispose();
    _fade.dispose();
    super.dispose();
  }

  Rect? _hole(int i) => TpCoach._rectOf(widget.steps[i].target)?.inflate(6);

  Rect get _now => Rect.lerp(
    _from,
    _to,
    Curves.easeOutBack.transform(_move.value.clamp(0, 1)),
  )!;

  Future<void> _next() async {
    TpHaptics.selection();
    var i = _index + 1;
    while (i < widget.steps.length && _hole(i) == null) {
      i++;
    }
    if (i >= widget.steps.length) {
      await _close();
      return;
    }
    final reduced = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _from = _now;
      _to = _hole(i)!;
      _index = i;
    });
    if (reduced) {
      _move.value = 1;
    } else {
      unawaited(_move.forward(from: 0));
    }
  }

  Future<void> _close() async {
    if (!MediaQuery.disableAnimationsOf(context)) await _fade.reverse();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final size = MediaQuery.sizeOf(context);
    final last = _index == widget.steps.length - 1;
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _move,
        builder: (context, _) {
          final hole = _now;
          final radius = (hole.shortestSide / 2).clamp(8.0, 24.0);
          // 말풍선은 구멍 아래, 자리가 없으면 위.
          final below = hole.bottom + 180 < size.height - 40;
          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: Semantics(
                  button: true,
                  label: K.coachClose.tr(),
                  onTap: () => unawaited(_close()),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => unawaited(_next()),
                    child: CustomPaint(
                      painter: _Scrim(hole: hole, radius: radius),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: below ? hole.bottom + 14 : null,
                bottom: below ? null : size.height - hole.top + 14,
                child: Align(
                  alignment: Alignment(
                    ((hole.center.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
                    0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: _Bubble(
                      key: ValueKey<int>(_index),
                      title: step.title.tr(),
                      body: step.body.tr(),
                      count: '${_index + 1}/${widget.steps.length}',
                      action: (last ? K.coachDone : K.next).tr(),
                      onAction: () => unawaited(_next()),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 어두운 막에 구멍 하나.
class _Scrim extends CustomPainter {
  const _Scrim({required this.hole, required this.radius});

  final Rect hole;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)));
    canvas.drawPath(path, Paint()..color = const Color(0x99000000));
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole, Radius.circular(radius)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xCCFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_Scrim old) => old.hole != hole || old.radius != radius;
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.title,
    required this.body,
    required this.count,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String body;
  final String count;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: context.motion.reveal.duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 8),
          child: child,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
          decoration: BoxDecoration(
            color: sys.cell,
            borderRadius: BorderRadius.circular(glass ? 22 : 16),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: sys.label,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    body,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: sys.label2,
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    ExcludeSemantics(
                      child: Text(
                        count,
                        style: TextStyle(fontSize: 13, color: sys.label3),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onAction,
                      child: Text(
                        action,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: TpTokens.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
