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

/// 실제 기기 크기에서 넘치지 않는지.
///
/// 다른 위젯 테스트는 1200×3000 캔버스에 올린다. 그 크기에서는 Row 가 절대
/// 안 넘쳐서 오버플로가 잡히지 않는다. 여기서는 명세 Chrome geometry 표의
/// 프레임 그대로 그린다.
///
/// 한국어도 같이 돈다. 명세는 "Korean is roughly 15% shorter ... neither
/// wraps" 라고 적었지만 그건 프로토타입 기준이고, 여기 폰트는 다르다.
///
/// **글자가 들어맞는지를 보는 테스트가 아니다.** flutter_test 의 대체 폰트는
/// 글리프 폭이 대략 글자 크기와 같아서 SF Pro·Roboto 보다 훨씬 넓다.
/// `Continue with Google` 이 15px 에서 305px 로 잰다. 그래서 여기서 확인하는
/// 것은 레이아웃이 **넘치는 대신 줄어드는가** 다 — 긴 번역이나 큰 글자 크기
/// 설정에서도 같은 문제가 실제로 생긴다.

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

void main() {
  for (final locale in <Locale>[
    const Locale('en', 'US'),
    const Locale('ko', 'KR'),
  ]) {
    final lang = locale.languageCode;

    for (final frame in <(String, TpChrome, Size)>[
      ('ios', TpChrome.ios, _iosFrame),
      ('android', TpChrome.android, _androidFrame),
    ]) {
      final (name, chrome, size) = frame;

      for (final entry in _screens().entries) {
        testWidgets('$lang · $name · ${entry.key}', (tester) async {
          await initLocalization(locale: locale);
          await pumpScreen(
            tester,
            entry.value,
            chrome: chrome,
            size: size,
            overrides: <Override>[
              askServiceProvider.overrideWithValue(const LocalAskService()),
            ],
          );
          expect(tester.takeException(), isNull);
        });
      }

      for (final entry in _noSettle().entries) {
        testWidgets('$lang · $name · ${entry.key}', (tester) async {
          await initLocalization(locale: locale);
          await pumpScreenNoSettle(
            tester,
            entry.value,
            chrome: chrome,
            size: size,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
