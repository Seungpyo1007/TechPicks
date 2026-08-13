import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:riverpod/misc.dart' show Override;

import '../support/harness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';

/// Firebase 를 띄우지 않는 가짜. 어떤 방법이 성공할지 테스트가 정한다.
class _StubAuth implements AuthService {
  _StubAuth({this.succeeds = const <AuthMethod>{AuthMethod.anonymous}});

  final Set<AuthMethod> succeeds;
  final List<AuthMethod> tried = <AuthMethod>[];
  TpUser? _current;

  @override
  TpUser? get current => _current;

  @override
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async {
    tried.add(method);
    if (!succeeds.contains(method)) return null;
    return _current = TpUser(
      uid: 'u1',
      isAnonymous: method == AuthMethod.anonymous,
    );
  }

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async => _current = null;
}

ProviderContainer? _container;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  AuthService? auth,
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

/// 사용자가 시트를 닫은 경우.
class _CancelingAuth implements AuthService {
  @override
  TpUser? get current => null;

  @override
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async => throw const AuthCanceled();

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  setUp(initLocalization);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('온보딩', () {
    testWidgets('명세의 세 문구를 그대로 쓴다', (tester) async {
      await _pump(tester, const OnboardingScreen(), auth: _StubAuth());

      expect(find.text('Every spec.\nOne number.'), findsOneWidget);
      expect(
        find.textContaining('scores every device on performance'),
        findsOneWidget,
      );
    });

    testWidgets('Next 로 넘기면 마지막에 Get started', (tester) async {
      await _pump(tester, const OnboardingScreen(), auth: _StubAuth());

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
        auth: _StubAuth(),
      );

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // v1 은 여기서 되돌릴 수 없다는 다이얼로그를 띄웠다.
      expect(find.byType(AlertDialog), findsNothing);
      expect(done, isTrue);
      expect(_container!.read(onboardingDoneProvider), isTrue);
    });

    testWidgets('Get started 가 완료 플래그를 남긴다', (tester) async {
      await _pump(tester, const OnboardingScreen(), auth: _StubAuth());

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();

      expect(_container!.read(onboardingDoneProvider), isTrue);
    });
  });

  group('로그인', () {
    testWidgets('버튼 네 개가 명세 순서로', (tester) async {
      await _pump(tester, const LoginScreen(), auth: _StubAuth());

      expect(find.text('Welcome to\nTechPicks'), findsOneWidget);
      for (final b in LoginScreen.buttons) {
        expect(find.text(b.key.tr()), findsOneWidget, reason: b.key);
      }
      expect(find.text('No account yet?'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      // Facebook 은 뺐다.
      expect(find.textContaining('Facebook'), findsNothing);
    });

    testWidgets('취소는 실패가 아니다', (tester) async {
      // 스스로 시트를 닫은 사람에게 "연결되지 않았습니다"를 보여주면
      // 앱이 고장 난 것처럼 읽힌다.
      await _pump(tester, const LoginScreen(), auth: _CancelingAuth());

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      expect(find.textContaining('not connected yet'), findsNothing);
      expect(_container!.read(currentUserProvider), isNull);
    });

    testWidgets('계정 없이 둘러보기는 익명 로그인', (tester) async {
      final auth = _StubAuth();
      var signedIn = false;
      await _pump(
        tester,
        LoginScreen(onSignedIn: () => signedIn = true),
        auth: auth,
      );

      await tester.tap(find.text('Browse without an account'));
      await tester.pumpAndSettle();

      expect(auth.tried, <AuthMethod>[AuthMethod.anonymous]);
      expect(signedIn, isTrue);
      expect(_container!.read(currentUserProvider)?.isAnonymous, isTrue);
    });

    testWidgets('아직 연결 안 된 방법은 안내를 띄운다', (tester) async {
      // 익명만 성공하도록 두면 나머지 넷은 안내로 떨어진다.
      final auth = _StubAuth(
        succeeds: const <AuthMethod>{AuthMethod.anonymous},
      );
      await _pump(tester, const LoginScreen(), auth: auth);

      await tester.tap(find.text('Continue with Apple'));
      await tester.pumpAndSettle();

      expect(find.textContaining('not connected yet'), findsOneWidget);
      expect(_container!.read(currentUserProvider), isNull);
    });

    testWidgets('두 크롬 모두에서 그려진다', (tester) async {
      for (final chrome in TpChrome.values) {
        await _pump(
          tester,
          const LoginScreen(),
          auth: _StubAuth(),
          chrome: chrome,
        );
        expect(find.text('Continue with email'), findsOneWidget);
      }
    });
  });
}
