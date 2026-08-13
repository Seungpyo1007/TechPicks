import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/tp_tokens.dart';
import 'package:techpicks/domain/model/tp_index.dart';
import 'package:techpicks/shared/widgets/tp_bar.dart';
import 'package:techpicks/shared/widgets/tp_chip.dart';
import 'package:techpicks/shared/widgets/tp_score_strip.dart';
import 'package:techpicks/shared/widgets/tp_surface.dart';

import '../support/harness.dart';
import 'golden_harness.dart';

/// 공용 위젯 한 장.
///
/// 화면 골든은 위젯이 어디에 놓였는지를 잡고, 이 한 장은 위젯 자체가 어떻게
/// 생겼는지를 잡는다. 화면을 다 바꿔도 이건 그대로여야 한다.
void main() {
  setUp(initLocalization);

  goldenScenario('components', '공용 위젯', (tester, chrome) async {
    await pumpScreen(
      tester,
      const _Sheet(),
      chrome: chrome,
      size: frameOf(chrome),
    );
  });
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: t.pageBackground,
      // 앱에서는 TpShell 이 깔아준다. 없으면 스타일 없는 Text 가 빨간 오류
      // 글씨로 그려진다.
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TpSurface(
                padding: const EdgeInsets.all(16),
                child: Text('card', style: type.titleMedium),
              ),
              const SizedBox(height: 12),
              TpSurface(
                strong: true,
                padding: const EdgeInsets.all(16),
                child: Text('card strong', style: type.titleMedium),
              ),
              const SizedBox(height: 12),
              // 동심 규칙: 카드 반지름 안은 한 단계 작은 반지름.
              TpSurface(
                padding: const EdgeInsets.all(10),
                child: TpSurface(
                  strong: true,
                  radius: t.rInner,
                  shadow: false,
                  padding: const EdgeInsets.all(12),
                  child: Text('nested', style: type.bodyMedium),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  TpChip(label: 'selected', selected: true, onTap: () {}),
                  const SizedBox(width: 8),
                  TpChip(label: 'idle', selected: false, onTap: () {}),
                  const SizedBox(width: 8),
                  // 못 누르는 칩. 색은 idle 과 같고 시맨틱만 다르다.
                  const TpChip(label: 'flat', selected: false),
                ],
              ),
              const SizedBox(height: 20),
              const TpBar(fraction: 0.74),
              const SizedBox(height: 10),
              const TpBar(fraction: 0.2, height: 6, radius: 3),
              const SizedBox(height: 10),
              // 빈 트랙. 0 점과 구분되어야 한다.
              const TpBar(fraction: 0),
              const SizedBox(height: 20),
              const TpScoreStrip(
                axes: <TpAxis>[
                  TpAxis(TpAxisKind.performance, 92),
                  TpAxis(TpAxisKind.camera, 61),
                  TpAxis(TpAxisKind.display, 78),
                  TpAxis(TpAxisKind.battery, 45),
                  TpAxis(TpAxisKind.value, null),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
