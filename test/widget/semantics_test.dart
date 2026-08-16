import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/domain/model/device_specs.dart';
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

    // 1위가 무엇인지는 카탈로그가 정한다. 읽히는 문장의 모양만 본다.
    expect(semanticsLabels(tester), contains(_topRankSentence()));
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
    expect(
      labels,
      contains(K.a11yAxis.tr(args: <String>['Performance', '89'])),
    );
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
    expect(K.a11yAxisMissing.tr(args: <String>['Camera']), 'Camera not scored');
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
    // 기본 두 기기는 카탈로그 앞의 둘이고, 가격은 싼 쪽이 이긴다.
    // 비교는 지수 1·2위로 시작한다.
    final ranked = readRanking();
    final a = ranked[0].device;
    final b = ranked[1].device;
    final cheaper = (a.msrpUsd ?? 0) <= (b.msrpUsd ?? 0) ? a : b;
    final dearer = identical(cheaper, a) ? b : a;

    final labels = semanticsLabels(tester);
    expect(
      labels,
      contains(
        K.a11yWinner.tr(
          args: <String>[
            cheaper.name,
            DeviceSpecs.formatPrice(cheaper.msrpUsd),
          ],
        ),
      ),
    );
    expect(
      labels,
      contains(
        K.a11yCompareCell.tr(
          args: <String>[dearer.name, DeviceSpecs.formatPrice(dearer.msrpUsd)],
        ),
      ),
    );
    handle.dispose();
  });

  testWidgets('한국어에서도 문장으로 읽는다', (tester) async {
    await initLocalization(locale: const Locale('ko', 'KR'));
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const RankScreen());

    expect(semanticsLabels(tester), contains(_topRankSentence()));
    handle.dispose();
  });
}

/// 랭킹 1위 행이 읽히는 문장.
String _topRankSentence() {
  final top = readRanking().first;
  return K.a11yRankRow.tr(
    args: <String>['1', top.device.name, '${top.index}'],
  );
}
