import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/fake_auth.dart';
import '../support/harness.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeAuthService auth, {
  VoidCallback? onSignedIn,
  TpChrome chrome = TpChrome.ios,
}) => pumpScreen(
  tester,
  LoginScreen(onClose: () {}, onSignedIn: onSignedIn),
  chrome: chrome,
  size: const Size(1200, 2000),
  overrides: <Override>[authServiceProvider.overrideWithValue(auth)],
);

Future<void> _toEmail(WidgetTester tester) async {
  await tester.tap(find.text(K.continueEmail.tr()));
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, String email, String password) async {
  final fields = find.byType(EditableText);
  await tester.enterText(fields.first, email);
  await tester.enterText(fields.last, password);
  await tester.pumpAndSettle();
}

/// 세그먼트와 알약이 같은 글자라 알약은 맨 뒤다.
Future<void> _submit(WidgetTester tester, String key) async {
  await tester.tap(find.text(key.tr()).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(initLocalization);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('방법 고르기', () {
    testWidgets('iOS 는 Apple, Google, 이메일 순서', (tester) async {
      await _pump(tester, FakeAuthService());

      expect(find.text(K.loginTitle.tr()), findsOneWidget);
      final apple = tester.getTopLeft(find.byType(SignInWithAppleButton)).dy;
      final google = tester.getTopLeft(find.text(K.continueGoogle.tr())).dy;
      final email = tester.getTopLeft(find.text(K.continueEmail.tr())).dy;
      expect(apple, lessThan(google));
      expect(google, lessThan(email));
      // 익명 둘러보기는 없다. 로그인은 닫으면 그만이다.
      expect(find.textContaining('without an account'), findsNothing);
    });

    testWidgets('Android 는 Apple 이 없고, 설정 전엔 Google 도 숨는다', (tester) async {
      await _pump(tester, FakeAuthService(), chrome: TpChrome.android);

      expect(find.byType(SignInWithAppleButton), findsNothing);
      expect(find.text(K.continueGoogle.tr()), findsNothing);
      expect(find.text(K.continueEmail.tr()), findsOneWidget);
    });

    testWidgets('취소는 오류가 아니다', (tester) async {
      final auth = FakeAuthService(
        signInResult: const AuthResult.failed(AuthFailure.canceled),
      );
      await _pump(tester, auth);

      await tester.tap(find.text(K.continueGoogle.tr()));
      await tester.pumpAndSettle();

      expect(auth.signIns, <AuthMethod>[AuthMethod.google]);
      expect(find.text(K.authFailed.tr()), findsNothing);
      expect(find.text(K.authNetwork.tr()), findsNothing);
    });

    testWidgets('실패는 까닭을 말한다', (tester) async {
      await _pump(
        tester,
        FakeAuthService(
          signInResult: const AuthResult.failed(AuthFailure.network),
        ),
      );

      await tester.tap(find.text(K.continueGoogle.tr()));
      await tester.pumpAndSettle();

      expect(find.text(K.authNetwork.tr()), findsOneWidget);
    });

    test('오류마다 문장이 있다, 취소만 빼고', () {
      for (final f in AuthFailure.values) {
        final message = authMessage(f);
        if (f == AuthFailure.canceled) {
          expect(message, isNull);
        } else {
          expect(message, isNotEmpty, reason: f.name);
        }
      }
    });
  });

  group('입력 검사', () {
    test('이메일 형태만 통과시킨다', () {
      expect(LoginScreen.looksLikeEmail('a@b.com'), isTrue);
      expect(LoginScreen.looksLikeEmail('  a@b.co.kr '), isTrue);

      expect(LoginScreen.looksLikeEmail('a@b'), isFalse);
      expect(LoginScreen.looksLikeEmail('@b.com'), isFalse);
      expect(LoginScreen.looksLikeEmail('a@'), isFalse);
      expect(LoginScreen.looksLikeEmail('a b@c.com'), isFalse);
      expect(LoginScreen.looksLikeEmail('a@.com'), isFalse);
      expect(LoginScreen.looksLikeEmail(''), isFalse);
    });

    // 빈 칸에 "형식이 아닙니다"는 고장 난 것처럼 읽힌다.
    testWidgets('빈 칸은 채우라고 말한다', (tester) async {
      final auth = FakeAuthService();
      await _pump(tester, auth);
      await _toEmail(tester);

      await _submit(tester, K.signIn);

      expect(find.text(K.emailNeeded.tr()), findsOneWidget);
      expect(find.text(K.emailInvalid.tr()), findsNothing);
      expect(auth.signIns, isEmpty);
    });

    testWidgets('잘못된 이메일은 서버까지 가지 않는다', (tester) async {
      final auth = FakeAuthService();
      await _pump(tester, auth);
      await _toEmail(tester);

      await _fill(tester, 'nope', 'longenough');
      await _submit(tester, K.signIn);

      expect(find.text(K.emailInvalid.tr()), findsOneWidget);
      expect(auth.signIns, isEmpty);
    });

    testWidgets('짧은 비밀번호도 막는다', (tester) async {
      final auth = FakeAuthService();
      await _pump(tester, auth);
      await _toEmail(tester);

      await _fill(tester, 'a@b.com', '12345');
      await _submit(tester, K.signIn);

      expect(find.text(K.passwordShort.tr()), findsOneWidget);
      expect(auth.signIns, isEmpty);
    });
  });

  group('이메일', () {
    testWidgets('제대로 넣으면 로그인하고, 체크를 보인 뒤 닫힌다', (tester) async {
      final auth = FakeAuthService();
      var signedIn = false;
      await _pump(tester, auth, onSignedIn: () => signedIn = true);
      await _toEmail(tester);

      await _fill(tester, 'a@b.com', 'longenough');
      // 끝까지 감으면 체크를 보여주는 시간도 지나 버린다.
      await tester.tap(find.text(K.signIn.tr()).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(auth.emails, <String>['a@b.com']);
      expect(find.text(K.signedIn.tr()), findsOneWidget);
      expect(signedIn, isFalse);

      await tester.pump(LoginScreen.doneHold);
      expect(signedIn, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('틀린 비밀번호는 그렇게 말한다', (tester) async {
      await _pump(
        tester,
        FakeAuthService(
          signInResult: const AuthResult.failed(AuthFailure.badCredentials),
        ),
      );
      await _toEmail(tester);

      await _fill(tester, 'a@b.com', 'longenough');
      await _submit(tester, K.signIn);

      expect(find.text(K.authBadCredentials.tr()), findsOneWidget);
      expect(find.text(K.signedIn.tr()), findsNothing);
    });

    testWidgets('가입으로 바꾸면 가입을 부른다', (tester) async {
      final auth = FakeAuthService();
      await _pump(tester, auth);
      await _toEmail(tester);

      await tester.tap(find.textContaining(K.noAccount.tr()));
      await tester.pumpAndSettle();
      expect(find.text(K.signupTitle.tr()), findsOneWidget);
      expect(find.text(K.pwHint.tr()), findsOneWidget);
      // 가입에는 비밀번호 찾기가 없다.
      expect(find.text(K.forgotPw.tr()), findsNothing);

      await _fill(tester, 'new@b.com', 'longenough');
      await _submit(tester, K.signup);

      expect(auth.signUps, <String>['new@b.com']);
      expect(auth.signIns, isEmpty);
    });

    testWidgets('이미 있는 주소로 가입하면 그렇게 말한다', (tester) async {
      await _pump(
        tester,
        FakeAuthService(
          signUpResult: const AuthResult.failed(AuthFailure.emailInUse),
        ),
      );
      await _toEmail(tester);

      await tester.tap(find.textContaining(K.noAccount.tr()));
      await tester.pumpAndSettle();
      await _fill(tester, 'new@b.com', 'longenough');
      await _submit(tester, K.signup);

      expect(find.text(K.authEmailInUse.tr()), findsOneWidget);
    });

    testWidgets('비밀번호 찾기는 적은 주소를 들고 가서 메일을 보낸다', (tester) async {
      final auth = FakeAuthService();
      await _pump(tester, auth);
      await _toEmail(tester);

      await tester.enterText(find.byType(EditableText).first, 'a@b.com');
      await tester.tap(find.text(K.forgotPw.tr()));
      await tester.pumpAndSettle();

      expect(find.text(K.resetTitle.tr()), findsOneWidget);
      expect(find.text('a@b.com'), findsOneWidget);

      await tester.tap(find.text(K.resetSend.tr()));
      await tester.pumpAndSettle();

      expect(auth.resets, <String>['a@b.com']);
      expect(find.text(K.resetSent.tr()), findsOneWidget);
    });

    testWidgets('한국어로도 그려진다', (tester) async {
      await initLocalization(locale: const Locale('ko', 'KR'));
      await _pump(tester, FakeAuthService());
      await _toEmail(tester);

      expect(find.text('이메일'), findsOneWidget);
      expect(find.text('비밀번호'), findsOneWidget);
      expect(find.text('로그인'), findsWidgets);
    });
  });
}
