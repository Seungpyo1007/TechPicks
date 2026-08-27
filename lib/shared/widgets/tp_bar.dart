import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';

/// 0–1 을 채우는 가로 막대.
///
/// 랭킹 행(3px), 프로세서 행(3px), 상세의 점수 스트립(6px)이 같은 모양을 따로
/// 그리고 있었다. 셋 다 여기로 온다.
///
/// **값이 바뀌면 트윈된다.** 예전에는 [FractionallySizedBox] 를 즉시 갱신해서,
/// You 화면 슬라이더를 움직이면 랭킹 행은 220ms 로 미끄러지는데 그 안의 막대만
/// 순간이동했다. 같은 프레임에 두 종류의 모션이 섞이면 안 움직이는 쪽이
/// 고장으로 보인다.
class TpBar extends StatelessWidget {
  const TpBar({
    super.key,
    required this.fraction,
    this.height = 3,
    this.radius = 2,
  });

  /// 0–1. 범위를 벗어나면 잘린다.
  final double fraction;

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final move = context.motion.valueChange;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: t.track,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: fraction.clamp(0, 1).toDouble()),
            duration: move.duration,
            curve: move.curve,
            builder: (context, value, _) => Align(
              alignment: Alignment.centerLeft,
              // 0 이면 FractionallySizedBox 가 아예 안 그려져서 채움이
              // 사라졌다 나타난다. 대신 폭만 0 으로 둔다.
              child: FractionallySizedBox(
                widthFactor: value,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: t.barFill),
                  child: SizedBox(height: height),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
