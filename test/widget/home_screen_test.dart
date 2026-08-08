
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/feature/home/home_screen.dart';
import 'package:techpicks/shared/widgets/tp_score_strip.dart';

ProviderContainer? _container;

Future<void> _pump(WidgetTester tester, {TpChrome chrome = TpChrome.ios}) async {
  _container = await pumpScreen(tester, const HomeScreen(),
      chrome: chrome,
      size: const Size(1200, 3200));
}

void main() {
  group('shortlist 지우기', _shortlistRemoval);

  setUp(initLocalization);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('shortlist 가 비면 결론 카드 대신 빈 상태', (tester) async {
    await _pump(tester);

    expect(find.text('Nothing on your shortlist yet'), findsOneWidget);
    expect(find.text('Add a device'), findsOneWidget);
    // 명세: 빈 상태에서는 결론 카드를 보여주지 않는다.
    expect(find.text('WHERE THIS LANDS'), findsNothing);
    expect(find.byType(TpScoreStrip), findsNothing);
  });

  testWidgets('shortlist 가 차면 결론 카드가 나온다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25', 'oneplus-13'],
    });
    await _pump(tester);

    expect(find.text('WHERE THIS LANDS'), findsOneWidget);
    expect(find.byType(TpScoreStrip), findsOneWidget);
    expect(find.text('Compare all'), findsOneWidget);
    expect(find.text('Ask why'), findsOneWidget);
    expect(find.text('Nothing on your shortlist yet'), findsNothing);
  });

  testWidgets('결론은 shortlist 중 지수가 가장 높은 기기', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      // galaxy-s25 61, oneplus-13 74 — 뒤엣것이 이긴다.
      'shortlist_slugs': <String>['galaxy-s25', 'oneplus-13'],
    });
    await _pump(tester);

    expect(_container!.read(verdictProvider)?.slug, 'oneplus-13');
  });

  testWidgets('shortlist 섹션이 담긴 기기를 순서대로 보여준다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25', 'oneplus-13', 'pixel-9-pro'],
    });
    await _pump(tester);

    expect(find.text('Shortlist'), findsOneWidget);
    expect(find.text('Galaxy S25'), findsOneWidget);
    // 결론 카드와 shortlist 행에 각각 한 번씩 나온다.
    expect(find.text('OnePlus 13'), findsWidgets);
    expect(find.text('Pixel 9 Pro'), findsOneWidget);
    expect(
      find.text('3 phones on your shortlist, one decision left.'),
      findsOneWidget,
    );
  });

  testWidgets('저장된 순위가 없으면 Movers 섹션이 없다', (tester) async {
    await _pump(tester);
    expect(find.text('Movers this week'), findsNothing);
  });

  testWidgets('저장된 순위가 있으면 Movers 가 나온다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      // 실제 1위는 galaxy-s25-ultra 다. 뒤집어 저장해두면 변동이 잡힌다.
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
    await _pump(tester);

    expect(find.text('Movers this week'), findsOneWidget);
    expect(_container!.read(moversProvider), hasLength(3));
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, chrome: chrome);
      // iOS 는 콘텐츠 안, Android 는 large app bar 에 제목이 있다.
      expect(find.text('Today'), findsOneWidget);
    }
  });
}

/// 명세 §3 — shortlist 행은 스와이프와 길게 누르기로 지운다.
void _shortlistRemoval() {
  testWidgets('길게 누르면 목록에서 빠진다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25-ultra', 'iphone-16-pro-max'],
    });

    final container = await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();
    expect(container.read(shortlistProvider).length, 2);

    await tester.longPress(find.text('iPhone 16 Pro Max').first);
    await tester.pumpAndSettle();

    expect(container.read(shortlistProvider), <String>['galaxy-s25-ultra']);
  });

  testWidgets('스와이프도 그대로 지운다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25-ultra', 'iphone-16-pro-max'],
    });

    final container = await pumpScreen(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await tester.drag(
      find.text('iPhone 16 Pro Max').first,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(container.read(shortlistProvider), <String>['galaxy-s25-ultra']);
  });
}
