import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/feature/ask/ask_screen.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';
import 'package:techpicks/feature/viewer/viewer_screen.dart';
import 'package:techpicks/feature/you/profile_edit_screen.dart';
import 'package:techpicks/feature/you/you_screen.dart';
import 'package:techpicks/shared/widgets/tp_page.dart';

import '../support/fake_auth.dart';
import '../support/harness.dart';

/// 위 버튼 자리는 모든 화면이 같다. 로그인 X 가 기준이다.
///
/// 화면마다 몇 pt 씩 달라서, 넘나들 때 버튼이 들썩였다.
void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const size = Size(402, 874);

  Future<Rect> firstButton(WidgetTester tester, Widget screen) async {
    await pumpScreen(
      tester,
      screen,
      size: size,
      overrides: <Override>[
        authServiceProvider.overrideWithValue(FakeAuthService()),
      ],
    );
    return tester.getRect(find.byType(TpBarButton).first);
  }

  testWidgets('Apple 표준 자리: 안전 영역 바로 아래, 왼쪽 20', (tester) async {
    // iOS 26 시스템 앱(설정·미리 알림)의 뒤로 버튼: (20, 안전 영역, 44, 44).
    final login = await firstButton(tester, LoginScreen(onClose: () {}));
    expect(login.top, moreOrLessEquals(tpPhonePadding.top, epsilon: .5));
    expect(login.left, moreOrLessEquals(20, epsilon: .5));
    expect(login.height, moreOrLessEquals(44, epsilon: .5));
  });

  testWidgets('왼쪽 위 버튼은 화면마다 같은 자리', (tester) async {
    final login = await firstButton(tester, LoginScreen(onClose: () {}));

    final screens = <String, Widget>{
      '내 정보(큰 제목)': YouScreen(onBack: () {}),
      '가중치(작은 제목)': PrioritiesScreen(onBack: () {}),
      '계정': AccountScreen(name: 'A', onBack: () {}),
      '프로필 편집': ProfileEditScreen(onBack: () {}),
      '질문': AskScreen(onBack: () {}),
    };
    for (final e in screens.entries) {
      final r = await firstButton(tester, e.value);
      expect(r.top, moreOrLessEquals(login.top, epsilon: .5), reason: e.key);
      expect(r.left, moreOrLessEquals(login.left, epsilon: .5), reason: e.key);
    }
  });

  testWidgets('오른쪽 위 버튼도 같은 높이', (tester) async {
    final login = await firstButton(tester, LoginScreen(onClose: () {}));
    final skip = await firstButton(tester, const OnboardingScreen());

    expect(skip.center.dy, moreOrLessEquals(login.center.dy, epsilon: .5));
    expect(skip.right, moreOrLessEquals(size.width - 20, epsilon: .5));
  });

  testWidgets('3D 뷰어 X 도 같은 자리', (tester) async {
    final login = await firstButton(tester, LoginScreen(onClose: () {}));
    await pumpScreenNoSettle(
      tester,
      ViewerScreen(deviceName: 'X', onBack: () {}),
      size: size,
      overrides: <Override>[
        authServiceProvider.overrideWithValue(FakeAuthService()),
      ],
    );
    final close = tester.getRect(find.bySemanticsLabel('Close').first);
    expect(close.top, moreOrLessEquals(login.top, epsilon: .5));
    expect(close.left, moreOrLessEquals(login.left, epsilon: .5));
  });
}
