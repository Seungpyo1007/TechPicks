import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/tab_host.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/feature/login/login_sheet.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/fake_auth.dart';
import '../support/harness.dart';

Future<void> _openYou(WidgetTester tester, FakeAuthService auth) async {
  await pumpApp(
    tester,
    size: const Size(700, 3000),
    overrides: <Override>[
      authServiceProvider.overrideWithValue(auth),
      askServiceProvider.overrideWithValue(const LocalAskService()),
    ],
  );
  // 오늘 오른쪽 위 프로필 버튼으로 내 정보를 연다.
  await tester.tap(find.bySemanticsLabel(K.you.tr()).first);
  await tester.pumpAndSettle();
}

/// 로그아웃은 눌린 대로 나가야 한다. 로그인은 선택이라, 나간 뒤에도 앱은 그대로다.
void main() {
  setUp(initLocalization);

  setUp(
    () => SharedPreferences.setMockInitialValues(<String, Object>{
      'is_tutorial_completed': true,
    }),
  );

  Future<void> logout(WidgetTester tester) async {
    await tester.tap(find.text(K.logout.tr()).last);
    await tester.pumpAndSettle();
    // 확인 시트의 빨간 "로그아웃".
    await tester.tap(find.text(K.logout.tr()).last);
    await tester.pumpAndSettle();
  }

  testWidgets('로그아웃하면 계정이 빠지고 그 자리에 로그인이 뜬다', (tester) async {
    final auth = FakeAuthService(user: FakeAuthService.defaultUser);
    await _openYou(tester, auth);

    await logout(tester);

    expect(auth.signOuts, 1);
    expect(find.text(K.signIn.tr()), findsWidgets);
    // 로그인 화면으로 쫓아내지 않는다.
    expect(find.byType(LoginSheet), findsNothing);
    // 내 정보가 탭 위에 밀려 있어 탭은 무대 밖이다.
    expect(find.byType(TabHost, skipOffstage: false), findsOneWidget);
  });

  testWidgets('signOut 이 안 돌아와도 화면은 나간다', (tester) async {
    final auth = FakeAuthService(
      user: FakeAuthService.defaultUser,
      hangSignOut: true,
    );
    await _openYou(tester, auth);

    await logout(tester);

    expect(find.text(K.signIn.tr()), findsWidgets);
  });

  testWidgets('로그인 줄은 로그인 시트를 연다', (tester) async {
    final auth = FakeAuthService();
    await _openYou(tester, auth);

    await tester.tap(find.text(K.signIn.tr()).last);
    await tester.pumpAndSettle();

    expect(find.byType(LoginSheet), findsOneWidget);
    expect(auth.signOuts, 0);
  });
}
