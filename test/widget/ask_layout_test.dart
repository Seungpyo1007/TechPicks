import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/domain/model/ask_answer.dart';
import 'package:techpicks/feature/ask/ask_screen.dart';
import 'package:techpicks/shared/widgets/tp_chip.dart';

import '../support/harness.dart';

/// 상담 화면의 자리 배치.
///
/// 넘침 예외가 안 나는 것과 글자가 상자 안에 있는 것은 다른 일이다. 여기
/// 있는 것들은 전부 예외 없이 조용히 틀려 있던 것들이다.

/// 긴 답 하나를 돌려주는 가짜.
class _LongAsk implements AskService {
  const _LongAsk();

  @override
  Future<AskReply?> ask(String question, List<Smartphone> catalog) async =>
      const AskReply.pick(
        AskAnswer(
          pick: 'OnePlus 13',
          pickSlug: 'oneplus-13',
          reason:
              '가격 대비 배터리와 충전이 가장 좋고, 화면과 프로세서도 이 값에서 '
              '기대할 수 있는 것보다 낫습니다. 카메라만 한 급 아래입니다.',
          rows: <AskRow>[
            AskRow(label: 'TP Index', value: '74'),
            AskRow(label: 'Price', value: r'$899'),
            AskRow(label: 'Battery', value: '6000mAh'),
            AskRow(label: 'Camera', value: '36'),
          ],
        ),
      );
}

void main() {
  setUp(initLocalization);

  // 예전에는 `_send` 가 await 직후에 maxScrollExtent 를 읽었다. 그 시점의
  // 값은 답이 아직 놓이기 전 것이라, 답이 길수록 아래가 잘린 채로 멈췄다.
  testWidgets('긴 답이 와도 바닥까지 내려간다', (tester) async {
    const frame = Size(402, 874);
    await pumpScreen(
      tester,
      const AskScreen(),
      size: frame,
      overrides: <Override>[
        askServiceProvider.overrideWithValue(const _LongAsk()),
      ],
    );

    await tester.enterText(find.byType(TextField), '뭐가 좋아?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(
      position.pixels,
      moreOrLessEquals(position.maxScrollExtent, epsilon: 1),
    );
  });

  // 컴포저 높이가 118 짜리 상수였다. 실제로는 어느 배율에서도 108 이었고
  // (두 상자가 높이로 묶여 있어서 안 자랐다), 1.6배에서는 칩 라벨과 입력
  // 글자가 상자 밖으로 나갔다. 예외가 안 나서 배율 테스트도 조용했다.
  for (final scale in <double>[1, 1.6]) {
    testWidgets('글자 $scale 배에서 컴포저가 제 자리 안에 든다', (tester) async {
      await pumpScreen(
        tester,
        const AskScreen(),
        size: const Size(402, 874),
        textScale: scale,
      );

      final composer = tester.getRect(find.byKey(askComposerKey));
      final field = tester.getRect(find.byType(TextField));
      // 입력 글자를 담은 알약.
      final pill = tester.getRect(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(Container),
            )
            .first,
      );

      // 글자가 알약 밖으로 안 나간다. 예전에는 48 로 묶인 상자 위아래로
      // 삐져나갔고, alignment 가 center 라 예외도 안 났다.
      expect(
        field.height,
        lessThanOrEqualTo(pill.height + 0.5),
        reason: '$scale',
      );
      expect(
        pill.top,
        greaterThanOrEqualTo(composer.top - 0.5),
        reason: '$scale',
      );
      expect(
        pill.bottom,
        lessThanOrEqualTo(composer.bottom + 0.5),
        reason: '$scale',
      );

      // 제안 칩도 자기 줄 안에 든다.
      for (final chip in find.byType(TpChip).evaluate()) {
        final r = tester.getRect(find.byWidget(chip.widget));
        expect(
          r.top,
          greaterThanOrEqualTo(composer.top - 0.5),
          reason: '$scale',
        );
        expect(r.bottom, lessThanOrEqualTo(pill.top + 0.5), reason: '$scale');
      }
    });
  }

  // 마지막 말풍선이 입력 바 뒤에 숨으면 안 된다. 목록이 자기 패딩에 컴포저
  // 자리를 더한다.
  testWidgets('마지막 말풍선이 입력 바에 안 가린다', (tester) async {
    const frame = Size(402, 874);
    await pumpScreen(
      tester,
      const AskScreen(),
      size: frame,
      overrides: <Override>[
        askServiceProvider.overrideWithValue(const _LongAsk()),
      ],
    );

    await tester.enterText(find.byType(TextField), '뭐가 좋아?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final composer = tester.getRect(find.byKey(askComposerKey));
    final answer = tester.getRect(find.text('OnePlus 13'));
    expect(answer.bottom, lessThanOrEqualTo(composer.top));
  });
}
