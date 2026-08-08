import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/feature/ask/ask_screen.dart';
import 'package:techpicks/feature/login/email_login_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 입력창 이름과 새 답 알림.
///
/// 이름을 hintText 로만 주면 글자를 치는 순간 사라진다. 그 뒤로 스크린 리더는
/// 그 필드가 뭘 받는 칸인지 말해줄 수 없다.

List<SemanticsData> _nodes(WidgetTester tester) {
  final out = <SemanticsData>[];
  void walk(SemanticsNode node) {
    out.add(node.getSemanticsData());
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  void fromOwner(PipelineOwner owner) {
    final root = owner.semanticsOwner?.rootSemanticsNode;
    if (root != null) walk(root);
    owner.visitChildren(fromOwner);
  }

  fromOwner(tester.binding.rootPipelineOwner);
  return out;
}

Iterable<SemanticsData> _fields(WidgetTester tester) =>
    _nodes(tester).where((d) => d.flagsCollection.isTextField);

void main() {
  setUp(initLocalization);

  testWidgets('이메일·비밀번호 칸은 글자를 쳐도 이름이 남는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, EmailLoginScreen(onBack: () {}));

    expect(
      _fields(tester).map((d) => d.label),
      containsAll(<String>[K.emailLabel.tr(), K.passwordLabel.tr()]),
    );

    await tester.enterText(find.byType(TextField).first, 'a@b.com');
    await tester.pumpAndSettle();

    expect(
      _fields(tester).map((d) => d.label),
      contains(K.emailLabel.tr()),
      reason: '힌트가 사라져도 이름은 남아야 한다',
    );
    handle.dispose();
  });

  testWidgets('상담 입력창도 이름이 남는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const AskScreen(), size: const Size(1200, 2400));

    await tester.enterText(find.byType(TextField), '뭐가 좋아?');
    await tester.pumpAndSettle();

    expect(_fields(tester).map((d) => d.label), contains(K.askHint.tr()));
    handle.dispose();
  });

  testWidgets('새로 온 답만 읽어준다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const AskScreen(),
      size: const Size(1200, 2400),
      overrides: <Override>[
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );

    // 씨앗 인사 하나뿐일 때도 그게 마지막 AI 말풍선이다.
    expect(
      _nodes(tester).where((d) => d.flagsCollection.isLiveRegion).length,
      1,
    );

    await tester.enterText(find.byType(TextField), '뭐가 좋아?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final live = _nodes(
      tester,
    ).where((d) => d.flagsCollection.isLiveRegion).toList();
    // 답이 왔어도 알리는 건 여전히 하나 — 가장 마지막 것.
    expect(live.length, 1);
    expect(live.single.label, isNot(K.chatSeed.tr()));
    handle.dispose();
  });
}
