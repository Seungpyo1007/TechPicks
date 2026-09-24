import 'package:flutter/widgets.dart';

import '../../app/theme/tp_motion.dart';

/// [trigger] 가 바뀔 때마다 한 번 튄다. 살짝 눌렸다가 bouncy 스프링으로 돌아오며
/// 1 을 조금 넘는다 — 관심 목록 담기, 빈 칸의 + 처럼 "됐다"를 알리는 자리.
///
/// 처음 그릴 때는 안 튄다. 동작 줄이기면 안 튄다.
class TpPulse extends StatefulWidget {
  const TpPulse({
    super.key,
    required this.trigger,
    required this.child,
    this.depth = 0.06,
  });

  final Object? trigger;
  final Widget child;

  /// 얼마나 눌렸다 시작하는지. 0.06 이면 94% 에서 출발한다.
  final double depth;

  @override
  State<TpPulse> createState() => _TpPulseState();
}

class _TpPulseState extends State<TpPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(TpPulse old) {
    super.didUpdateWidget(old);
    if (widget.trigger == old.trigger) return;
    final motion = context.motion;
    if (motion.isReduced) return;
    _c
      ..value = 1 - widget.depth
      ..animateWith(motion.bouncy.createSimulation(start: 1 - widget.depth));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.scale(
      scale: _c.value,
      transformHitTests: false,
      child: child,
    ),
    child: widget.child,
  );
}
