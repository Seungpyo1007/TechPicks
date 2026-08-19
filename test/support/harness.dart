import 'dart:convert';
import 'dart:io';

// Localization·Translations 는 공개 배럴에 없어 내부 경로로 가져온다.
// 테스트에서만 쓰고, 앱 코드는 .tr() 확장만 쓴다.
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/domain/model/tp_weights.dart';

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
///
/// 위젯을 올려서 앱 전체를 띄우는 테스트도 시도해 봤는데, `pumpAndSettle` 이
/// 끝나지 않고 10분 타임아웃까지 간다. 그래서 앱 루트는 [TechPicksRoot] 만
/// 떼어 검사한다 (test/widget/startup_test.dart).
/// 홈이 알맹이를 그리게 하는 최소한의 저장 상태.
///
/// [initLocalization] 은 저장소를 비운다. 그러면 홈에는 큰 제목과 "관심 목록이
/// 비어 있습니다" 카드밖에 없고, 레이아웃·글자 배율·접근성 스윕이 **결론 카드도
/// 관심목록 행도 변동 행도 한 번도 안 그린 채** 지나간다. 그 뒤에 1.6배에서
/// 넘치는 Row 와 52pt 상자에 든 34pt 숫자가 조용히 숨어 있었다.
///
/// [initLocalization] **뒤에** 부른다 — 그쪽이 저장소를 비운다.
void seedHomeContent() {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'shortlist_slugs': <String>['galaxy-s25', 'oneplus-13', 'pixel-9-pro'],
    // 변동 섹션은 지난 실행의 순위가 있어야 생긴다. 실제 순위를 뒤집어
    // 저장해두면 세 줄이 잡힌다.
    'rank_snapshot_slugs': <String>[
      'oneplus-13r',
      'iphone-16-pro',
      'galaxy-s25',
      'pixel-9-pro',
      'iphone-16-pro-max',
      'pixel-9-pro-xl',
      'galaxy-z-fold-7',
      'xiaomi-15-ultra',
      'oneplus-13',
      'galaxy-s25-ultra',
    ],
  });
}

Future<void> initLocalization({
  Locale locale = const Locale('en', 'US'),
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final name = '${locale.languageCode}-${locale.countryCode}';
  final raw =
      jsonDecode(File('assets/translations/$name.json').readAsStringSync())
          as Map<String, dynamic>;

  Localization.load(locale, translations: Translations(raw));
}

/// 화면 하나를 앱과 같은 테마·프로바이더 위에 올린다.
Future<ProviderContainer> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  TpChrome chrome = TpChrome.ios,
  List<Override> overrides = const <Override>[],
  Size size = const Size(1200, 3000),
  String catalogAsset = defaultCatalogAsset,
  double textScale = 1,
  bool disableAnimations = false,
  bool dark = false,
  Locale? locale,
}) async {
  await _pump(
    tester,
    screen,
    chrome: chrome,
    dark: dark,
    overrides: overrides,
    size: size,
    catalogAsset: catalogAsset,
    textScale: textScale,
    disableAnimations: disableAnimations,
    locale: locale,
  );
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
  String catalogAsset = defaultCatalogAsset,
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await _pump(
    tester,
    screen,
    chrome: chrome,
    overrides: overrides,
    size: size,
    catalogAsset: catalogAsset,
    textScale: textScale,
    disableAnimations: disableAnimations,
  );
  await tester.pump();
}

/// 구워둔 실제 카탈로그.
const String defaultCatalogAsset = 'assets/catalog/v1.json';

/// 애셋 카탈로그를 그대로 읽는다.
///
/// 기대값을 데이터에서 끌어오려고 둔다. 카탈로그는 `tool/build_catalog.dart`
/// 를 다시 돌릴 때마다 바뀌므로, 특정 기기 이름을 테스트에 박아두면 다음
/// 갱신에서 전부 깨진다.
Catalog readCatalog() => Catalog.fromJson(
  jsonDecode(File(defaultCatalogAsset).readAsStringSync())
      as Map<String, dynamic>,
);

/// 기본 가중치로 매긴 순위. 랭킹 화면이 보여주는 것과 같은 순서다.
List<RankedDevice> readRanking() =>
    Ranking.of(readCatalog().smartphones, RankAxis.tpIndex, TpWeights.defaults);

/// 없는 경로. 애셋이 빠졌거나 깨진 빌드를 흉내낸다.
const String missingCatalogAsset = 'assets/catalog/없는파일.json';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  required TpChrome chrome,
  required List<Override> overrides,
  required Size size,
  required String catalogAsset,
  required double textScale,
  required bool disableAnimations,
  bool dark = false,
  // `.tr()` 은 전역 Localization 을 보지만, 위젯이 Localizations.localeOf 로
  // 언어를 고를 때는 MaterialApp 쪽도 맞춰줘야 한다.
  Locale? locale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  // 안전 영역이 0 인 기기는 없다. 셸이 헤더·탭 바 위치를 여기서 잡으므로
  // 이걸 비워두면 콘텐츠가 헤더 스크림 아래로 들어가 실제와 다르게 겹친다.
  tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(bundle: FileBundle(), assetPath: catalogAsset),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        // 골든에 빨간 DEBUG 리본이 같이 구워진다.
        debugShowCheckedModeBanner: false,
        locale: locale,
        supportedLocales: const <Locale>[
          Locale('en', 'US'),
          Locale('ko', 'KR'),
        ],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.of(chrome, dark: dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
}

/// 지금 화면의 시맨틱 라벨 전부.
///
/// `find.bySemanticsLabel` 은 병합된 노드를 놓치는 경우가 있어 트리를 직접
/// 훑는다. 스크린 리더가 실제로 읽는 것이 이 목록이다.
List<String> semanticsLabels(WidgetTester tester) {
  final labels = <String>[];
  void walk(SemanticsNode node) {
    if (node.label.isNotEmpty) labels.add(node.label);
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  // 시맨틱 트리는 뷰별 파이프라인에 달려 있다. 루트와 자식 오너를 모두 본다.
  void fromOwner(PipelineOwner owner) {
    final root = owner.semanticsOwner?.rootSemanticsNode;
    if (root != null) walk(root);
    owner.visitChildren(fromOwner);
  }

  fromOwner(tester.binding.rootPipelineOwner);
  return labels;
}
