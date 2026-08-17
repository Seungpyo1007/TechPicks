import 'package:techpicks/shared/widgets/tp_press.dart';
import 'package:techpicks/shared/widgets/tp_tap_target.dart';
import 'package:techpicks/shared/widgets/tp_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/home/home_screen.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 버튼은 글자 밖에서도 눌려야 한다.
///
/// `GestureDetector` 의 기본값은 `deferToChild` 고, `decoration:` 으로 칠한
/// 상자는 히트 테스트에 안 잡힌다. 그래서 알약 버튼이 **글리프 위에서만**
/// 눌렸다 — 342×52 짜리 버튼에서 반응하는 곳이 110×21 이었다.
///
/// 시뮬레이터에서 온보딩 "다음"과 랭킹의 찾기 버튼이 안 눌린 적이 있는데,
/// 그때는 좌표를 잘못 짚은 줄 알았다. 가운데만 누르는 테스트로는 안 잡힌다.

/// 라벨을 감싼 알약의 사각형.
Rect _pill(WidgetTester tester, String label) => tester.getRect(
  find
      .ancestor(of: find.text(label), matching: find.byType(GestureDetector))
      .first,
);

/// 알약의 네 모서리에서 6pt 안쪽. 글자에서 가장 먼 자리다.
List<Offset> _corners(Rect r) => <Offset>[
  r.topLeft + const Offset(6, 6),
  r.topRight + const Offset(-6, 6),
  r.bottomLeft + const Offset(6, -6),
  r.bottomRight + const Offset(-6, -6),
];

Future<void> _tapCorners(WidgetTester tester, String label) async {
  for (final point in _corners(_pill(tester, label))) {
    await tester.tapAt(point);
    await tester.pump();
  }
}

void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('온보딩 다음', (tester) async {
    await pumpScreen(tester, const OnboardingScreen());

    // 세 장이라 모서리 두 번이면 마지막 장이다.
    for (final point in _corners(_pill(tester, K.next.tr())).take(2)) {
      await tester.tapAt(point);
      await tester.pumpAndSettle();
    }

    expect(find.text(K.start.tr()), findsOneWidget);
  });

  testWidgets('홈 결론 카드 버튼', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25'],
    });
    var taps = 0;
    await pumpScreen(tester, HomeScreen(onCompareAll: () => taps++));

    await _tapCorners(tester, K.compareAll.tr());

    expect(taps, 4);
  });

  testWidgets('상세 행동 버튼', (tester) async {
    var taps = 0;
    await pumpScreen(
      tester,
      DetailScreen(slug: 'galaxy-s25', onCompare: (_) => taps++),
    );
    await tester.pumpAndSettle();

    await _tapCorners(tester, K.compareButton.tr());

    expect(taps, 4);
  });

  testWidgets('로그인 버튼', (tester) async {
    var taps = 0;
    await pumpScreen(tester, LoginScreen(onEmail: () => taps++));

    await _tapCorners(tester, K.loginEmail.tr());

    expect(taps, 4);
  });

  testWidgets('랭킹 인라인 찾기 버튼', (tester) async {
    var taps = 0;
    await pumpScreen(tester, RankScreen(onScan: () => taps++));

    // 50행 아래라 화면 밖이다. 끌어와서 누른다.
    await tester.scrollUntilVisible(
      find.text(K.scanCta.tr()),
      400,
      scrollable: find
          .descendant(
            of: find.byType(RankScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    await _tapCorners(tester, K.scanCta.tr());

    expect(taps, 4);
  });

  testWidgets('랭킹 축 칩', (tester) async {
    final container = await pumpScreen(tester, RankScreen(onScan: () {}));

    // 칩은 한 번만 누른다. 두 번 누르면 축이 다시 바뀐다.
    final battery = _pill(tester, K.rankAxis(RankAxis.battery).tr());
    await tester.tapAt(battery.topLeft + const Offset(6, 6));
    await tester.pump();

    expect(container.read(rankAxisProvider), RankAxis.battery);
  });

  // 눌러도 아무 반응이 없으면 죽은 버튼처럼 보인다. 명세가 이름을 준 칩·카드
  // 말고는 규칙이 없어 서른 곳 넘게 그대로 있었다.
  testWidgets('버튼은 눌리는 동안 줄고 어두워진다', (tester) async {
    await pumpScreen(tester, const OnboardingScreen());

    final button = find.byType(TpButton).first;
    double scale() => tester
        .widgetList<Transform>(
          find.descendant(of: button, matching: find.byType(Transform)),
        )
        // getMaxScaleOnAxis 는 z(=1)까지 세서 가로가 줄어도 1 로 나온다.
        .map((t) => t.transform.storage[0])
        // 쉴 때는 Transform 자체가 없다 — 그때가 1 이다.
        .fold(1.0, (a, b) => a < b ? a : b);

    expect(scale(), moreOrLessEquals(1, epsilon: 0.001));

    final press = await tester.startGesture(tester.getCenter(button));
    // 한 프레임은 티커를 시작만 하고, 그 다음 프레임부터 값이 움직인다.
    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump(const Duration(milliseconds: 45));
    expect(scale(), lessThan(1));
    // 크기만 바뀌면 손가락 밑에서 뭐가 일어났는지 안 보인다.
    expect(
      find.descendant(of: button, matching: find.byType(ColorFiltered)),
      findsWidgets,
    );

    await press.up();
    await tester.pumpAndSettle();
    expect(scale(), moreOrLessEquals(1, epsilon: 0.001));
  });

  // 같은 0.97 이 칩에서는 2pt, 전체 폭 버튼에서는 10pt 가 된다. 큰 버튼만
  // 과장돼 보이던 게 그래서다.
  testWidgets('넓은 버튼이 더 조금 줄어든다', (tester) async {
    // 전체 폭 버튼은 양쪽 3pt 씩만 들어간다. 예전 0.97 이면 5pt 씩이었다.
    expect(
      342 * (1 - TpPressFeel.scaleFor(342)),
      moreOrLessEquals(6, epsilon: 0.1),
    );
    // 좁은 칩은 6pt 가 과해서 한도에 걸린다.
    expect(80 * (1 - TpPressFeel.scaleFor(80)), lessThan(6));
    expect(TpPressFeel.scaleFor(342), greaterThan(TpPressFeel.scaleFor(80)));
  });

  testWidgets('링크도 같은 박자로 반응한다', (tester) async {
    await pumpScreen(tester, const OnboardingScreen());

    final skip = find.byType(TpTapTarget).first;
    final press = await tester.startGesture(tester.getCenter(skip));
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.widget<AnimatedScale>(_scaleOf(skip)).scale, lessThan(1));

    await press.up();
    await tester.pumpAndSettle();
  });
}

/// 그 컨트롤이 들고 있는 스케일 애니메이션.
Finder _scaleOf(Finder control) =>
    find.descendant(of: control, matching: find.byType(AnimatedScale)).first;
