import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../brand/tp_logo.dart';

/// 스켈레톤 묶음. 안의 [TpBone] 이 로고 막대처럼 각자 차올랐다 비워진다.
///
/// 끝없이 돌기 때문에 `motion.loops` 가 꺼져 있으면(동작 줄이기, 테스트) 뼈대
/// 줄만 회색으로 서 있다.
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
  Widget build(BuildContext context) => _ShimmerScope(
    animation: context.motion.loops ? _c : null,
    child: ExcludeSemantics(child: widget.child),
  );
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});

  final Animation<double>? animation;

  @override
  bool updateShouldNotify(_ShimmerScope old) => old.animation != animation;
}

/// 스켈레톤 한 줄. 회색 홈 위에 옅은 파랑이 왼쪽부터 찬다.
///
/// [width] 를 주면 그 폭, [widthFactor] 를 주면 남은 폭의 비율, 둘 다 없으면
/// 가득. [delay] 는 0–1 주기 비율로 늦춘다(로고 막대처럼 어긋나게).
class TpBone extends StatelessWidget {
  const TpBone({
    super.key,
    this.width,
    this.widthFactor,
    this.height = 12,
    this.radius,
    this.delay = 0,
  });

  final double? width;
  final double? widthFactor;
  final double height;
  final double? radius;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final animation = context
        .dependOnInheritedWidgetOfExactType<_ShimmerScope>()
        ?.animation;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = (dark ? const Color(0xFF8DB7EE) : const Color(0xFF4375B9))
        .withValues(alpha: dark ? .32 : .24);
    final r = BorderRadius.circular(radius ?? height / 2);
    Widget bone = ClipRRect(
      borderRadius: r,
      child: SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: ColoredBox(
          color: context.sys.fill3,
          child: animation == null
              ? null
              : AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: TpLogoLoader.fillAt(animation.value - delay),
                    child: ColoredBox(color: tint),
                  ),
                ),
        ),
      ),
    );
    if (widthFactor != null) {
      bone = FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: bone,
      );
    }
    return bone;
  }
}
