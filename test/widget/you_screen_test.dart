import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/domain/model/tp_index.dart';
import 'package:techpicks/domain/model/tp_weights.dart';
import 'package:techpicks/feature/you/you_screen.dart';

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
  WidgetTester tester, {
  TpChrome chrome = TpChrome.ios,
  String? name,
  String? email,
}) async {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(bundle: _FileBundle()),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.of(chrome),
        home: YouScreen(name: name, email: email),
      ),
    ),
  );
  await tester.pumpAndSettle();
  _container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('다섯 축 슬라이더가 있다', (tester) async {
    await _pump(tester);
    expect(find.byType(Slider), findsNWidgets(5));
    for (final label in <String>[
      'Performance',
      'Camera',
      'Display',
      'Battery',
      'Value',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('슬라이더를 움직이면 가중치가 바뀐다', (tester) async {
    await _pump(tester);
    final before = _container!.read(weightsProvider);

    // 첫 슬라이더(성능)를 오른쪽 끝으로.
    await tester.drag(find.byType(Slider).first, const Offset(500, 0));
    await tester.pumpAndSettle();

    final after = _container!.read(weightsProvider);
    expect(after.performance, greaterThan(before.performance));
    // 다른 축은 그대로.
    expect(after.camera, before.camera);
  });

  testWidgets('가중치가 바뀌면 지수가 따라 바뀐다', (tester) async {
    await _pump(tester);
    final container = _container!;

    // You 화면은 카탈로그를 보지 않으므로 여기서 직접 불러온다.
    final catalog = await container.read(catalogProvider.future);

    int? indexOf(String slug) {
      final d = catalog.smartphones.firstWhere((e) => e.slug == slug);
      return TpIndex.of(d.score, container.read(weightsProvider));
    }

    // 기본 가중치에서 galaxy-s25 는 61.
    expect(indexOf('galaxy-s25'), 61);

    container.read(weightsProvider.notifier).set(
          const TpWeights(
            performance: 1,
            camera: 0,
            display: 0,
            battery: 0,
            value: 0,
          ),
        );
    await tester.pumpAndSettle();

    // 성능만 보면 그 축 점수(88.9)가 그대로 지수가 된다.
    expect(indexOf('galaxy-s25'), 89);
  });

  testWidgets('Reset 이 기본값으로 돌린다', (tester) async {
    await _pump(tester);
    final container = _container!;

    container.read(weightsProvider.notifier).setAxis(
          TpAxisKind.performance,
          0.9,
        );
    await tester.pumpAndSettle();
    expect(container.read(weightsProvider).performance, 0.9);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(container.read(weightsProvider), TpWeights.defaults);
  });

  testWidgets('저장된 가중치를 다시 읽는다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tp_weights': jsonEncode(<String, dynamic>{
        'performance': 0.5,
        'camera': 0.1,
        'display': 0.1,
        'battery': 0.2,
        'value': 0.1,
      }),
    });
    await _pump(tester);
    expect(_container!.read(weightsProvider).performance, 0.5);
  });

  testWidgets('설정 줄과 버전 푸터', (tester) async {
    await _pump(tester);
    for (final label in <String>[
      'Language',
      'Dark mode',
      'Notifications',
      'Currency',
      'Change password',
      'Log out',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(YouScreen.versionLine), findsOneWidget);
  });

  testWidgets('로그인 전에는 계정 없이 쓰는 상태로 보인다', (tester) async {
    await _pump(tester);
    expect(find.text('Browsing without an account'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('이름이 있으면 이니셜을 만든다', (tester) async {
    await _pump(tester, name: 'Seungpyo Park', email: 'a@b.com');
    expect(find.text('SP'), findsOneWidget);
    expect(find.text('Seungpyo Park'), findsOneWidget);
    expect(find.text('a@b.com'), findsOneWidget);
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, chrome: chrome);
      expect(find.text('You'), findsOneWidget);
    }
  });
}
