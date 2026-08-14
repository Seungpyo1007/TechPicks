import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/dto/brand.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/feature/compare/picker_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 비교 선택 시트의 검색.
///
/// 카탈로그가 154종이 되면서 손으로 굴려 찾는 게 일이 됐다.
void main() {
  setUp(initLocalization);

  group('거르는 규칙', () {
    const devices = <Smartphone>[
      Smartphone(
        slug: 'galaxy-s25',
        name: 'Galaxy S25',
        brand: Brand(slug: 'samsung', name: 'Samsung'),
      ),
      Smartphone(
        slug: 'iphone-16-pro',
        name: 'iPhone 16 Pro',
        brand: Brand(slug: 'apple', name: 'Apple'),
      ),
    ];

    test('빈 검색어는 전부 그대로', () {
      expect(PickerScreen.filter(devices, '   '), hasLength(2));
    });

    test('이름 일부로 찾는다', () {
      expect(PickerScreen.filter(devices, 's25').single.slug, 'galaxy-s25');
    });

    test('대소문자를 안 가린다', () {
      expect(
        PickerScreen.filter(devices, 'IPHONE').single.slug,
        'iphone-16-pro',
      );
    });

    test('브랜드 이름으로도 찾는다', () {
      // 화면에는 브랜드가 안 보이지만 사람은 "삼성"으로 찾는다.
      expect(PickerScreen.filter(devices, 'samsung').single.slug, 'galaxy-s25');
    });

    test('없으면 빈 목록', () {
      expect(PickerScreen.filter(devices, 'nokia'), isEmpty);
    });
  });

  testWidgets('치는 대로 목록이 줄어든다', (tester) async {
    await pumpScreen(tester, const PickerScreen(), size: const Size(1200, 2400));

    final all = readCatalog().smartphones;
    final target = all.firstWhere((d) => d.name.contains('Galaxy S25'));

    await tester.enterText(find.byType(TextField), target.name);
    await tester.pumpAndSettle();

    // 검색어가 입력칸에도 남아 있어 같은 글자가 둘이다.
    expect(find.text(target.name), findsWidgets);
    // 다른 기기는 사라진다.
    final other = all.firstWhere((d) => !d.name.contains('Galaxy'));
    expect(find.text(other.name), findsNothing);
  });

  testWidgets('결과가 없으면 없다고 말한다', (tester) async {
    await pumpScreen(tester, const PickerScreen(), size: const Size(1200, 2400));

    await tester.enterText(find.byType(TextField), '없는기기이름');
    await tester.pumpAndSettle();

    expect(find.text(K.noDevices.tr()), findsOneWidget);
  });

  testWidgets('지우면 다시 전부 나온다', (tester) async {
    await pumpScreen(tester, const PickerScreen(), size: const Size(1200, 2400));

    await tester.enterText(find.byType(TextField), 'galaxy');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text(readCatalog().smartphones.first.name), findsOneWidget);
  });

  testWidgets('두 크롬 다 그린다', (tester) async {
    for (final chrome in TpChrome.values) {
      await pumpScreen(
        tester,
        const PickerScreen(),
        chrome: chrome,
        size: const Size(1200, 2400),
      );
      expect(find.text(K.searchHint.tr()), findsOneWidget, reason: chrome.name);
    }
  });
}
