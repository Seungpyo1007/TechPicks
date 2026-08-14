import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/service/link_opener.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';

import '../support/harness.dart';

class _StubOpener implements LinkOpener {
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

/// 상세의 브랜드 카드.
///
/// 기기 레코드에 임베드된 brand 는 이름뿐이다. 국가·설립연도·설명은 카탈로그의
/// `brands` 에서만 온다.
void main() {
  setUp(initLocalization);

  final samsung = readCatalog().brands.firstWhere((b) => b.slug == 'samsung');

  Future<_StubOpener> pump(
    WidgetTester tester, {
    String slug = 'galaxy-s25',
    TpChrome chrome = TpChrome.ios,
    String catalogAsset = defaultCatalogAsset,
  }) async {
    final opener = _StubOpener();
    await pumpScreen(
      tester,
      DetailScreen(slug: slug),
      chrome: chrome,
      size: const Size(1200, 4200),
      catalogAsset: catalogAsset,
      overrides: <Override>[linkOpenerProvider.overrideWithValue(opener)],
    );
    return opener;
  }

  testWidgets('만든 회사와 설명을 보여준다', (tester) async {
    await pump(tester);

    expect(find.text(samsung.name), findsWidgets);
    expect(find.textContaining('${samsung.foundedYear}'), findsOneWidget);
    expect(find.text(samsung.descriptionEn!), findsOneWidget);
  });

  testWidgets('한국어에서는 한국어 설명을 쓴다', (tester) async {
    await initLocalization(locale: const Locale('ko', 'KR'));

    await pumpScreen(
      tester,
      const DetailScreen(slug: 'galaxy-s25'),
      size: const Size(1200, 4200),
      overrides: <Override>[
        linkOpenerProvider.overrideWithValue(_StubOpener()),
      ],
      locale: const Locale('ko', 'KR'),
    );

    expect(find.text(samsung.descriptionKo!), findsOneWidget);
  });

  testWidgets('웹사이트를 누르면 그 주소가 열린다', (tester) async {
    final opener = await pump(tester);

    await tester.tap(find.text('Website'));
    await tester.pumpAndSettle();

    expect(opener.opened, <Uri>[Uri.parse(samsung.website!)]);
  });

  testWidgets('두 크롬 다 그린다', (tester) async {
    for (final chrome in TpChrome.values) {
      await pump(tester, chrome: chrome);
      expect(find.text(samsung.name), findsWidgets, reason: chrome.name);
    }
  });

  testWidgets('브랜드 목록이 없는 카탈로그에서는 조용히 빈다', (tester) async {
    // Remote Config 로 받아둔 옛 카탈로그에는 brands 가 없다.
    await pump(tester, catalogAsset: missingCatalogAsset);

    expect(find.text('Website'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
