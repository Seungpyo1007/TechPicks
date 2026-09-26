import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';
import 'package:techpicks/app/tab_host.dart';
import 'package:techpicks/app/tp_launch.dart';

import '../support/fake_auth.dart';
import '../support/harness.dart';

/// Firebase 가 없는 빌드. 모든 로그인이 실패한다.
class _NoFirebase extends FakeAuthService {
  _NoFirebase()
    : super(signInResult: const AuthResult.failed(AuthFailure.notConfigured));
}

/// 온보딩과 탭 중 무엇이 먼저 뜨는지는 라우터의 redirect 가 정한다. 그래서
/// 진짜 라우터 위에 올린다. 로그인은 선택이라 게이트에 없다.
Future<ProviderContainer> _boot(WidgetTester tester) async {
  return pumpApp(
    tester,
    // 온보딩·로그인 게이트 자체를 보는 파일이다.
    onboarded: false,
    overrides: <Override>[authServiceProvider.overrideWithValue(_NoFirebase())],
  );
}

void main() {
  setUp(initLocalization);

  // current 만 읽던 때는 앱을 켠 그 순간의 값이 전부였다. Firebase 는 저장된
  // 세션을 비동기로 복원하므로, 늦게 온 계정도 받아야 한다.
  testWidgets('늦게 복원된 세션도 받는다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
    });
    final auth = FakeAuthService();
    final container = await pumpApp(
      tester,
      onboarded: false,
      overrides: <Override>[authServiceProvider.overrideWithValue(auth)],
    );
    await tester.pumpAndSettle();
    // 로그인은 선택이다. 계정이 없어도 앱이 뜬다.
    expect(find.byType(TabHost), findsOneWidget);

    auth.emit(const TpUser(uid: 'u1', email: 'a@b.com'));
    await tester.pumpAndSettle();
    expect(container.read(currentUserProvider)?.uid, 'u1');
    expect(find.byType(TabHost), findsOneWidget);
  });

  testWidgets('저장값을 읽기 전에는 온보딩이 스쳐 지나가지 않는다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
    });

    await pumpApp(
      tester,
      onboarded: false,
      settle: false,
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_NoFirebase()),
      ],
    );

    // 첫 프레임. 아직 아무것도 모른다.
    expect(find.byType(OnboardingScreen), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(TabHost), findsOneWidget);
  });

  testWidgets('처음 켜면 온보딩이 나온다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await _boot(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('온보딩을 마치면 로그인 없이 바로 앱이다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
    });

    await _boot(tester);
    expect(find.byType(TabHost), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  // 네이티브 스플래시가 첫 프레임에서 사라지고, 저장값을 읽는 동안 빈 화면이
  // 지나간 뒤, 첫 화면이 툭 나타났다. 켤 때마다 흰 화면이 한 번 깜빡였다.
  group('켜지는 장면', () {
    testWidgets('읽는 동안 로고를 들고 있는다', (tester) async {
      await initLocalization();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'is_tutorial_completed': true,
      });

      await pumpApp(
        tester,
        onboarded: false,
        settle: false,
        overrides: <Override>[
          authServiceProvider.overrideWithValue(_NoFirebase()),
        ],
      );

      // 첫 프레임에 로고가 떠 있다. 그 아래에서 화면이 자리를 잡는 중이다.
      expect(find.byType(TpLaunch), findsOneWidget);
      expect(find.image(const AssetImage('assets/logo/logo.png')), findsOne);

      await tester.pumpAndSettle();
      expect(find.byType(TabHost), findsOneWidget);
    });

    testWidgets('로고가 열리고 나면 아무것도 안 얹는다', (tester) async {
      await initLocalization();
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await _boot(tester);
      await tester.pumpAndSettle();

      // 다 열린 뒤에는 위젯이 자리를 비운다 — 스택도 불투명 판도 없다.
      expect(
        find.image(const AssetImage('assets/logo/logo.png')),
        findsNothing,
      );
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('네이티브 스플래시와 같은 크기로 그린다', (tester) async {
      // LaunchImage@3x 가 375px 이라 화면에서는 125pt 다. 이 값이 어긋나면
      // 넘어오는 순간 로고가 한 번 튄다.
      expect(TpLaunch.logoSize, 125);
    });
  });
}
