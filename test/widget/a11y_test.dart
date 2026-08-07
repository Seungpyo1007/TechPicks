import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/feature/ask/ask_screen.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/compare/picker_screen.dart';
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

final _screens = <String, Widget>{
  'home': const HomeScreen(),
  'rank': RankScreen(onScan: () {}),
  'compare': const CompareScreen(),
  'detail': const DetailScreen(slug: 'galaxy-s25'),
  'ask': const AskScreen(),
  'you': const YouScreen(),
  'login': const LoginScreen(),
  'onboarding': const OnboardingScreen(),
  // 뒤로 가기처럼 아이콘만 있는 버튼이 있는 화면들.
  'detail-with-back': DetailScreen(slug: 'galaxy-s25', onBack: () {}),
  'picker': PickerScreen(onDone: () {}),
  'email-login': EmailLoginScreen(onBack: () {}),
};

/// 스캔·뷰어는 애니메이션이 멈추지 않아 settle 이 끝나지 않는다.
final _noSettle = <String, Widget>{
  'scan': ScanScreen(onBack: () {}, recognizedText: 'Galaxy S25 Ultra Samsung'),
  'viewer': ViewerScreen(deviceName: 'Galaxy S25', onBack: () {}),
};

void main() {
  setUp(initLocalization);

  for (final entry in _screens.entries) {
    testWidgets('${entry.key} — 탭 타깃 크기', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(
        tester,
        entry.value,
        size: const Size(1200, 3200),
        overrides: <Override>[
          askServiceProvider.overrideWithValue(const LocalAskService()),
        ],
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      // 아이콘만 있는 버튼은 스크린 리더가 읽을 이름이 있어야 한다.
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  for (final entry in _noSettle.entries) {
    testWidgets('${entry.key} — 탭 타깃 크기', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreenNoSettle(tester, entry.value,
          size: const Size(1200, 2400));
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
