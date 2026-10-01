import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../brand/tp_logo.dart';

/// 스켈레톤 줄이 점수 막대처럼 차올랐다 비워진다(로고 로더와 같은 움직임).
///
/// 끝없이 돌기 때문에 `motion.loops` 가 꺼져 있으면(동작 줄이기, 테스트) 그냥
/// [child] 다. 채움은 child 의 칠해진 곳에만 얹힌다.
class TpShimmer extends StatefulWidget {
  const TpShimmer({super.key, required this.child});

  final Widget child;

  /// 한 번 찼다 비우는 시간. 로고 로더와 같다.
  static const Duration period = TpLogoLoader.period;

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
    // 로고 로더와 같은 움직임: 스켈레톤 줄이 점수 막대처럼 왼쪽부터 옅은
    // 파랑으로 찼다가 비워진다. 칠해진 곳(child 의 모양)에만 얹힌다.
    final tint = (dark ? const Color(0xFF8DB7EE) : const Color(0xFF4375B9))
        .withValues(alpha: dark ? .32 : .24);
    // 스켈레톤 모양은 반투명이라 그 위에 칠하면 같이 흐려진다. 모양만 따로
    // 불투명하게 떠서(알파를 키움) 그 안에 채움을 칠해 위에 얹는다.
    final mask = ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0, 0, 0, 0, 0, //
        0, 0, 0, 0, 0, //
        0, 0, 0, 0, 0, //
        0, 0, 0, 12, 0, //
      ]),
      child: widget.child,
    );
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final p = TpLogoLoader.fillAt(_c.value);
                return ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (rect) => LinearGradient(
                    colors: <Color>[tint, tint, tint.withValues(alpha: 0)],
                    stops: <double>[0, p, math.min(1, p + .05)],
                  ).createShader(rect),
                  child: child,
                );
              },
              child: ExcludeSemantics(child: mask),
            ),
          ),
        ),
      ],
    );
  }
}
