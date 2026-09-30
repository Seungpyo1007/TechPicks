import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import 'tp_arrive.dart';

/// 0–1 을 채우는 가로 막대.
///
/// 랭킹 행(3px), 프로세서 행(3px), 상세의 점수 스트립(6px)이 같은 모양을 따로
/// 그리고 있었다. 셋 다 여기로 온다.
///
/// **값이 바뀌면 스프링으로 따라간다.** 예전에는 [FractionallySizedBox] 를 즉시 갱신해서,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: t.track,
          // 스프링이라 도중에 값이 또 바뀌어도(슬라이더) 속도를 이어받는다.
          child: SingleMotionBuilder(
            // 화면이 나타나면 0 에서부터 찬다.
            key: ValueKey<DateTime?>(TpArriveScope.of(context)),
            from: TpArriveScope.freshOf(context) == null ? null : 0,
            value: fraction.clamp(0, 1).toDouble(),
            motion: context.motion.smooth,
            builder: (context, v, _) => Align(
              alignment: Alignment.centerLeft,
              // 0 이면 FractionallySizedBox 가 아예 안 그려져서 채움이
              // 사라졌다 나타난다. 대신 폭만 0 으로 둔다.
              child: FractionallySizedBox(
                widthFactor: v.clamp(0.0, 1.0),
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
