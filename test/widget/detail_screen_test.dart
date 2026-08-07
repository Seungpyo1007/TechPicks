
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/shared/widgets/tp_score_strip.dart';

Future<void> _pump(
  WidgetTester tester,
  String slug, {
  TpChrome chrome = TpChrome.ios,
}) =>
    pumpScreen(tester, DetailScreen(slug: slug),
        chrome: chrome,
      size: const Size(1200, 3200));

void main() {
  setUp(initLocalization);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('카탈로그에 있는 기기를 그린다', (tester) async {
    await _pump(tester, 'galaxy-s25');

    expect(find.text('Galaxy S25'), findsOneWidget);
    expect(find.text('SAMSUNG'), findsOneWidget);
    expect(find.text(r'$799'), findsWidgets);
    expect(find.byType(TpScoreStrip), findsOneWidget);
  });

  testWidgets('스펙 열 개를 명세 순서로 보여준다', (tester) async {
    await _pump(tester, 'galaxy-s25');

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
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(find.text('Snapdragon 8 Elite'), findsOneWidget);
  });

  testWidgets('shortlist 버튼이 상태에 따라 라벨을 바꾼다', (tester) async {
    await _pump(tester, 'galaxy-s25');

    expect(find.text('Add to shortlist'), findsOneWidget);
    expect(find.text('On your shortlist'), findsNothing);

    await tester.tap(find.text('Add to shortlist'));
    await tester.pumpAndSettle();

    expect(find.text('On your shortlist'), findsOneWidget);
    expect(find.text('Add to shortlist'), findsNothing);
  });

  testWidgets('출처를 표기한다', (tester) async {
    await _pump(tester, 'galaxy-s25');
    // CC-BY-SA 4.0 의무. 빠지면 라이선스 위반이라 테스트로 묶어둔다.
    expect(find.text('Data from TechAPI · CC-BY-SA 4.0'), findsOneWidget);
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, 'oneplus-13', chrome: chrome);
      expect(find.text('OnePlus 13'), findsOneWidget);
    }
  });

  testWidgets('세 가지 동작 버튼이 있다', (tester) async {
    await _pump(tester, 'galaxy-s25');
    expect(find.text('Compare'), findsOneWidget);
    expect(find.text('View in 3D'), findsOneWidget);
  });
}
