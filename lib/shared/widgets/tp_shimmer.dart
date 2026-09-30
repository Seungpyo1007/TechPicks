import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';

/// 스켈레톤 위를 빛 한 줄이 지나간다. 불러오는 중이라는 표시.
///
/// 끝없이 돌기 때문에 `motion.loops` 가 꺼져 있으면(동작 줄이기, 테스트) 그냥
/// [child] 다. 빛은 child 의 칠해진 곳에만 얹힌다(`srcATop`).
class TpShimmer extends StatefulWidget {
  const TpShimmer({super.key, required this.child});

  final Widget child;

  /// 한 번 지나가는 시간. 사이에 쉬는 시간까지 포함한다.
  static const Duration period = Duration(milliseconds: 2000);

  @override
  State<TpShimmer> createState() => _TpShimmerState();
}

class _TpShimmerState extends State<TpShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: TpShimmer.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.motion.loops) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.motion.loops) return widget.child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final light = Colors.white.withValues(alpha: dark ? .10 : .55);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // 앞 70% 동안 왼쪽 밖에서 오른쪽 밖까지 지나가고 나머지는 쉰다.
        final p = (_c.value / 0.7).clamp(0.0, 1.0);
        final x = -1.5 + 3 * Curves.easeInOut.transform(p);
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(x - 0.6, -0.3),
            end: Alignment(x + 0.6, 0.3),
            colors: <Color>[
              light.withValues(alpha: 0),
              light,
              light.withValues(alpha: 0),
            ],
          ).createShader(rect),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
