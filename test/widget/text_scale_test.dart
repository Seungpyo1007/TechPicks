import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
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

/// 글자 크기를 키웠을 때.
///
/// iOS 손쉬운 사용과 Android 접근성 설정 둘 다 본문 글자를 키운다. 명세는
/// 이 경우를 안 다루고 높이를 픽셀로 고정한 요소가 많다 — 버튼 52, 탭 캡슐
/// 62, 칩 38, 랭킹 행 62.
///
/// 배율은 1.6 이다. 2.0 은 탭 캡슐(62)부터 무너지는데, 거기까지 맞추려면
/// 명세의 고정 높이를 전부 다시 정해야 한다. 그건 디자인 쪽 결정이다.
///
/// [layout_test.dart] 와 같은 이유로 글자가 들어맞는지는 보지 않는다.

/// iOS 402×874, Android 412×892.
const Size _iosFrame = Size(402, 874);
const Size _androidFrame = Size(412, 892);

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

const double _scale = 1.6;

void main() {
  setUp(initLocalization);
  // 홈은 저장된 관심목록이 없으면 빈 카드 하나뿐이라, 이 스윕이 결론
  // 카드도 행도 한 번도 안 본 채로 초록이었다.
  setUp(seedHomeContent);
  for (final frame in <(String, TpChrome, Size)>[
    ('ios', TpChrome.ios, _iosFrame),
    ('android', TpChrome.android, _androidFrame),
  ]) {
    final (name, chrome, size) = frame;

    for (final entry in _screens().entries) {
      testWidgets('$name · ${entry.key}', (tester) async {
        await initLocalization();
        await pumpScreen(
          tester,
          entry.value,
          chrome: chrome,
          size: size,
          textScale: _scale,
          overrides: <Override>[
            askServiceProvider.overrideWithValue(const LocalAskService()),
          ],
        );
        expect(tester.takeException(), isNull);
      });
    }

    for (final entry in _noSettle().entries) {
      testWidgets('$name · ${entry.key}', (tester) async {
        await initLocalization();
        await pumpScreenNoSettle(
          tester,
          entry.value,
          chrome: chrome,
          size: size,
          textScale: _scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
