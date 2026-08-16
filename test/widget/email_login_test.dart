import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/feature/login/email_login_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// Firebase 를 띄우지 않는 가짜.
class _StubAuth implements AuthService {
  @override
  Stream<TpUser?> changes() => const Stream<TpUser?>.empty();
  _StubAuth({this.signInOk = true, this.signUpOk = true});

  final bool signInOk;
  final bool signUpOk;
  final List<String> calls = <String>[];
  TpUser? _current;

  @override
  TpUser? get current => _current;

  @override
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async {
    calls.add('signIn:$email');
    return signInOk ? (_current = TpUser(uid: 'u', email: email)) : null;
  }

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async {
    calls.add('signUp:$email');
    return signUpOk ? (_current = TpUser(uid: 'u', email: email)) : null;
  }

  @override
  Future<bool> sendPasswordReset(String email) async => false;

  @override
  Future<TpUser?> updateName(String name) async => null;

  @override
  Future<void> signOut() async => _current = null;
}

Future<void> _pump(
  WidgetTester tester,
  AuthService auth, {
  VoidCallback? onSignedIn,
}) => pumpScreen(
  tester,
  EmailLoginScreen(onSignedIn: onSignedIn),
  size: const Size(1200, 2000),
  overrides: <Override>[authServiceProvider.overrideWithValue(auth)],
);

Future<void> _fill(WidgetTester tester, String email, String password) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.first, email);
  await tester.enterText(fields.last, password);
  await tester.pumpAndSettle();
}

void main() {
  setUp(initLocalization);

  group('입력 검사', () {
    test('이메일 형태만 통과시킨다', () {
      expect(EmailLoginScreen.looksLikeEmail('a@b.com'), isTrue);
      expect(EmailLoginScreen.looksLikeEmail('  a@b.co.kr '), isTrue);

      expect(EmailLoginScreen.looksLikeEmail('a@b'), isFalse);
      expect(EmailLoginScreen.looksLikeEmail('@b.com'), isFalse);
      expect(EmailLoginScreen.looksLikeEmail('a@'), isFalse);
      expect(EmailLoginScreen.looksLikeEmail('a b@c.com'), isFalse);
      expect(EmailLoginScreen.looksLikeEmail('a@.com'), isFalse);
      expect(EmailLoginScreen.looksLikeEmail(''), isFalse);
    });
  });

  // 빈 칸에 "형식이 아닙니다"는 고장 난 것처럼 읽힌다.
  testWidgets('빈 칸은 채우라고 말한다', (tester) async {
    final auth = _StubAuth();
    await _pump(tester, auth);

    await tester.tap(find.text(K.signIn.tr()));
    await tester.pumpAndSettle();

    expect(find.text(K.emailNeeded.tr()), findsOneWidget);
    expect(find.text(K.emailInvalid.tr()), findsNothing);
    expect(auth.calls, isEmpty);
  });

  testWidgets('잘못된 이메일은 서버까지 가지 않는다', (tester) async {
    final auth = _StubAuth();
    await _pump(tester, auth);

    await _fill(tester, 'nope', 'longenough');
    await tester.tap(find.text(K.signIn.tr()));
    await tester.pumpAndSettle();

    expect(find.text(K.emailInvalid.tr()), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('짧은 비밀번호도 막는다', (tester) async {
    final auth = _StubAuth();
    await _pump(tester, auth);

    await _fill(tester, 'a@b.com', '12345');
    await tester.tap(find.text(K.signIn.tr()));
    await tester.pumpAndSettle();

    expect(find.text(K.passwordShort.tr()), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('제대로 넣으면 로그인한다', (tester) async {
    final auth = _StubAuth();
    var signedIn = false;
    await _pump(tester, auth, onSignedIn: () => signedIn = true);

    await _fill(tester, 'a@b.com', 'longenough');
    await tester.tap(find.text(K.signIn.tr()));
    await tester.pumpAndSettle();

    expect(auth.calls, <String>['signIn:a@b.com']);
    expect(signedIn, isTrue);
  });

  testWidgets('실패하면 안내가 뜬다', (tester) async {
    await _pump(tester, _StubAuth(signInOk: false));

    await _fill(tester, 'a@b.com', 'longenough');
    await tester.tap(find.text(K.signIn.tr()));
    await tester.pumpAndSettle();

    expect(find.text(K.authFailed.tr()), findsOneWidget);
  });

  testWidgets('가입 모드로 바꾸면 가입을 부른다', (tester) async {
    final auth = _StubAuth();
    await _pump(tester, auth);

    // 하단 링크로 모드를 바꾼다.
    await tester.tap(find.text(K.signup.tr()));
    await tester.pumpAndSettle();
    expect(find.text(K.signupTitle.tr()), findsOneWidget);

    await _fill(tester, 'new@b.com', 'longenough');
    await tester.tap(find.text(K.signup.tr()).last);
    await tester.pumpAndSettle();

    expect(auth.calls, <String>['signUp:new@b.com']);
  });

  testWidgets('가입 실패도 안내가 뜬다', (tester) async {
    await _pump(tester, _StubAuth(signUpOk: false));

    await tester.tap(find.text(K.signup.tr()));
    await tester.pumpAndSettle();
    await _fill(tester, 'new@b.com', 'longenough');
    await tester.tap(find.text(K.signup.tr()).last);
    await tester.pumpAndSettle();

    expect(find.text(K.signupFailed.tr()), findsOneWidget);
  });

  testWidgets('한국어로도 그려진다', (tester) async {
    await initLocalization(locale: const Locale('ko', 'KR'));
    await _pump(tester, _StubAuth());

    expect(find.text('이메일'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인'), findsWidgets);
  });
}
