import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

import '../support/fake_auth.dart';
import '../support/harness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';

ProviderContainer? _container;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  FakeAuthService? auth,
  TpChrome chrome = TpChrome.ios,
}) async {
  _container = await pumpScreen(
    tester,
    screen,
    chrome: chrome,
    size: const Size(1200, 2400),
    overrides: <Override>[
      if (auth != null) authServiceProvider.overrideWithValue(auth),
    ],
  );
}

void main() {
  setUp(initLocalization);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('온보딩', () {
    testWidgets('명세의 세 문구를 그대로 쓴다', (tester) async {
      await _pump(tester, const OnboardingScreen(), auth: FakeAuthService());

      expect(find.text('Every spec.\nOne number.'), findsOneWidget);
      expect(
        find.textContaining('scores every device on performance'),
        findsOneWidget,
      );
    });

    testWidgets('Next 로 넘기면 마지막에 Get started', (tester) async {
      await _pump(tester, const OnboardingScreen(), auth: FakeAuthService());

      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Two devices.\nOne table.'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Ask.\nThen decide.'), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('Skip 은 경고 없이 바로 끝난다', (tester) async {
      var done = false;
      await _pump(
        tester,
        OnboardingScreen(onDone: () => done = true),
        auth: FakeAuthService(),
      );

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // v1 은 여기서 되돌릴 수 없다는 다이얼로그를 띄웠다.
      expect(find.byType(AlertDialog), findsNothing);
      expect(done, isTrue);
      expect(_container!.read(onboardingDoneProvider), isTrue);
    });

    testWidgets('Get started 가 완료 플래그를 남긴다', (tester) async {
      await _pump(tester, const OnboardingScreen(), auth: FakeAuthService());

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(_container!.read(onboardingDoneProvider), isTrue);
    });
  });
}
