import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/domain/model/processor.dart';
import 'package:techpicks/feature/cpu/processor_screen.dart';
import 'package:techpicks/feature/rank/rank_category.dart';
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

  testWidgets('카테고리 칩으로 랭킹과 프로세서를 오간다', (tester) async {
    final container = await pumpScreen(tester, const RankTab());

    expect(find.byType(RankScreen), findsOneWidget);

    await tester.tap(find.text(K.cpus.tr()));
    await tester.pumpAndSettle();

    expect(container.read(rankCategoryProvider), RankCategory.processors);
    expect(find.byType(ProcessorScreen), findsOneWidget);
    expect(find.byType(RankScreen), findsNothing);
  });

  testWidgets('Laptops 칩은 아직 눌리지 않는다', (tester) async {
    final container = await pumpScreen(tester, const RankTab());

    await tester.tap(find.text(K.laptops.tr()));
    await tester.pumpAndSettle();

    expect(container.read(rankCategoryProvider), RankCategory.phones);
  });

  testWidgets('행은 순위·이름·지수를 한 문장으로 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, const ProcessorScreen());

    expect(
      semanticsLabels(tester),
      contains(
        K.a11yProcessorRow.tr(args: <String>['1', 'Snapdragon 8 Elite', '97']),
      ),
    );
    handle.dispose();
  });

  testWidgets('애셋이 없으면 빈 목록을 알린다', (tester) async {
    await pumpScreen(
      tester,
      const ProcessorScreen(),
      catalogAsset: missingCatalogAsset,
    );

    expect(find.text(K.noDevices.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android 크롬에서도 뜬다', (tester) async {
    await pumpScreen(tester, const ProcessorScreen(), chrome: TpChrome.android);

    expect(find.text('Snapdragon 8 Elite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
