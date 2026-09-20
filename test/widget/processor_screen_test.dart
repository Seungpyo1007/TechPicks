import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/domain/model/processor.dart';
import 'package:techpicks/feature/cpu/processor_screen.dart';
import 'package:techpicks/feature/rank/rank_category.dart';
import 'package:techpicks/feature/rank/laptop_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/feature/rank/rank_tab.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

void main() {
  setUp(initLocalization);

  testWidgets('모바일 세그먼트가 기본이고 점수순으로 선다', (tester) async {
    await pumpScreen(tester, const ProcessorScreen());

    expect(find.text(K.cpuTitle.tr()), findsWidgets);
    expect(find.text('Snapdragon 8 Elite'), findsOneWidget);
    expect(find.text('MediaTek Dimensity 9400'), findsOneWidget);
    // 1위는 Snapdragon 8 Elite (96.7).
    expect(find.text('97'), findsOneWidget);
    expect(find.text(K.cpuNote.tr()), findsOneWidget);
  });

  testWidgets('sub 줄에 제조사와 공정이 나온다', (tester) async {
    await pumpScreen(tester, const ProcessorScreen());

    expect(find.textContaining('Qualcomm · 3nm'), findsWidgets);
  });

  testWidgets('Laptop 을 누르면 노트북 CPU 로 바뀐다', (tester) async {
    final container = await pumpScreen(tester, const ProcessorScreen());

    await tester.tap(find.text(K.cpuLaptop.tr()));
    await tester.pumpAndSettle();

    expect(container.read(processorSegmentProvider), ProcessorSegment.laptop);
    expect(find.text('Intel Core i9-14900HX'), findsOneWidget);
    expect(find.text('Snapdragon 8 Elite'), findsNothing);
  });

  testWidgets('카테고리 칩이 어느 카테고리로 가려는지 알려준다', (tester) async {
    // 카테고리는 이제 주소가 쥔다. 칩은 고르기만 하고 옮기는 건 라우터다.
    RankCategory? picked;
    await pumpScreen(
      tester,
      RankTab(category: RankCategory.phones, onCategory: (c) => picked = c),
    );

    expect(find.byType(RankScreen), findsOneWidget);

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

  testWidgets('카테고리마다 제 화면이 열린다', (tester) async {
    for (final (category, matcher) in <(RankCategory, Finder)>[
      (RankCategory.phones, find.byType(RankScreen)),
      (RankCategory.processors, find.byType(ProcessorScreen)),
      (RankCategory.laptops, find.byType(LaptopScreen)),
    ]) {
      await pumpScreen(tester, RankTab(category: category));
      expect(matcher, findsOneWidget, reason: category.name);
    }
  });

  testWidgets('행은 순위·이름·지수를 한 문장으로 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const ProcessorScreen());

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
    await pumpScreen(tester, const ProcessorScreen(), chrome: TpChrome.android);

    expect(find.text('Snapdragon 8 Elite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
