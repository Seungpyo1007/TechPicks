import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/feature/ask/ask_screen.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/compare/picker_screen.dart';
import 'package:techpicks/feature/cpu/processor_screen.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/home/home_screen.dart';
import 'package:techpicks/feature/login/email_login_screen.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/feature/scan/scan_screen.dart';
import 'package:techpicks/feature/viewer/viewer_screen.dart';
import 'package:techpicks/feature/you/you_screen.dart';

import '../support/harness.dart';

/// 누를 수 있는 것은 전부 버튼으로 읽혀야 한다.
///
/// `labeledTapTargetGuideline` 은 이미 탭 액션이 붙은 노드만 본다. 맨
/// [GestureDetector] 는 시맨틱 트리에 탭 액션을 안 만들어서 그 검사를 통째로
/// 빠져나간다. 스크린 리더에는 누를 수 있다는 사실 자체가 안 보인다.
///
/// 여기서는 반대로 본다 — 탭 액션이 있는 노드가 버튼으로 표시돼 있고 읽을
/// 이름이 있는지.

Map<String, Widget> _screens() => <String, Widget>{
  'home': HomeScreen(onDeviceTap: (_) {}, onAdd: () {}),
  'rank': RankScreen(onDeviceTap: (_) {}, onScan: () {}),
  'cpu': const ProcessorScreen(),
  'compare': CompareScreen(onPick: (_) {}),
  'picker': PickerScreen(onDone: () {}),
  'detail': DetailScreen(slug: 'galaxy-s25-ultra', onBack: () {}),
  'ask': const AskScreen(),
  'you': const YouScreen(name: '홍길동', email: 'hong@example.com'),
  'login': const LoginScreen(),
  'email-login': EmailLoginScreen(onBack: () {}),
  'onboarding': const OnboardingScreen(),
};

/// 끝나지 않는 애니메이션이 있어 settle 이 안 끝나는 화면.
Map<String, Widget> _noSettle() => <String, Widget>{
  'scan': ScanScreen(onBack: () {}, recognizedText: 'Galaxy S25 Ultra'),
  'viewer': ViewerScreen(deviceName: 'Galaxy S25 Ultra', onBack: () {}),
};

/// 탭 액션이 있는데 버튼이 아니거나 이름이 없는 노드, **그리고 그 반대**.
///
/// 오래 앞쪽만 봤다. 그래서 정반대 결함이 앱 전체에 깔려 있었다 — `버튼`
/// 이라고 알리면서 **누르는 동작이 없는** 노드다.
/// `Semantics(button: true, excludeSemantics: true)` 로 안쪽 글자를 묶으면,
/// 같이 묶여서 사라지는 것 중에 `GestureDetector` 가 내주던 탭 액션이 있다.
/// 스크린 리더는 버튼이라고 읽어주고, 두 번 눌러도 아무 일이 안 일어난다.
///
/// 랭킹은 버튼 55개 중 47개가, 내 정보는 11개 중 9개가 그랬다. **탭 바
/// 다섯 칸이 전부 여기 있었다** — 보이스오버로는 탭을 바꿀 수가 없었다.
List<String> _unlabeledTapTargets(WidgetTester tester) {
  final bad = <String>[];

  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    final tappable = data.hasAction(SemanticsAction.tap);
    if (data.flagsCollection.isButton && !tappable) {
      bad.add('눌리지 않는 버튼: "${data.label}"');
    }
    if (tappable) {
      // 입력창도 탭 액션을 갖는다. 그쪽은 버튼이 아니라 텍스트 필드로 읽혀야
      // 맞다. 앱 밖으로 나가는 것은 링크로 읽혀야 맞다 — 스크린 리더가
      // 버튼과 링크를 다르게 알린다.
      final actionable =
          data.flagsCollection.isButton ||
          data.flagsCollection.isTextField ||
          data.flagsCollection.isLink ||
          // 켜고 끄는 줄은 스위치로 읽힌다. 버튼이 아니고, 버튼이면 안 된다.
          data.flagsCollection.isToggled != Tristate.none;
      if (!actionable) {
        bad.add('버튼 아님: "${data.label}"');
      } else if (data.label.trim().isEmpty) {
        bad.add('이름 없음: ${node.rect}');
      }
    }
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
  return bad;
}

void main() {
  setUp(initLocalization);
  // 홈은 저장된 관심목록이 없으면 빈 카드 하나뿐이라, 이 스윕이 결론
  // 카드도 행도 한 번도 안 본 채로 초록이었다.
  setUp(seedHomeContent);

  for (final entry in _screens().entries) {
    testWidgets(entry.key, (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(
        tester,
        entry.value,
        size: const Size(1200, 3200),
        overrides: <Override>[
          askServiceProvider.overrideWithValue(const LocalAskService()),
        ],
      );
      expect(_unlabeledTapTargets(tester), isEmpty);
      handle.dispose();
    });
  }

  for (final entry in _noSettle().entries) {
    testWidgets(entry.key, (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreenNoSettle(
        tester,
        entry.value,
        size: const Size(1200, 3200),
      );
      expect(_unlabeledTapTargets(tester), isEmpty);
      handle.dispose();
    });
  }
}
