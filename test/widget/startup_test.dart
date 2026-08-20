import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/feature/login/email_login_screen.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';
import 'package:techpicks/app/tab_host.dart';
import 'package:techpicks/app/tp_launch.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// Firebase 가 없는 빌드. 모든 로그인이 실패한다.
class _NoFirebase implements AuthService {
  @override
  Stream<TpUser?> changes() => const Stream<TpUser?>.empty();
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
  Future<bool> sendPasswordReset(String email) async => false;

  @override
  Future<TpUser?> updateName(String name) async => null;

  @override
  Future<void> signOut() async {}
}

/// 온보딩·로그인·탭 중 무엇이 먼저 뜨는지는 이제 라우터의 redirect 가
/// 정한다. 그래서 진짜 라우터 위에 올린다.
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
  // 세션을 비동기로 복원하므로, 돌아온 사용자가 로그인 화면에 갇혔다.
  testWidgets('늦게 복원된 세션도 로그인으로 친다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
    });
    final auth = _LateSession();
    final container = await pumpApp(
      tester,
      onboarded: false,
      overrides: <Override>[authServiceProvider.overrideWithValue(auth)],
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    auth.restore(const TpUser(uid: 'u1', email: 'a@b.com'));
    await tester.pumpAndSettle();

    expect(container.read(currentUserProvider)?.uid, 'u1');
    expect(find.byType(TabHost), findsOneWidget);
  });

  group('손님으로 쓰기', _guest);

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
      expect(find.byType(LoginScreen), findsOneWidget);
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

/// 저장된 세션이 늦게 복원되는 Firebase.
class _LateSession implements AuthService {
  final _users = StreamController<TpUser?>.broadcast();

  void restore(TpUser user) => _users.add(user);

  @override
  Stream<TpUser?> changes() => _users.stream;

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
  Future<bool> sendPasswordReset(String email) async => false;

  @override
  Future<TpUser?> updateName(String name) async => null;

  @override
  Future<void> signOut() async {}
}
