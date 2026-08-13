import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/feature/you/you_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 이름과 비밀번호는 Firebase 가 처리한다. 여기서는 무엇을 시켰는지만 본다.
class _StubAuth implements AuthService {
  _StubAuth({this.succeeds = true, TpUser? user})
    : _current = user ?? const TpUser(uid: 'u1', email: 'a@b.com', name: '홍길동');

  final bool succeeds;
  TpUser? _current;

  final List<String> resets = <String>[];
  final List<String> names = <String>[];

  @override
  TpUser? get current => _current;

  @override
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async => _current;

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<bool> sendPasswordReset(String email) async {
    resets.add(email);
    return succeeds;
  }

  @override
  Future<TpUser?> updateName(String name) async {
    names.add(name);
    if (!succeeds) return null;
    return _current = TpUser(uid: 'u1', email: 'a@b.com', name: name);
  }

  @override
  Future<void> signOut() async => _current = null;
}

Future<void> _pump(
  WidgetTester tester,
  _StubAuth auth, {
  String? name = '홍길동',
  String? email = 'a@b.com',
}) => pumpScreen(
  tester,
  YouScreen(name: name, email: email),
  size: const Size(1200, 3600),
  overrides: <Override>[authServiceProvider.overrideWithValue(auth)],
);

void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('비밀번호 재설정', () {
    testWidgets('로그인한 주소로 메일을 보낸다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth);

      await tester.tap(find.text(K.changePassword.tr()));
      await tester.pumpAndSettle();

      expect(auth.resets, <String>['a@b.com']);
      expect(find.textContaining('a@b.com'), findsWidgets);
    });

    testWidgets('못 보내면 그렇다고 말한다', (tester) async {
      final auth = _StubAuth(succeeds: false);
      await _pump(tester, auth);

      await tester.tap(find.text(K.changePassword.tr()));
      await tester.pumpAndSettle();

      expect(find.text(K.pwResetFailed.tr()), findsOneWidget);
    });

    testWidgets('메일 주소가 없으면 줄 자체가 없다', (tester) async {
      // 익명이나 소셜 로그인은 보낼 곳이 없다.
      await _pump(tester, _StubAuth(), name: null, email: null);

      expect(find.text(K.changePassword.tr()), findsNothing);
    });
  });

  group('이름 바꾸기', () {
    testWidgets('저장하면 새 이름이 올라간다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth);

      await tester.tap(find.text(K.editProfile.tr()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  김승표  ');
      await tester.tap(find.text(K.save.tr()));
      await tester.pumpAndSettle();

      expect(auth.names, <String>['김승표']);
    });

    testWidgets('취소하면 아무 일도 없다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth);

      await tester.tap(find.text(K.editProfile.tr()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '다른 이름');
      await tester.tap(find.text(K.cancel.tr()));
      await tester.pumpAndSettle();

      expect(auth.names, isEmpty);
    });

    testWidgets('빈 이름은 저장하지 않는다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth);

      await tester.tap(find.text(K.editProfile.tr()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text(K.save.tr()));
      await tester.pumpAndSettle();

      expect(auth.names, isEmpty);
    });

    testWidgets('실패하면 그렇다고 말한다', (tester) async {
      final auth = _StubAuth(succeeds: false);
      await _pump(tester, auth);

      await tester.tap(find.text(K.editProfile.tr()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '새 이름');
      await tester.tap(find.text(K.save.tr()));
      await tester.pumpAndSettle();

      expect(find.text(K.authFailed.tr()), findsOneWidget);
    });
  });
}
