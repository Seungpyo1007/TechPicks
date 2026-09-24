import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/feature/rank/category_chips.dart';
import 'package:techpicks/feature/rank/rank_category.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

Future<void> _pump(WidgetTester tester, {TpChrome chrome = TpChrome.ios}) =>
    pumpScreen(
      tester,
      const RankScreen(),
      chrome: chrome,
      size: const Size(700, 3000),
    );

Finder _button(TpChrome chrome, String label) => chrome == TpChrome.ios
    ? find.bySemanticsLabel(label)
    : find.byTooltip(label);

void main() {
  setUp(initLocalization);

  testWidgets('카탈로그를 순위로 그린다', (tester) async {
    await _pump(tester);

    final first = readRanking().first;
    expect(find.text(first.device.name), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('상태 줄이 정렬 축, 브랜드, 개수를 말한다', (tester) async {
    await _pump(tester);
    expect(
      find.text(
        K.rankStatus.tr(
          args: <String>[
            K.rankAxis(RankAxis.tpIndex).tr(),
            K.allBrands.tr(),
            '${readCatalog().smartphones.length}',
          ],
        ),
      ),
      findsOneWidget,
    );
  });

  for (final chrome in TpChrome.values) {
    testWidgets('$chrome — 정렬로 축을 바꾼다', (tester) async {
      final container = await pumpScreen(
        tester,
        const RankScreen(),
        chrome: chrome,
        size: const Size(700, 3000),
      );

      // iOS 는 정렬 메뉴, Android 는 칩 줄.
      if (chrome == TpChrome.ios) {
        await tester.tap(_button(chrome, K.sort.tr()));
        await tester.pumpAndSettle();
      } else {
        expect(_button(chrome, K.sort.tr()), findsNothing);
      }
      await tester.tap(find.text(K.rankAxis(RankAxis.battery).tr()).last);
      await tester.pumpAndSettle();

      expect(container.read(rankAxisProvider), RankAxis.battery);
    });
  }

  testWidgets('브랜드 시트로 거르고 지우기로 되돌린다', (tester) async {
    final container = await pumpScreen(
      tester,
      const RankScreen(),
      size: const Size(700, 3000),
    );
    final brand = container.read(rankBrandsProvider).first;
    final all = container.read(rankVisibleProvider).length;

    await tester.tap(_button(TpChrome.ios, K.brand.tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(brand).last);
    await tester.pumpAndSettle();

    final filtered = container.read(rankVisibleProvider);
    expect(filtered.length, lessThan(all));
    expect(filtered.every((r) => r.device.brand?.name == brand), isTrue);
    // 고른 브랜드가 툴바 버튼 글자가 된다.
    expect(find.bySemanticsLabel(brand), findsWidgets);

    await tester.tap(find.text(K.clear.tr()));
    await tester.pumpAndSettle();
    expect(container.read(rankVisibleProvider), hasLength(all));
  });

  testWidgets('세그먼트가 카테고리를 알려준다', (tester) async {
    RankCategory? picked;
    await pumpScreen(
      tester,
      RankScreen(onCategory: (c) => picked = c),
      size: const Size(700, 3000),
    );
    expect(find.byType(CategoryChips), findsOneWidget);
    await tester.tap(find.text(RankCategory.laptops.key.tr()));
    await tester.pumpAndSettle();
    expect(picked, RankCategory.laptops);
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, chrome: chrome);
      expect(find.text(readRanking().first.device.name), findsOneWidget);
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
