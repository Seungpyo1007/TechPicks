import 'package:flutter/material.dart';

import '../../app/theme/tp_typography.dart';

/// 넘칠 때만 오른쪽 끝이 배경으로 사라지는 한 줄.
///
/// [ShaderMask] 는 자식 크기에 맞춰 그러데이션을 건다. 조건 없이 감싸면 다
/// 들어간 줄의 끝 글자까지 흐려져 잘린 것처럼 보인다 — 관심 목록의
/// "$799 · Dimensity 9500" 이 그랬다. 그래서 먼저 재보고 넘칠 때만 씌운다.
class TpFadedLine extends StatelessWidget {
  const TpFadedLine({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = context.tpText.caption;
    final line = Text(
      text,
      style: style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.clip,
    );

    return SizedBox(
      height: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            maxLines: 1,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final overflows = painter.width > constraints.maxWidth;
          painter.dispose();
          if (!overflows) return line;

          return ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[Colors.black, Colors.black, Colors.transparent],
              stops: <double>[0, 0.85, 1],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: line,
          );
        },
      ),
    );
  }
}
