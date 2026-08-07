import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 스크린 리더가 읽는 내용.
///
/// 이 화면들은 숫자가 많다. 라벨 없이 두면 "1", "79", "88" 이 따로 읽혀
/// 무엇의 값인지 알 수 없다.
void main() {
  setUp(initLocalization);

  testWidgets('랭킹 행은 순위·이름·지수를 한 문장으로 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const RankScreen());

    // 1위는 galaxy-s25-ultra, 지수 79.
    expect(
      semanticsLabels(tester),
      contains(K.a11yRankRow.tr(args: <String>['1', 'Galaxy S25 Ultra', '77'])),
    );
    handle.dispose();
  });

  testWidgets('점수 축은 무엇의 몇 점인지 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const DetailScreen(slug: 'galaxy-s25'),
      size: const Size(1200, 3200),
    );

    final labels = semanticsLabels(tester);
    expect(labels, contains(K.a11yAxis.tr(args: <String>['Performance', '89'])));
    // 지수 숫자도 단독 숫자가 아니라 문장으로.
    expect(labels, contains(K.a11yIndex.tr(args: <String>['61'])));
    handle.dispose();
  });

  testWidgets('점수가 없는 축은 없다고 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const DetailScreen(slug: 'galaxy-s25'),
      size: const Size(1200, 3200),
    );

    // 카탈로그 기기는 다섯 축이 다 있다. 라벨 형식만 확인한다.
    expect(
      K.a11yAxisMissing.tr(args: <String>['Camera']),
      'Camera not scored',
    );
    handle.dispose();
  });

  testWidgets('비교 셀은 어느 기기 값인지, 이겼는지 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const CompareScreen(),
      size: const Size(1200, 3200),
    );

    // 승패는 색으로만 표시된다. 색을 못 보면 알 수 없다.
    // 기본 두 기기는 galaxy-s25-ultra(1299) 와 iphone-16-pro-max(1199).
    final labels = semanticsLabels(tester);
    expect(
      labels,
      contains(K.a11yWinner.tr(args: <String>['iPhone 16 Pro Max', r'$1,199'])),
    );
    expect(
      labels,
      contains(
        K.a11yCompareCell.tr(args: <String>['Galaxy S25 Ultra', r'$1,299']),
      ),
    );
    handle.dispose();
  });

  testWidgets('한국어에서도 문장으로 읽는다', (tester) async {
    await initLocalization(locale: const Locale('ko', 'KR'));
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const RankScreen());

    expect(
      semanticsLabels(tester),
      contains(K.a11yRankRow.tr(args: <String>['1', 'Galaxy S25 Ultra', '77'])),
    );
    handle.dispose();
  });
}
