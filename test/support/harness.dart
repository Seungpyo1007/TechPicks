import 'dart:convert';
import 'dart:io';

// Localization·Translations 는 공개 배럴에 없어 내부 경로로 가져온다.
// 테스트에서만 쓰고, 앱 코드는 .tr() 확장만 쓴다.
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';

/// 애셋을 파일에서 그대로 읽는 번들.
///
/// `tool/build_catalog.dart` 가 구운 실제 카탈로그를 테스트가 그대로 쓴다.
/// 손으로 만든 픽스처였으면 파일이 깨져도 안 걸린다.
class FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(File(key).readAsBytesSync().buffer);

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode(File(key).readAsBytesSync());
}

/// 번역을 쓰는 위젯 테스트는 매 테스트마다 이걸 먼저 부른다.
///
/// EasyLocalization 위젯을 테스트 트리에 올리지 않는다. 그 위젯은 첫 프레임에
/// 번역을 비동기로 읽고 그동안 빈 화면을 그리는데, 한 파일에서 두 번째
/// 테스트부터 그 로딩이 끝나지 않아 화면이 통째로 비었다.
///
/// `.tr()` 은 전역 Localization 인스턴스를 보므로 여기서 직접 올려두면
/// 위젯 없이도 동작한다.
Future<void> initLocalization({
  Locale locale = const Locale('en', 'US'),
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final name = '${locale.languageCode}-${locale.countryCode}';
  final raw = jsonDecode(
    File('assets/translations/$name.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  Localization.load(locale, translations: Translations(raw));
}

/// 화면 하나를 앱과 같은 테마·프로바이더 위에 올린다.
Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  TpChrome chrome = TpChrome.ios,
  List<Override> overrides = const <Override>[],
  Size size = const Size(1200, 3000),
}) async {
  await _pump(tester, screen, chrome: chrome, overrides: overrides, size: size);
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

/// 끝나지 않는 애니메이션이 있는 화면용. settle 대신 한 프레임만 돌린다.
Future<void> pumpScreenNoSettle(
  WidgetTester tester,
  Widget screen, {
  TpChrome chrome = TpChrome.ios,
  List<Override> overrides = const <Override>[],
  Size size = const Size(1200, 3000),
}) async {
  await _pump(tester, screen, chrome: chrome, overrides: overrides, size: size);
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required TpChrome chrome,
  required List<Override> overrides,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(bundle: FileBundle()),
        ),
        ...overrides,
      ],
      child: MaterialApp(theme: AppTheme.of(chrome), home: screen),
    ),
  );
}
