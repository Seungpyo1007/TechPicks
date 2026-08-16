import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';

/// 누르는 동안 밝아지는 면.
///
/// 명세는 카드에만 규칙을 줬다(밝기 +4%). 그래서 카드가 아닌 줄 — 랭킹 행,
/// 설정 줄, 언어 시트, 세그먼트 — 은 눌러도 아무 일이 없었다. 같은 줄에
/// 사는 것들이 어떤 건 반응하고 어떤 건 안 하면 고장으로 읽힌다.
///
/// 알약은 [TpButton]·[TpTapTarget] 처럼 줄어들고, 넓은 면은 이렇게 밝아진다.
/// 줄어들기를 넓은 면에 쓰면 목록 전체가 출렁인다.
class TpPress extends StatefulWidget {
  const TpPress({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.semanticsButton = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 바깥에서 이미 시맨틱을 붙였으면 false. 두 번 읽히면 안 된다.
  final bool semanticsButton;

  /// `filter: brightness(1.04)` 와 같다.
  static const double amount = 1.04;

  /// 눌린 정도 [t] (0–1) 만큼 밝힌다.
  static ColorFilter filterAt(double t) {
    final v = 1 + (amount - 1) * t;
    return ColorFilter.matrix(<double>[
      v, 0, 0, 0, 0, //
      0, v, 0, 0, 0, //
      0, 0, v, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }

  @override
  State<TpPress> createState() => _TpPressState();
}

class _TpPressState extends State<TpPress> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final move = context.motion.press;
    final enabled = widget.onTap != null || widget.onLongPress != null;

    final Widget gesture = GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _pressed ? 1 : 0),
        duration: move.duration,
        curve: move.curve,
        child: widget.child,
        builder: (context, t, child) => t == 0
            ? child!
            : ColorFiltered(colorFilter: TpPress.filterAt(t), child: child),
      ),
    );

    return widget.semanticsButton
        ? Semantics(button: true, child: gesture)
        : gesture;
  }
}
