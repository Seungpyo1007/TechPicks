import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/compare/picker_screen.dart';

ProviderContainer? _container;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  TpChrome chrome = TpChrome.ios,
}) async {
  _container = await pumpScreen(
    tester,
    screen,
    chrome: chrome,
    size: const Size(1200, 3200),
  );
}

void main() {
  setUp(initLocalization);

  testWidgets('지수 1·2위로 시작한다', (tester) async {
    await _pump(tester, const CompareScreen());

    // 빈 화면으로 시작하지 않는다.
    expect(find.text('Choose two devices to compare.'), findsNothing);
    // 비교는 지수 1·2위로 시작한다.
    final ranked = readRanking();
    expect(find.text(ranked[0].device.name), findsOneWidget);
    expect(find.text(ranked[1].device.name), findsOneWidget);
  });

  testWidgets('열 줄을 모두 보여준다', (tester) async {
    await _pump(tester, const CompareScreen());
    for (final label in <String>[
      'TP Index',
      'Price',
      'Screen',
      'Chipset',
      'Camera',
      'Battery',
      'OS',
      'Weight',
      'Thickness',
      'Released',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('열 머리를 누르면 어느 슬롯인지 알려준다', (tester) async {
    CompareSide? picked;
    await _pump(tester, CompareScreen(onPick: (s) => picked = s));

    await tester.tap(find.text(readRanking()[0].device.name));
    await tester.pumpAndSettle();
    expect(picked, CompareSide.a);

    await tester.tap(find.text(readRanking()[1].device.name));
    await tester.pumpAndSettle();
    expect(picked, CompareSide.b);
  });

  testWidgets('picker 가 슬롯을 덮어쓴다', (tester) async {
    await _pump(tester, const PickerScreen());
    final container = _container!;

    container.read(pickSlotProvider.notifier).set(CompareSide.b);
    await tester.pumpAndSettle();

    await tester.tap(find.text('OnePlus 13'));
    await tester.pumpAndSettle();

    expect(container.read(compareProvider).b, 'oneplus-13');
    // A 슬롯은 그대로여야 한다.
    expect(container.read(compareProvider).a, readRanking()[0].device.slug);
  });

  testWidgets('picker 는 지수와 가격을 같이 보여준다', (tester) async {
    await _pump(tester, const PickerScreen());
    expect(find.text('Choose a device'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    // 목록 첫 기기의 가격이 통화 형태로 붙는다.
    expect(
      find.text(DeviceSpecs.formatPrice(readRanking().first.device.msrpUsd)),
      findsWidgets,
    );
  });

  // 같은 기기를 두 열에 놓으면 모든 줄이 같아 비교가 아니게 된다.
  testWidgets('반대쪽에 있던 기기를 고르면 자리를 맞바꾼다', (tester) async {
    final container = await pumpScreen(tester, const CompareScreen());
    final ranked = readRanking();
    final a = ranked[0].device.slug;
    final b = ranked[1].device.slug;

    container.read(compareProvider.notifier).pick(CompareSide.a, b);

    expect(container.read(compareProvider).a, b);
    expect(container.read(compareProvider).b, a);
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, const CompareScreen(), chrome: chrome);
      expect(find.text('Compare'), findsWidgets);
    }
  });
}
