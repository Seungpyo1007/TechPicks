import 'package:easy_localization/easy_localization.dart';
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
import 'package:techpicks/shared/copy_keys.dart';

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

    Future<void> toLast(WidgetTester tester) async {
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    }

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

    testWidgets('마지막 장에는 건너뛰기가 없다', (tester) async {
      await _pump(tester, const OnboardingScreen(), auth: FakeAuthService());
      await toLast(tester);

      expect(find.text('Skip').hitTestable(), findsNothing);
    });

    testWidgets('카드 안은 실제 부품이다: 지수 숫자, 비교표, 답 카드', (tester) async {
      await _pump(tester, const OnboardingScreen(), auth: FakeAuthService());
      expect(find.text('79'), findsOneWidget);
      expect(find.text(K.tpIndex.tr()), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Galaxy S26 Ultra'), findsOneWidget);
      expect(find.text('iPhone 17 Pro Max'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(K.onbAsk.tr()), findsOneWidget);
      expect(find.text('Vivo X300s'), findsOneWidget);
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

    testWidgets('Get started 가 완료 표시를 남기고 끝낸다', (tester) async {
      var done = 0;
      await _pump(
        tester,
        OnboardingScreen(onDone: () => done++),
        auth: FakeAuthService(),
      );
      await toLast(tester);

      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(done, 1);
      expect(_container!.read(onboardingDoneProvider), isTrue);
    });
  });
}
