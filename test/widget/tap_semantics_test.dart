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

/// 탭 액션이 있는데 버튼이 아니거나 이름이 없는 노드.
List<String> _unlabeledTapTargets(WidgetTester tester) {
  final bad = <String>[];

  void walk(SemanticsNode node) {
    final data = node.getSemanticsData();
    final tappable = data.hasAction(SemanticsAction.tap);
    if (tappable) {
      // 입력창도 탭 액션을 갖는다. 그쪽은 버튼이 아니라 텍스트 필드로 읽혀야
      // 맞다.
      final actionable =
          data.flagsCollection.isButton || data.flagsCollection.isTextField;
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
