import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:easy_localization/easy_localization.dart';

import '../support/harness.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/app/theme/tp_tokens.dart';
import 'package:techpicks/feature/rank/category_chips.dart';
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

  testWidgets('잘린 것을 말해준다', (tester) async {
    // 상한 없이 조용히 끊으면 가격순에서 제일 싼 기기가 왜 없는지 모른다.
    // 안내는 목록 아래라 화면이 그만큼 길어야 그려진다.
    await pumpScreen(tester, const RankScreen(), size: const Size(1200, 4400));

    final rest = readCatalog().smartphones.length - RankScreen.maxRows;
    expect(
      find.text(
        K.rankCapped.tr(args: <String>['${RankScreen.maxRows}', '$rest']),
      ),
      findsOneWidget,
    );
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

  testWidgets('노트북 칩은 꺼져 있고 그렇게 보인다', (tester) async {
    // 데이터가 없어 못 누른다. 켜진 것과 똑같이 생기면 눌러보고 만다.
    await _pump(tester);

    final chips = tester.widgetList<TpChip>(
      find.descendant(
        of: find.byType(CategoryChips),
        matching: find.byType(TpChip),
      ),
    );
    final laptops = chips.firstWhere((c) => c.label == 'Laptops');
    expect(laptops.onTap, isNull);

    // 못 누르는 칩은 그렇게 보여야 한다. 켜진 칩과 같은 색이면 눌러 보고서야
    // 안 된다는 걸 안다.
    final off = tester.widget<Text>(
      find.descendant(of: find.byWidget(laptops), matching: find.byType(Text)),
    );
    final on = tester.widget<Text>(
      find.descendant(
        of: find.byWidget(chips.firstWhere((c) => c.label == 'Processors')),
        matching: find.byType(Text),
      ),
    );
    expect(off.style!.color, isNot(on.style!.color));

    final label = tester.widget<Text>(
      find.descendant(
        of: find.widgetWithText(TpChip, 'Laptops'),
        matching: find.byType(Text),
      ),
    );
    expect(label.style?.color, isNot(TpTokens.inkLight));
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

  // 랭킹은 50행에서 잘린다. 그 아래 기기를 찾을 방법이 스크롤밖에 없었는데,
  // 카탈로그가 200종이라 사실상 없는 거나 마찬가지였다.
  group('찾기', () {
    testWidgets('이름으로 걸러진다', (tester) async {
      final container = await pumpScreen(
        tester,
        const RankScreen(),
        size: const Size(1200, 4400),
      );

      await tester.enterText(find.byType(TextField), 'pixel');
      await tester.pumpAndSettle();

      final visible = container.read(rankVisibleProvider);
      expect(visible, isNotEmpty);
      expect(
        visible.every(
          (r) =>
              r.device.name.toLowerCase().contains('pixel') ||
              (r.device.brand?.name.toLowerCase().contains('pixel') ?? false),
        ),
        isTrue,
      );
      // 순위 번호는 전체 순위 그대로다. 다시 매기면 "구글 중 1위"가
      // "전체 1위"처럼 보인다.
      expect(visible.first.position, greaterThan(0));
    });

    testWidgets('맞는 게 없으면 그렇게 말한다', (tester) async {
      await pumpScreen(tester, const RankScreen(), size: const Size(1200, 4400));

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();

      expect(find.text(K.noMatches.tr()), findsOneWidget);
    });

    testWidgets('브랜드 칩으로 거르고 다시 눌러 푼다', (tester) async {
      final container = await pumpScreen(
        tester,
        const RankScreen(),
        size: const Size(1200, 4400),
      );

      final brand = container.read(rankBrandsProvider).first;
      final all = container.read(rankVisibleProvider).length;

      await tester.tap(find.widgetWithText(TpChip, brand));
      await tester.pumpAndSettle();

      final filtered = container.read(rankVisibleProvider);
      expect(filtered.length, lessThan(all));
      expect(filtered.every((r) => r.device.brand?.name == brand), isTrue);

      await tester.tap(find.widgetWithText(TpChip, brand));
      await tester.pumpAndSettle();
      expect(container.read(rankVisibleProvider), hasLength(all));
    });
  });
}
