import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/domain/model/build_estimate.dart';
import 'package:techpicks/data/repository/parts_repository.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/domain/model/tp_money.dart';
import 'package:techpicks/feature/build/build_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:techpicks/shared/widgets/tp_chip.dart';
import 'package:techpicks/shared/widgets/tp_reveal.dart';

import '../support/harness.dart';

void main() {
  setUp(initLocalization);

  testWidgets('예산 안의 조합 셋을 그린다', (tester) async {
    final container = await pumpScreen(
      tester,
      const BuildScreen(),
      size: const Size(402, 3200),
    );

    final picks = container.read(buildPicksProvider);
    expect(picks, hasLength(3));

    // 화면이 도메인이 고른 것과 같은 것을 그린다.
    for (final combo in picks) {
      expect(find.text(combo.cpu.name), findsOneWidget);
      expect(find.text(combo.gpu.name), findsOneWidget);
    }
  });

  testWidgets('용도를 바꾸면 추천이 바뀐다', (tester) async {
    final container = await pumpScreen(
      tester,
      const BuildScreen(),
      size: const Size(402, 3200),
    );

    final before = container.read(buildPicksProvider).first;

    // 용도는 풀다운 메뉴다.
    await tester.tap(find.text(K.buildUse.tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(BuildUseCase.office.key.tr()).last);
    await tester.pumpAndSettle();

    expect(container.read(buildQueryProvider).useCase, BuildUseCase.office);
    final after = container.read(buildPicksProvider).first;
    expect(
      after.cpu.slug == before.cpu.slug && after.gpu.slug == before.gpu.slug,
      isFalse,
      reason: '게이밍과 사무는 다른 1등을 고른다',
    );
  });

  testWidgets('예산 프리셋을 누르면 그 값으로 간다', (tester) async {
    final container = await pumpScreen(
      tester,
      const BuildScreen(),
      size: const Size(402, 3200),
    );

    await tester.tap(find.widgetWithText(TpChip, DeviceSpecs.formatPrice(600)));
    await tester.pumpAndSettle();

    expect(container.read(buildQueryProvider).budgetUsd, 600);
    for (final combo in container.read(buildPicksProvider)) {
      expect(combo.priceUsd, lessThanOrEqualTo(600));
    }
  });

  testWidgets('살 수 있는 게 없으면 오류가 아니라 그렇게 말한다', (tester) async {
    // 예산이 낮은 것은 고장이 아니다. "문제가 생겼습니다" 로 쓰면 거짓말이다.
    final container = await pumpScreen(
      tester,
      const BuildScreen(),
      size: const Size(402, 3200),
    );

    container.read(buildQueryProvider.notifier).budget(BuildEstimate.minBudget);
    await tester.pumpAndSettle();

    // 얼마부터 되는지도 같이 말한다.
    final parts = readParts();
    final cheapest = BuildEstimate.cheapestUsd(parts.cpus, parts.gpus)!;
    expect(cheapest, greaterThan(BuildEstimate.minBudget));
    expect(
      find.text(
        '${K.buildEmpty.tr()} '
        '${K.buildEmptyFrom.tr(args: <String>[DeviceSpecs.formatPrice(cheapest)])}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('부품을 읽는 동안 "맞는 조합 없음"을 띄우지 않는다', (tester) async {
    final never = Completer<DesktopParts>();
    await pumpScreenNoSettle(
      tester,
      const BuildScreen(),
      size: const Size(402, 3200),
      overrides: [partsProvider.overrideWith((ref) => never.future)],
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining(K.buildEmpty.tr()), findsNothing);
    expect(find.byType(TpLoadingMark), findsOneWidget);
  });

  testWidgets('다시 시도가 부품 파일도 다시 읽는다', (tester) async {
    var calls = 0;
    await pumpScreen(
      tester,
      const BuildScreen(),
      size: const Size(402, 3200),
      overrides: [
        partsProvider.overrideWith((ref) async {
          if (calls++ == 0) throw StateError('flaky');
          return readParts();
        }),
      ],
    );
    expect(find.text(K.catalogFailedTitle.tr()), findsOneWidget);

    await tester.tap(find.text(K.retry.tr()));
    await tester.pumpAndSettle();

    expect(find.text(K.catalogFailedTitle.tr()), findsNothing);
    expect(find.byType(TpChip), findsWidgets);
    expect(calls, 2);
  });

  testWidgets('가격이 통화 설정을 따른다', (tester) async {
    final money = TpMoney.krw(FxRate.fallback);
    final container = await pumpScreen(
      tester,
      const BuildScreen(),
      size: const Size(402, 3200),
      overrides: [moneyProvider.overrideWithValue(money)],
    );

    final budget = container.read(buildQueryProvider).budgetUsd;
    expect(find.text(money.format(budget)), findsWidgets);
    expect(find.widgetWithText(TpChip, money.format(600)), findsOneWidget);
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('iOS 프리셋 칩이 흰 셀 위에서도 모양이 보인다', (tester) async {
    await pumpScreen(tester, const BuildScreen(), size: const Size(402, 3200));

    final chip = tester.widget<TpChip>(
      find.widgetWithText(TpChip, DeviceSpecs.formatPrice(600)),
    );
    expect(chip.color, isNotNull);
  });

  testWidgets('예산이 허용 범위를 벗어나면 접는다', (tester) async {
    final container = await pumpScreen(tester, const BuildScreen());

    container.read(buildQueryProvider.notifier).budget(999999);
    expect(
      container.read(buildQueryProvider).budgetUsd,
      BuildEstimate.maxBudget,
    );
  });

  testWidgets('없는 부품을 지어내지 않는다고 적는다', (tester) async {
    // 예산이 두 부품 값의 합일 뿐 완제품 가격이 아니라는 것. 안 적으면
    // "$1,500 짜리 PC" 로 읽힌다.
    await pumpScreen(tester, const BuildScreen(), size: const Size(402, 3200));

    expect(find.text(K.buildScope.tr()), findsOneWidget);
    expect(
      find.text(
        K.buildPsuNote.tr(args: <String>['${BuildEstimate.platformWatts}']),
      ),
      findsOneWidget,
    );
  });

  testWidgets('요구사양 표가 1등 조합에서 도출된다', (tester) async {
    final container = await pumpScreen(
      tester,
      const BuildScreen(),
      size: const Size(402, 3200),
    );

    final top = container.read(buildPicksProvider).first;

    expect(find.text(K.buildReq.tr().toUpperCase()), findsOneWidget);
    expect(find.text(RequirementKind.socket.key.tr()), findsOneWidget);
    if (top.cpu.socket case final socket?) {
      expect(find.text(socket), findsOneWidget);
    }
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await pumpScreen(
        tester,
        const BuildScreen(),
        chrome: chrome,
        size: const Size(402, 3200),
      );
      expect(find.text(K.buildTitle.tr()), findsWidgets, reason: chrome.name);
    }
  });
}
