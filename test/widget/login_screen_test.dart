import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/shared/brand/tp_logo.dart';
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

final Finder _appleLogo = find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is AppleLogoPainter,
);

void main() {
  setUp(initLocalization);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('방법 고르기', () {
    testWidgets('iOS 는 Apple, Google, 이메일 순서', (tester) async {
      await _pump(tester, FakeAuthService());

      expect(find.text(K.loginTitle.tr()), findsOneWidget);
      final apple = tester.getTopLeft(find.text(K.continueApple.tr())).dy;
      final google = tester.getTopLeft(find.text(K.continueGoogle.tr())).dy;
      final email = tester.getTopLeft(find.text(K.continueEmail.tr())).dy;
      expect(apple, lessThan(google));
      expect(google, lessThan(email));
      // 익명 둘러보기는 없다. 로그인은 닫으면 그만이다.
      expect(find.textContaining('without an account'), findsNothing);
    });

    testWidgets('Android 는 Apple 이 없고, 설정 전엔 Google 도 숨는다', (tester) async {
      await _pump(tester, FakeAuthService(), chrome: TpChrome.android);

      expect(find.text(K.continueApple.tr()), findsNothing);
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

    testWidgets('Apple 을 기다리는 동안 돌림 표시가 뜨고 다른 버튼은 잠긴다', (tester) async {
      final auth = _HangingAuth();
      await _pump(tester, auth);

      await tester.tap(find.text(K.continueApple.tr()));
      await tester.pump();

      expect(auth.signIns, <AuthMethod>[AuthMethod.apple]);
      expect(_appleLogo, findsNothing);
      expect(find.byType(TpLogoLoader), findsOneWidget);
      await tester.tap(find.text(K.continueGoogle.tr()));
      await tester.pump();
      expect(auth.signIns, <AuthMethod>[AuthMethod.apple]);

      auth.finish(const AuthResult.failed(AuthFailure.canceled));
      await tester.pumpAndSettle();
      expect(_appleLogo, findsOneWidget);
    });

    testWidgets('Apple 로고와 글자는 Google 과 같은 크기', (tester) async {
      await _pump(tester, FakeAuthService());

      final apple = tester.getSize(_appleLogo);
      final google = tester.getSize(
        find.image(const AssetImage('assets/logo/google_logo.png')),
      );
      expect(apple.height, google.height);
      TextStyle? styleOf(String text) =>
          tester.widget<Text>(find.text(text)).style;
      expect(
        styleOf(K.continueApple.tr())?.fontSize,
        styleOf(K.continueGoogle.tr())?.fontSize,
      );
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

    testWidgets('Android 는 틀린 칸의 errorText 로 말한다', (tester) async {
      await _pump(tester, FakeAuthService(), chrome: TpChrome.android);
      await _toEmail(tester);

      await _fill(tester, 'nope', 'longenough');
      await _submit(tester, K.signIn);

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.first.decoration!.errorText, K.emailInvalid.tr());
      expect(fields.last.decoration!.errorText, isNull);
      expect(find.text(K.emailInvalid.tr()), findsOneWidget);

      // 고치기 시작하면 풀린다.
      await tester.enterText(find.byType(EditableText).first, 'a@b.com');
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byType(TextField).first)
            .decoration!
            .errorText,
        isNull,
      );
    });

    testWidgets('iOS 는 틀린 칸의 이름이 빨개진다', (tester) async {
      await _pump(tester, FakeAuthService());
      await _toEmail(tester);

      await _fill(tester, 'a@b.com', '12345');
      await _submit(tester, K.signIn);

      Color? color(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;
      expect(color(K.passwordLabel.tr()), isNot(color(K.emailLabel.tr())));
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

      // 보낸 뒤엔 로그인으로 돌아가는 버튼이 있다.
      await tester.tap(find.text(K.resetBackToSignIn.tr()));
      await tester.pumpAndSettle();
      expect(find.text(K.resetTitle.tr()), findsNothing);
      expect(find.text(K.emailTitle.tr()), findsOneWidget);
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

/// 로그인이 [finish] 전까지 안 돌아온다(OS 계정 시트가 떠 있는 동안).
class _HangingAuth extends FakeAuthService {
  Completer<AuthResult>? _wait;

  void finish(AuthResult result) => _wait?.complete(result);

  @override
  Future<AuthResult> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) {
    signIns.add(method);
    return (_wait = Completer<AuthResult>()).future;
  }
}
