import 'package:flutter/widgets.dart';

import '../../app/theme/tp_motion.dart';

/// 처음 그려질 때 작게 시작해서 bouncy 스프링으로 제 크기가 된다.
/// 비교 빈 칸의 + 처럼 "여기를 누르라"는 자리에 한 번.
///
/// 동작 줄이기면 그냥 [child].
class TpPopIn extends StatefulWidget {
  const TpPopIn({super.key, required this.child, this.from = 0.6});

  final Widget child;

  /// 시작 크기.
  final double from;

  @override
  State<TpPopIn> createState() => _TpPopInState();
}

class _TpPopInState extends State<TpPopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = context.motion;
    if (motion.isReduced) return;
    _c
      ..value = widget.from
      ..animateWith(motion.bouncy.createSimulation(start: widget.from));
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
