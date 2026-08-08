import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../domain/model/tp_index.dart';
import '../copy_keys.dart';
import '../spec_labels.dart';

/// 점수 5개 축을 각자 트랙 위에 그린다.
///
/// 레이더 차트를 쓰지 않는 이유가 여기 있다. 다섯 축이 모두 0–100 같은
/// 척도라 나란히 놓으면 그대로 읽히는데, 레이더로 접으면 축 순서에 따라
/// 면적이 달라 보인다.
///
/// 데이터가 없는 축은 빈 트랙으로 둔다. 0 점과 구분해야 한다.
class TpScoreStrip extends StatelessWidget {
  const TpScoreStrip({super.key, required this.axes});

  final List<TpAxis> axes;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;

    return Column(
      children: <Widget>[
        for (final axis in axes)
          Semantics(
            container: true,
            // 라벨·숫자·막대가 따로 읽히면 무슨 값인지 알 수 없다.
            label: axis.hasData
                ? K.a11yAxis.tr(
                    args: <String>[
                      SpecLabels.axis(axis.kind),
                      axis.score!.round().toString(),
                    ],
                  )
                : K.a11yAxisMissing.tr(
                    args: <String>[SpecLabels.axis(axis.kind)],
                  ),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          SpecLabels.axis(axis.kind),
                          style: type.secondary,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      Text(
                        axis.hasData ? axis.score!.round().toString() : '—',
                        maxLines: 1,
                        softWrap: false,
                        style: type.secondary.copyWith(
                          color: axis.hasData ? TpTokens.ink : t.dim,
                          fontWeight: t.boldWeight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _Segment(fraction: axis.fraction),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 6,
        color: t.track,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: t.barFill),
            child: const SizedBox(height: 6),
          ),
        ),
      ),
    );
  }
}
