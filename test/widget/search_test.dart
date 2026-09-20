import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/domain/model/search_index.dart';
import 'package:techpicks/feature/search/search_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:techpicks/shared/widgets/tp_surface.dart';

import '../support/harness.dart';

Future<void> _type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pumpAndSettle();
}

void main() {
  setUp(initLocalization);

  group('색인', () {
    test('세 갈래를 한 목록으로 편다', () {
      final catalog = readCatalog();
      final index = SearchIndex.of(
        phones: catalog.smartphones,
        processors: catalog.cpus,
        laptops: readLaptops().items,
      );

      expect(
        index,
        hasLength(
          catalog.smartphones.length +
              catalog.cpus.length +
              readLaptops().items.length,
        ),
      );
      for (final kind in SearchKind.values) {
        expect(
          index.where((h) => h.kind == kind),
          isNotEmpty,
          reason: kind.name,
        );
      }
    });

    test('빈 질의는 빈 목록이다', () {
      // DeviceSearch 는 전체를 돌려준다 — 거기선 목록이 먼저 있고 검색이
      // 좁힌다. 여기선 반대다.
      final index = SearchIndex.of(phones: readCatalog().smartphones);

      expect(SearchIndex.filter(index, ''), isEmpty);
      expect(SearchIndex.filter(index, '   '), isEmpty);
    });

    test('이름과 부제 어느 쪽에 걸려도 남는다', () {
      final index = SearchIndex.of(phones: readCatalog().smartphones);
      final sample = index.firstWhere((h) => h.meta != null);
      final brand = sample.meta!.split(' · ').first;

      expect(SearchIndex.filter(index, sample.name), isNotEmpty);
      expect(SearchIndex.filter(index, brand), isNotEmpty);
      expect(SearchIndex.filter(index, brand.toUpperCase()), isNotEmpty);
    });
  });

  group('화면', () {
    testWidgets('열면 결과가 아니라 안내가 있다', (tester) async {
      await pumpScreen(tester, const SearchScreen());

      expect(find.text(K.searchEmpty.tr()), findsOneWidget);
    });

    testWidgets('치면 세 갈래에서 찾는다', (tester) async {
      await pumpScreen(
        tester,
        const SearchScreen(),
        size: const Size(402, 2400),
      );

      // 데스크톱 CPU 가 아니라 카탈로그의 모바일 CPU 를 훑는다.
      await _type(tester, readCatalog().cpus.first.name);
      expect(find.text(K.searchKindCpu.tr()), findsWidgets);

      await _type(tester, readCatalog().smartphones.first.name);
      expect(find.text(K.searchKindPhone.tr()), findsWidgets);
    });

    testWidgets('몇 건인지 알려준다', (tester) async {
      await pumpScreen(
        tester,
        const SearchScreen(),
        size: const Size(402, 2400),
      );

      final name = readCatalog().smartphones.first.name;
      await _type(tester, name);

      final hits = SearchIndex.filter(
        SearchIndex.of(
          phones: readCatalog().smartphones,
          processors: readCatalog().cpus,
          laptops: readLaptops().items,
        ),
        name,
      );
      expect(
        find.text(K.searchCount.tr(args: <String>['${hits.length}'])),
        findsOneWidget,
      );
    });

    testWidgets('맞는 게 없으면 그렇게 말한다', (tester) async {
      await pumpScreen(tester, const SearchScreen());

      await _type(tester, '없는기기이름zzz');

      expect(find.text(K.noMatches.tr()), findsOneWidget);
    });

    testWidgets('결과를 누르면 무엇을 눌렀는지 알려준다', (tester) async {
      SearchHit? picked;
      await pumpScreen(
        tester,
        SearchScreen(onHit: (h) => picked = h),
        size: const Size(402, 2400),
      );

      final phone = readCatalog().smartphones.first;
      await _type(tester, phone.name);

      // 글자가 아니라 줄을 누른다. 이름이 길면 말줄임으로 잘려서 글자
      // 위가 손가락 자리가 아니다.
      await tester.tap(
        find
            .ancestor(
              of: find.text(phone.name),
              matching: find.byType(TpSurface),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(picked?.slug, phone.slug);
      expect(picked?.kind, SearchKind.phone);
    });

    testWidgets('두 크롬 모두에서 그려진다', (tester) async {
      for (final chrome in TpChrome.values) {
        await pumpScreen(tester, const SearchScreen(), chrome: chrome);
        expect(
          find.text(K.searchTitle.tr()),
          findsWidgets,
          reason: chrome.name,
        );
      }
    });
  });
}
