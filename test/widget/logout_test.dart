import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/app.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

class _StubAuth implements AuthService {
  TpUser? _current = const TpUser(uid: 'u1', isAnonymous: true);
  int signOuts = 0;

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
  Future<bool> sendPasswordReset(String email) async => false;

  @override
  Future<TpUser?> updateName(String name) async => null;

  @override
  Future<void> signOut() async {
    signOuts++;
    _current = null;
  }
}

/// signOut 이 영영 안 돌아오는 경우. 설정이 온전하지 않은 Firebase 가 그렇다.
class _HangingAuth implements AuthService {
  @override
  TpUser? get current => const TpUser(uid: 'u1', isAnonymous: true);

  @override
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async => current;

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
  Future<void> signOut() => Completer<void>().future;
}

/// 로그아웃은 눌린 대로 나가야 한다.
///
/// 실기기 대신 시뮬레이터에서 Firebase 설정이 온전하지 않을 때 signOut 이
/// 안 돌아와 화면이 그대로 남았다. 그래서 화면을 먼저 되돌린다.
void main() {
  setUp(initLocalization);

  testWidgets('You 탭에서 로그아웃을 누르면 로그인 화면으로 간다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
      'browsing_as_guest': true,
    });
    final auth = _StubAuth();

    await pumpScreen(
      tester,
      const TechPicksRoot(),
      size: const Size(1200, 3000),
      overrides: <Override>[
        authServiceProvider.overrideWithValue(auth),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );

    // 탭 바에서 You 로 간다.
    await tester.tap(find.text(K.tabYou.tr()));
    await tester.pumpAndSettle();

    // 익명 계정에는 이름도 메일도 없다. 그 줄은 "로그인"으로 적힌다.
    await tester.tap(find.text(K.signIn.tr()));
    await tester.pumpAndSettle();

    expect(auth.signOuts, 1);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('signOut 이 안 돌아와도 화면은 나간다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
      'browsing_as_guest': true,
    });

    await pumpScreen(
      tester,
      const TechPicksRoot(),
      size: const Size(1200, 3000),
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_HangingAuth()),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );

    await tester.tap(find.text(K.tabYou.tr()));
    await tester.pumpAndSettle();
    // 익명 계정에는 이름도 메일도 없다. 그 줄은 "로그인"으로 적힌다.
    await tester.tap(find.text(K.signIn.tr()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
