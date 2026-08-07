import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/compare/picker_screen.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(File(key).readAsBytesSync().buffer);

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode(File(key).readAsBytesSync());
}

ProviderContainer? _container;

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  TpChrome chrome = TpChrome.ios,
}) async {
  tester.view.physicalSize = const Size(1200, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(bundle: _FileBundle()),
        ),
      ],
      child: MaterialApp(theme: AppTheme.of(chrome), home: screen),
    ),
  );
  await tester.pumpAndSettle();
  _container = ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('카탈로그 앞의 두 기기로 시작한다', (tester) async {
    await _pump(tester, const CompareScreen());

    // 빈 화면으로 시작하지 않는다.
    expect(find.text('Choose two devices to compare.'), findsNothing);
    expect(find.text('Galaxy S25 Ultra'), findsOneWidget);
    expect(find.text('iPhone 16 Pro Max'), findsOneWidget);
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
    await _pump(
      tester,
      CompareScreen(onPick: (s) => picked = s),
    );

    await tester.tap(find.text('Galaxy S25 Ultra'));
    await tester.pumpAndSettle();
    expect(picked, CompareSide.a);

    await tester.tap(find.text('iPhone 16 Pro Max'));
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
    expect(container.read(compareProvider).a, 'galaxy-s25-ultra');
  });

  testWidgets('picker 는 지수와 가격을 같이 보여준다', (tester) async {
    await _pump(tester, const PickerScreen());
    expect(find.text('Choose a device'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text(r'$599'), findsOneWidget);
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, const CompareScreen(), chrome: chrome);
      expect(find.text('Compare'), findsWidgets);
    }
  });
}
