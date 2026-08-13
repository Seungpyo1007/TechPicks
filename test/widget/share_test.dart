import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/service/share_service.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/home/home_screen.dart';

import '../support/harness.dart';

/// 무엇을 보내는지만 받아 적는다. 시트는 안 띄운다.
class _StubShare implements ShareService {
  final List<({String text, String? subject})> sent =
      <({String text, String? subject})>[];

  @override
  Future<void> shareText(String text, {String? subject}) async {
    sent.add((text: text, subject: subject));
  }
}

/// 시트를 못 띄우는 기기.
class _ThrowingShare implements ShareService {
  @override
  Future<void> shareText(String text, {String? subject}) async =>
      throw StateError('공유 시트 없음');
}

Future<_StubShare> _pump(
  WidgetTester tester,
  Widget screen, {
  TpChrome chrome = TpChrome.ios,
  ShareService? service,
}) async {
  final stub = service is _StubShare ? service : _StubShare();
  await pumpScreen(
    tester,
    screen,
    chrome: chrome,
    size: const Size(1200, 3200),
    overrides: <Override>[
      shareServiceProvider.overrideWithValue(service ?? stub),
    ],
  );
  return stub;
}

void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('상세', () {
    testWidgets('이름·지수·링크를 보낸다', (tester) async {
      final stub = await _pump(tester, const DetailScreen(slug: 'galaxy-s25'));

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(stub.sent, hasLength(1));
      expect(stub.sent.single.text, '''
Galaxy S25 — TP Index 61
techpicks://device/galaxy-s25''');
      expect(stub.sent.single.subject, 'TechPicks — Galaxy S25');
    });

    testWidgets('두 크롬 다 버튼이 있다', (tester) async {
      for (final chrome in TpChrome.values) {
        final stub = await _pump(
          tester,
          const DetailScreen(slug: 'galaxy-s25'),
          chrome: chrome,
        );
        await tester.tap(find.byIcon(Icons.share));
        await tester.pumpAndSettle();
        expect(stub.sent, hasLength(1), reason: chrome.name);
      }
    });

    testWidgets('스크린 리더가 이름을 읽는다', (tester) async {
      // 아이콘만 있는 버튼이다. iOS 는 유리 알약에 라벨을, Android 는 앱 바
      // 액션에 툴팁을 단다 — 둘 다 스크린 리더가 읽는다.
      final handle = tester.ensureSemantics();

      await _pump(tester, const DetailScreen(slug: 'galaxy-s25'));
      expect(find.bySemanticsLabel('Share'), findsOneWidget);

      await _pump(
        tester,
        const DetailScreen(slug: 'galaxy-s25'),
        chrome: TpChrome.android,
      );
      expect(find.byTooltip('Share'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('못 불러온 기기는 공유 버튼이 없다', (tester) async {
      await _pump(tester, const DetailScreen(slug: '없는-기기'));

      expect(find.byIcon(Icons.share), findsNothing);
    });

    testWidgets('시트가 실패해도 화면이 죽지 않는다', (tester) async {
      await _pump(
        tester,
        const DetailScreen(slug: 'galaxy-s25'),
        service: _ThrowingShare(),
      );

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Galaxy S25'), findsOneWidget);
    });
  });

  group('홈 결론 카드', () {
    testWidgets('근거 한 줄이 같이 간다', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'shortlist_slugs': <String>['galaxy-s25', 'oneplus-13'],
      });
      final stub = await _pump(tester, const HomeScreen());

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();

      expect(stub.sent.single.text, '''
OnePlus 13 — TP Index 72
Leads your shortlist, carried by battery.
techpicks://device/oneplus-13''');
    });

    testWidgets('shortlist 가 비면 공유할 결론도 없다', (tester) async {
      await _pump(tester, const HomeScreen());

      expect(find.byIcon(Icons.share), findsNothing);
    });
  });
}
