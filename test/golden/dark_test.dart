import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/feature/home/home_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';

import '../support/harness.dart';
import 'golden_harness.dart';

/// 어두운 테마.
///
/// 명세에 다크 토큰 표가 없어 [TpTokens] 가 규칙으로 뒤집는다 — 지어낸 값이
/// 아니라는 것을 눈으로 확인할 수 있는 자리가 여기다. 밝은 쪽 스물네 장을
/// 통째로 두 배로 늘리지 않고, 유리(카드·크롬)와 톤이 다 보이는 두 화면만
/// 굽는다.
void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  goldenScenario('home_dark', '홈 — 어두운 테마', (tester, chrome) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25', 'oneplus-13'],
    });
    await pumpScreen(
      tester,
      const HomeScreen(),
      chrome: chrome,
      dark: true,
      size: frameOf(chrome),
    );
  });

  goldenScenario('rank_dark', '랭킹 — 어두운 테마', (tester, chrome) async {
    await pumpScreen(
      tester,
      const RankScreen(),
      chrome: chrome,
      dark: true,
      size: frameOf(chrome),
    );
  });
}
