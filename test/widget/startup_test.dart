import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/app.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/feature/login/email_login_screen.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';
import 'package:techpicks/app/tab_host.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// Firebase 가 없는 빌드. 모든 로그인이 실패한다.
class _NoFirebase implements AuthService {
  @override
  TpUser? get current => null;

  @override
  Future<TpUser?> signIn(
    AuthMethod m, {
    String? email,
    String? password,
  }) async => null;

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async {}
}

Future<ProviderContainer> _boot(WidgetTester tester) async {
  return pumpScreen(
    tester,
    const _RootHost(),
    overrides: <Override>[authServiceProvider.overrideWithValue(_NoFirebase())],
  );
}

/// TechPicksApp 은 MaterialApp 을 직접 만든다. 하네스가 이미 하나 올리므로
/// 루트 분기만 떼어 쓴다.
class _RootHost extends StatelessWidget {
  const _RootHost();

  @override
  Widget build(BuildContext context) => const TechPicksRoot();
}

void main() {
  setUp(initLocalization);

  group('손님으로 쓰기', _guest);

  testWidgets('저장값을 읽기 전에는 온보딩이 스쳐 지나가지 않는다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
    });

    await pumpScreenNoSettle(
      tester,
      const _RootHost(),
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_NoFirebase()),
      ],
    );

    // 첫 프레임. 아직 아무것도 모른다.
    expect(find.byType(OnboardingScreen), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('처음 켜면 온보딩이 나온다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await _boot(tester);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('Firebase 가 없어도 계정 없이 들어갈 수 있다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
    });

    await _boot(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text(K.loginAnon.tr()));
    await tester.pumpAndSettle();

    expect(find.byType(TabHost), findsOneWidget);
  });

  testWidgets('Sign up 은 가입 화면을 연다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
    });

    await _boot(tester);
    await tester.tap(find.text(K.signup.tr()));
    await tester.pumpAndSettle();

    expect(find.byType(EmailLoginScreen), findsOneWidget);
    // 가입 쪽부터 보여준다.
    expect(find.text(K.signupTitle.tr()), findsWidgets);
    expect(find.byType(TabHost), findsNothing);
  });
}

/// 계정 없이 쓰기로 한 선택.
void _guest() {
  testWidgets('한 번 고르면 다음 실행에도 로그인 화면을 안 본다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
    });

    await _boot(tester);
    await tester.tap(find.text(K.loginAnon.tr()));
    await tester.pumpAndSettle();
    expect(find.byType(TabHost), findsOneWidget);

    // 다시 켠다. 저장값은 그대로다.
    await _boot(tester);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.byType(TabHost), findsOneWidget);
  });

  testWidgets('로그아웃하면 다시 로그인 화면으로 간다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
      'browsing_as_guest': true,
    });

    final container = await _boot(tester);
    expect(find.byType(TabHost), findsOneWidget);

    await container.read(guestProvider.notifier).clear();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
