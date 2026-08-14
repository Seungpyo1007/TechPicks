import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:easy_localization/easy_localization.dart';

import '../support/harness.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/shared/widgets/tp_chip.dart';

Future<void> _pump(WidgetTester tester, {TpChrome chrome = TpChrome.ios}) =>
    pumpScreen(tester, const RankScreen(), chrome: chrome);

void main() {
  setUp(initLocalization);

  testWidgets('카탈로그를 순위로 그린다', (tester) async {
    await _pump(tester);

    expect(find.text('Rankings'), findsOneWidget);
    // 1위 행이 있고, 화면 상한까지만 그린다. 카탈로그는 그보다 크다.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('${RankScreen.maxRows}'), findsOneWidget);
    expect(find.text('${RankScreen.maxRows + 1}'), findsNothing);
    expect(readCatalog().smartphones.length, greaterThan(RankScreen.maxRows));
  });

  testWidgets('축 칩이 다섯 개 다 나온다', (tester) async {
    await _pump(tester);
    for (final axis in RankAxis.values) {
      expect(
        find.widgetWithText(TpChip, K.rankAxis(axis).tr()),
        findsWidgets,
        reason: axis.name,
      );
    }
  });

  testWidgets('축을 바꾸면 순서가 바뀐다', (tester) async {
    await _pump(tester);

    List<String> order() => tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => s.contains('Galaxy') || s.contains('iPhone'))
        .toList();

    final byIndex = order();

    await tester.tap(find.widgetWithText(TpChip, 'Price'));
    await tester.pumpAndSettle();

    expect(order(), isNot(equals(byIndex)), reason: '가격순은 지수순과 달라야 한다');
  });

  testWidgets('가격 축은 통화로, 점수 축은 정수로 보여준다', (tester) async {
    await _pump(tester);

    await tester.tap(find.widgetWithText(TpChip, 'Price'));
    await tester.pumpAndSettle();

    // 가격 축은 통화 기호와 천 단위 구분이 붙는다. 값은 카탈로그에서 가져온다 —
    // 같은 값을 가진 기기가 여럿이라 개수는 세지 않는다.
    final cheapest = readCatalog().smartphones
        .map((d) => d.msrpUsd?.toDouble())
        .whereType<double>()
        .reduce((a, b) => a < b ? a : b);
    expect(find.text(formatAxisValue(RankAxis.price, cheapest)), findsWidgets);
  });

  testWidgets('빈 값은 대시로 그린다', (tester) async {
    expect(formatAxisValue(RankAxis.price, null), '—');
    expect(formatAxisValue(RankAxis.tpIndex, null), '—');
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, chrome: chrome);
      expect(find.text('Rankings'), findsOneWidget);
    }
  });

  group('formatAxisValue', () {
    test('천 단위 구분', () {
      expect(formatAxisValue(RankAxis.price, 599), r'$599');
      expect(formatAxisValue(RankAxis.price, 1299), r'$1,299');
      expect(formatAxisValue(RankAxis.price, 1000000), r'$1,000,000');
    });

    test('점수는 반올림한 정수', () {
      expect(formatAxisValue(RankAxis.tpIndex, 88.6), '89');
      expect(formatAxisValue(RankAxis.camera, 36.1), '36');
    });
  });
}
