import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/domain/model/processor.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/feature/cpu/processor_screen.dart';
import 'package:techpicks/feature/rank/rank_category.dart';
import 'package:techpicks/feature/rank/browse_screen.dart';
import 'package:techpicks/feature/rank/rank_tab.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

void main() {
  setUp(initLocalization);

  testWidgets('필터로 모바일과 노트북을 오간다', (tester) async {
    final container = await pumpScreen(
      tester,
      const ProcessorScreen(),
      size: const Size(700, 3000),
    );
    final mobile = container.read(
      processorsInProvider(ProcessorSegment.mobile),
    );
    final laptop = container.read(
      processorsInProvider(ProcessorSegment.laptop),
    );
    expect(find.text(mobile.first.processor.name), findsOneWidget);
    expect(find.text(laptop.first.processor.name), findsNothing);
    expect(find.text(K.cpuNote.tr()), findsOneWidget);

    container
        .read(processorSegmentProvider.notifier)
        .set(ProcessorSegment.laptop);
    await tester.pumpAndSettle();
    expect(find.text(laptop.first.processor.name), findsOneWidget);
    expect(find.text(mobile.first.processor.name), findsNothing);
  });

  testWidgets('이름순으로 줄 세운다', (tester) async {
    final container = await pumpScreen(
      tester,
      const ProcessorScreen(),
      size: const Size(700, 3000),
    );
    container.read(processorSortProvider.notifier).set(ProcessorSort.name);
    await tester.pumpAndSettle();
    final names =
        container
            .read(processorsInProvider(ProcessorSegment.mobile))
            .map((r) => r.processor.name)
            .toList()
          ..sort();
    final first = tester.getTopLeft(find.text(names.first)).dy;
    final second = tester.getTopLeft(find.text(names[1])).dy;
    expect(first, lessThan(second));
  });

  testWidgets('조립 견적 행이 맨 위에 있다', (tester) async {
    var taps = 0;
    await pumpScreen(
      tester,
      ProcessorScreen(onBuild: () => taps++),
      size: const Size(700, 3000),
    );
    await tester.tap(find.text(K.buildTitle.tr()));
    expect(taps, 1);
  });

  testWidgets('카테고리 칩이 어느 카테고리로 가려는지 알려준다', (tester) async {
    // 카테고리는 이제 주소가 쥔다. 칩은 고르기만 하고 옮기는 건 라우터다.
    RankCategory? picked;
    await pumpScreen(
      tester,
      RankTab(category: RankCategory.phones, onCategory: (c) => picked = c),
    );

    expect(find.byType(BrowseScreen), findsOneWidget);

    await tester.tap(find.text(K.cpus.tr()));
    await tester.pumpAndSettle();

    expect(picked, RankCategory.processors);
  });

  testWidgets('Laptops 칩이 눌린다', (tester) async {
    // 여태 눌러도 아무 일이 없었다. 화면이 없어서 막아뒀는데, 그 상태가
    // 고장 난 앱처럼 보였다.
    RankCategory? picked;
    await pumpScreen(
      tester,
      RankTab(category: RankCategory.phones, onCategory: (c) => picked = c),
    );

    await tester.tap(find.text(K.laptops.tr()));
    await tester.pumpAndSettle();

    expect(picked, RankCategory.laptops);
  });

  testWidgets('카테고리가 바뀌어도 같은 둘러보기 화면이다', (tester) async {
    for (final category in RankCategory.values) {
      await pumpScreen(tester, RankTab(category: category));
      final browse = tester.widget<BrowseScreen>(find.byType(BrowseScreen));
      expect(browse.category, category);
    }
  });

  testWidgets('행은 순위·이름·지수를 한 문장으로 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      const ProcessorScreen(),
      size: const Size(700, 3000),
    );

    // 1위가 무엇인지는 카탈로그가 정한다. 문장 형태만 본다.
    final top = ProcessorRanking.of(
      readCatalog().socs.map(Processor.fromSoc).toList(growable: false),
    ).first;
    expect(
      semanticsLabels(tester),
      contains(
        K.a11yProcessorRow.tr(
          args: <String>['1', top.processor.name, '${top.processor.index}'],
        ),
      ),
    );
    handle.dispose();
  });

  // 못 읽은 것과 목록이 빈 것은 다른 일이다.
  testWidgets('애셋이 없으면 못 읽었다고 알린다', (tester) async {
    await pumpScreen(
      tester,
      const ProcessorScreen(),
      catalogAsset: missingCatalogAsset,
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(K.catalogFailedTitle.tr()), findsOneWidget);
    expect(find.text(K.noDevices.tr()), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android 크롬에서도 뜬다', (tester) async {
    final container = await pumpScreen(
      tester,
      const ProcessorScreen(),
      chrome: TpChrome.android,
      size: const Size(700, 3000),
    );

    final top = container.read(processorsInProvider(ProcessorSegment.mobile));
    expect(find.text(top.first.processor.name), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('전체 보기가 지금 구간의 전체 목록으로 간다', (tester) async {
    ProcessorSegment? opened;
    final container = await pumpScreen(
      tester,
      RankTab(
        category: RankCategory.processors,
        onAllProcessors: (s) => opened = s,
      ),
      size: const Size(700, 3000),
    );
    container
        .read(processorSegmentProvider.notifier)
        .set(ProcessorSegment.laptop);
    await tester.pumpAndSettle();

    await tester.tap(find.text(K.seeAll.tr()));
    expect(opened, ProcessorSegment.laptop);
  });

  testWidgets('필터 버튼 이름이 무엇이 걸렸는지 말한다', (tester) async {
    final handle = tester.ensureSemantics();
    final container = await pumpScreen(
      tester,
      const ProcessorScreen(),
      size: const Size(700, 3000),
    );
    expect(semanticsLabels(tester), contains(K.filter.tr()));

    container
        .read(processorSegmentProvider.notifier)
        .set(ProcessorSegment.laptop);
    await tester.pumpAndSettle();
    expect(
      semanticsLabels(tester),
      contains('${K.filter.tr()}, ${ProcessorSegment.laptop.key.tr()}'),
    );
    handle.dispose();
  });

  testWidgets('가격대에 노트북이 없으면 그 가격대 탓이라고 말한다', (tester) async {
    final container = await pumpScreen(
      tester,
      const RankTab(category: RankCategory.laptops),
      size: const Size(700, 3000),
    );
    // 번들 아홉 대는 모두 $1,500 이상이라 메인스트림이 빈다.
    container.read(laptopTierProvider.notifier).set(K.laptopTierMain);
    await tester.pumpAndSettle();

    expect(find.text(K.laptopTierEmpty.tr()), findsOneWidget);
    expect(find.text(K.noDevices.tr()), findsNothing);
  });

  testWidgets('노트북 다시 시도가 노트북 목록도 다시 읽는다', (tester) async {
    // 처음 한 번만 못 읽는다. 다시 시도가 노트북 쪽을 버려야 풀린다.
    var calls = 0;
    await pumpScreen(
      tester,
      const RankTab(category: RankCategory.laptops),
      size: const Size(700, 3000),
      overrides: [
        laptopsProvider.overrideWith((ref) async {
          if (calls++ == 0) throw StateError('flaky');
          return readLaptops();
        }),
      ],
    );
    expect(find.text(K.catalogFailedTitle.tr()), findsOneWidget);

    await tester.tap(find.text(K.retry.tr()));
    await tester.pumpAndSettle();

    expect(find.text(K.catalogFailedTitle.tr()), findsNothing);
    expect(find.text(readLaptops().byPrice.first.name), findsOneWidget);
  });

  testWidgets('Android 정렬 칩이 고른 칩까지 굴러간다', (tester) async {
    final container = await pumpScreen(
      tester,
      const RankTab(category: RankCategory.phones),
      chrome: TpChrome.android,
      size: const Size(360, 3000),
    );
    final price = find.widgetWithText(
      FilterChip,
      K.rankAxis(RankAxis.price).tr(),
    );
    expect(tester.getRect(price).right, greaterThan(360));

    container.read(rankAxisProvider.notifier).set(RankAxis.price);
    await tester.pumpAndSettle();

    expect(tester.getRect(price).right, lessThanOrEqualTo(360));
  });
}
