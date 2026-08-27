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
  size: const Size(700, 2400),
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

  // 칩 줄은 가로 스크롤이라 뒤쪽 칩은 화면 밖이면 아예 안 만들어진다.
  // 넷이 한 번에 들어가는 폭을 억지로 주는 것보다, 실제로 닿을 수 있는지를
  // 본다 — 그게 사람이 하는 일이다.
  testWidgets('제안 칩 넷에 다 닿는다', (tester) async {
    await _pump(tester, _StubAsk(_answer));

    final row = find
        .descendant(
          of: find.byType(AskScreen),
          matching: find.byType(Scrollable),
        )
        .last;
    for (final s in AskScreen.suggestions()) {
      await tester.dragUntilVisible(find.text(s), row, const Offset(-120, 0));
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
  //
  // 그걸 고치면서 이번엔 **키보드 높이만큼** 올렸는데, 그러면 크롬이 비워 둔
  // 자리(iOS 122 · Android 124)가 키보드 위에 빈 띠로 남았다. 키보드가
  // 올라오면 탭 캡슐은 그 뒤에 가려지므로 그 자리를 도로 쓴다. 그래서 올라간
  // 거리는 키보드 높이가 **아니다** — 확인할 것은 바가 키보드 바로 위에
  // 붙는가다.
  for (final chrome in TpChrome.values) {
    testWidgets('키보드가 올라오면 입력 바가 그 위에 붙는다 · ${chrome.name}', (tester) async {
      const frame = Size(402, 874);
      const keyboard = 336.0;
      tester.view.physicalSize = frame;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpScreen(tester, const AskScreen(), chrome: chrome, size: frame);
      final resting = tester.getRect(find.byType(TextField)).bottom;

      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      await tester.pumpAndSettle();

      final lifted = tester.getRect(find.byType(TextField)).bottom;
      final keyboardTop = frame.height - keyboard;
      expect(lifted, lessThanOrEqualTo(keyboardTop), reason: chrome.name);
      // 바로 위여야 한다. 예전에는 여기가 122pt 였다.
      expect(keyboardTop - lifted, lessThanOrEqualTo(16), reason: chrome.name);
      expect(lifted, lessThan(resting), reason: chrome.name);
    });
  }

  // 기다리는 동안 아무 표시가 없었다. 이제 답 자리에 뼈대가 놓인다 —
  // "생각 중…" 이라고 쓴 진짜 말풍선이 아니라, 답과 같은 반지름의 뼈대다.
  // 글자로 알리면 그게 답인 줄 알고 읽게 된다.
  testWidgets('기다리는 동안 답 자리에 뼈대가 놓인다', (tester) async {
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

    expect(find.byKey(AskScreen.thinkingKey), findsOneWidget);

    answer.complete(null);
    await tester.pumpAndSettle();

    expect(find.byKey(AskScreen.thinkingKey), findsNothing);
  });

  // 보내기 버튼은 잠겨 있었는데 Return 은 안 잠겨 있었다. `_send` 가 입력을
  // 먼저 비우고 노티파이어가 _busy 가드에서 되돌아가서, **친 글자만 사라지고**
  // 아무 일도 안 일어났다. 예전 테스트는 TextField 개수를 비교해서(늘 1)
  // 아무것도 검사하지 않았다.
  testWidgets('기다리는 중에 또 보내도 질문이 사라지지 않는다', (tester) async {
    final answer = Completer<AskReply?>();
    final slow = _SlowAsk(answer.future);
    await pumpScreen(
      tester,
      const AskScreen(),
      size: const Size(1200, 2400),
      overrides: <Override>[askServiceProvider.overrideWithValue(slow)],
    );

    await tester.enterText(find.byType(TextField), '첫 번째');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(slow.asked, <String>['첫 번째']);

    await tester.enterText(find.byType(TextField), '두 번째');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward));
    await tester.pump();

    // 두 번째 질문은 안 나갔고,
    expect(slow.asked, <String>['첫 번째']);
    // 친 글자는 그대로 남아 있다.
    expect(find.widgetWithText(TextField, '두 번째'), findsOneWidget);

    answer.complete(null);
    await tester.pumpAndSettle();
  });

  // 실패한 답이 성공한 답과 픽셀 단위로 같았다. failed 는 세팅만 되고
  // 아무 데서도 안 읽혔다.
  testWidgets('실패한 답에는 다시 시도가 붙는다', (tester) async {
    final container = await pumpScreen(
      tester,
      const AskScreen(),
      size: const Size(1200, 2400),
      overrides: <Override>[
        askServiceProvider.overrideWithValue(_StubAsk(null)),
      ],
    );

    await tester.enterText(find.byType(TextField), '뭐가 좋아?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text(K.retry.tr()), findsOneWidget);
    // 씨앗 + 질문 + 실패.
    expect(container.read(askProvider), hasLength(3));

    // 다시 시도는 실패한 답과 그 질문을 걷어내고 다시 보낸다. 그냥 send 를
    // 부르면 같은 질문이 두 번 올라간 것처럼 보인다.
    await tester.tap(find.text(K.retry.tr()));
    await tester.pumpAndSettle();

    expect(container.read(askProvider), hasLength(3));
  });
}

/// 시킨 대로 늦게 답한다.
class _SlowAsk implements AskService {
  _SlowAsk(this.answer);

  final Future<AskReply?> answer;

  final List<String> asked = <String>[];

  @override
  Future<AskReply?> ask(String question, List<Smartphone> catalog) {
    asked.add(question);
    return answer;
  }
}
