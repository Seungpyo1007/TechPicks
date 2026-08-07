import 'package:flutter/material.dart';

import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../domain/model/tp_index.dart';
import '../spec_labels.dart';

/// 점수 5개 축을 각자 트랙 위에 그린다.
///
/// 레이더 차트를 쓰지 않는 이유가 여기 있다. 다섯 축이 모두 0–100 같은
/// 척도라 나란히 놓으면 그대로 읽히는데, 레이더로 접으면 축 순서에 따라
/// 면적이 달라 보인다.
///
/// 데이터가 없는 축은 빈 트랙으로 둔다. 0 점과 구분해야 한다.
class TpScoreStrip extends StatelessWidget {
  const TpScoreStrip({
    super.key,
    required this.axes,
    this.labels = defaultLabels,
  });

  static const Map<TpAxisKind, String> defaultLabels = SpecLabels.axis;

  final List<TpAxis> axes;
  final Map<TpAxisKind, String> labels;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;

    return Column(
      children: <Widget>[
        for (final axis in axes)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        labels[axis.kind] ?? axis.kind.key,
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
