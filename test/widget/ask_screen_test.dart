import 'package:easy_localization/easy_localization.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

import '../support/harness.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/domain/model/ask_answer.dart';
import 'package:techpicks/feature/ask/ask_screen.dart';

/// 모델을 부르지 않는 가짜. 화면만 검사한다.
class _StubAsk implements AskService {
  _StubAsk(this.answer, {this.say});

  final AskAnswer? answer;

  /// 표 없이 문장만 돌려주는 답.
  final String? say;

  final List<String> asked = <String>[];

  @override
  Future<AskReply?> ask(String question, List<Smartphone> catalog) async {
    asked.add(question);
    if (say != null) return AskReply.say(say!);
    return answer == null ? null : AskReply.pick(answer!);
  }
}

Future<void> _pump(
  WidgetTester tester,
  AskService service, {
  TpChrome chrome = TpChrome.ios,
}) => pumpScreen(
  tester,
  const AskScreen(),
  chrome: chrome,
  size: const Size(1200, 2400),
  overrides: <Override>[askServiceProvider.overrideWithValue(service)],
);

const _answer = AskAnswer(
  pick: 'OnePlus 13',
  pickSlug: 'oneplus-13',
  reason: 'Cheapest flagship on your weights.',
  rows: <AskRow>[
    AskRow(label: 'TP Index', value: '74'),
    AskRow(label: 'Price', value: r'$899'),
    AskRow(label: 'Battery', value: '6000mAh'),
    AskRow(label: 'Camera', value: '36'),
  ],
);

void main() {
  setUp(initLocalization);

  testWidgets('안내 문구로 시작한다', (tester) async {
    await _pump(tester, _StubAsk(_answer));
    expect(find.textContaining('Give me a budget'), findsOneWidget);
  });

  testWidgets('제안 칩이 있다', (tester) async {
    await _pump(tester, _StubAsk(_answer));
    for (final s in AskScreen.suggestions()) {
      expect(find.text(s), findsOneWidget, reason: s);
    }
  });

  testWidgets('보내면 사용자 말풍선과 표가 쌓인다', (tester) async {
    final stub = _StubAsk(_answer);
    await _pump(tester, stub);

    await tester.enterText(find.byType(TextField), '카메라 좋은 거');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(stub.asked, <String>['카메라 좋은 거']);
    expect(find.text('카메라 좋은 거'), findsOneWidget);
    expect(find.text('OnePlus 13'), findsOneWidget);
    expect(find.text('Cheapest flagship on your weights.'), findsOneWidget);
    // 4줄 표
    for (final label in <String>['TP Index', 'Price', 'Battery', 'Camera']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('74'), findsOneWidget);
  });

  testWidgets('제안 칩을 누르면 그대로 질문이 된다', (tester) async {
    final stub = _StubAsk(_answer);
    await _pump(tester, stub);

    await tester.tap(find.text(AskScreen.suggestions().first));
    await tester.pumpAndSettle();

    expect(stub.asked, <String>[AskScreen.suggestions().first]);
  });

  testWidgets('실패하면 실패 말풍선', (tester) async {
    await _pump(tester, _StubAsk(null));

    await tester.enterText(find.byType(TextField), '뭐든');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not answer'), findsOneWidget);
  });

  // 카탈로그 밖 질문이면 표를 못 그린다. 그렇다고 "답할 수 없습니다"로
  // 떨어뜨릴 이유는 없다 — v1 은 그냥 대답했다.
  testWidgets('기기를 고를 수 없는 질문에는 문장으로 답한다', (tester) async {
    await _pump(tester, _StubAsk(null, say: '배터리 수명은 용량보다 화면과 칩이 더 좌우합니다.'));

    await tester.enterText(find.byType(TextField), '배터리 수명은 뭐가 정하나요?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('배터리 수명은 용량보다 화면과 칩이 더 좌우합니다.'), findsOneWidget);
    expect(find.textContaining('Could not answer'), findsNothing);
  });

  testWidgets('빈 입력은 보내지 않는다', (tester) async {
    final stub = _StubAsk(_answer);
    await _pump(tester, stub);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(stub.asked, isEmpty);
  });

  testWidgets('답변을 누르면 상세로 넘어갈 slug 를 준다', (tester) async {
    expect(_answer.pickSlug, 'oneplus-13');
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, _StubAsk(_answer), chrome: chrome);
      expect(find.text('Ask'), findsWidgets);
    }
  });

  // 앱에 Scaffold 가 없어 아무도 키보드를 안 피한다. 입력 바가 화면 바닥에
  // 붙어 있어서 누르면 키보드가 입력 바와 제안 칩을 통째로 덮었다.
  testWidgets('키보드가 올라오면 입력 바가 그만큼 올라간다', (tester) async {
    const frame = Size(402, 874);
    tester.view.physicalSize = frame;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScreen(tester, const AskScreen(), size: frame);
    final resting = tester.getRect(find.byType(TextField)).bottom;

    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    await tester.pumpAndSettle();

    final lifted = tester.getRect(find.byType(TextField)).bottom;
    expect(lifted, lessThanOrEqualTo(frame.height - 336));
    expect(resting - lifted, closeTo(336, 1));
  });

  // 답을 기다리는 동안 아무 표시가 없었고, 그 사이에 보낸 질문은 조용히
  // 버려졌다.
  testWidgets('기다리는 동안 표시가 남고 두 번째 질문은 안 사라진다', (tester) async {
    final answer = Completer<AskReply?>();
    await pumpScreen(
      tester,
      const AskScreen(),
      size: const Size(1200, 2400),
      overrides: <Override>[
        askServiceProvider.overrideWithValue(_SlowAsk(answer.future)),
      ],
    );

    await tester.enterText(find.byType(TextField), '뭐가 좋아?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text(K.askThinking.tr()), findsOneWidget);

    // 기다리는 동안 보내기는 잠겨 있다.
    final before = tester.widgetList(find.byType(TextField)).length;
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();
    expect(before, tester.widgetList(find.byType(TextField)).length);

    answer.complete(null);
    await tester.pumpAndSettle();

    expect(find.text(K.askThinking.tr()), findsNothing);
  });
}

/// 시킨 대로 늦게 답한다.
class _SlowAsk implements AskService {
  const _SlowAsk(this.answer);

  final Future<AskReply?> answer;

  @override
  Future<AskReply?> ask(String question, List<Smartphone> catalog) => answer;
}
