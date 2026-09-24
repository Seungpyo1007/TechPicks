import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/service/link_opener.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/you/sources_screen.dart';
import 'package:techpicks/feature/you/you_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:techpicks/shared/widgets/tp_tap_target.dart';

import '../support/harness.dart';

/// 브라우저를 안 띄운다. 어디로 가려 했는지만 받아 적는다.
class _StubOpener implements LinkOpener {
  final List<Uri> opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

/// 열 앱이 없는 기기.
class _BrokenOpener implements LinkOpener {
  @override
  Future<bool> open(Uri url) async => throw StateError('열 수 있는 앱이 없다');
}

Future<_StubOpener> _pump(
  WidgetTester tester,
  Widget screen, {
  TpChrome chrome = TpChrome.ios,
  LinkOpener? opener,
}) async {
  final stub = _StubOpener();
  await pumpScreen(
    tester,
    screen,
    chrome: chrome,
    size: const Size(1200, 3200),
    overrides: <Override>[linkOpenerProvider.overrideWithValue(opener ?? stub)],
  );
  return stub;
}

void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('상세 출처', () {
    testWidgets('표기를 누르면 라이선스 본문이 열린다', (tester) async {
      // CC-BY-SA 는 표기만으로 안 되고 라이선스에 닿을 수 있어야 한다.
      final stub = await _pump(tester, const DetailScreen(slug: 'galaxy-s25'));

      await tester.tap(find.text(K.dataSource.tr()));
      await tester.pumpAndSettle();

      expect(stub.opened, <Uri>[TpUrls.license]);
    });

    testWidgets('출처는 도메인만 보여주고 원문으로 연다', (tester) async {
      // 원문 주소는 한 줄을 다 먹는다. 귀속에 필요한 건 링크가 사는 것이다.
      final stub = await _pump(tester, const DetailScreen(slug: 'galaxy-s25'));

      final source = readCatalog().smartphones
          .firstWhere((d) => d.slug == 'galaxy-s25')
          .sourceUrls
          .first;
      final host = Uri.parse(source).host;

      expect(find.text(source), findsNothing);
      await tester.tap(find.text(host).first);
      await tester.pumpAndSettle();

      expect(stub.opened, <Uri>[Uri.parse(source)]);
    });

    testWidgets('두 크롬 다 열린다', (tester) async {
      for (final chrome in TpChrome.values) {
        final stub = await _pump(
          tester,
          const DetailScreen(slug: 'galaxy-s25'),
          chrome: chrome,
        );
        await tester.tap(find.text(K.dataSource.tr()));
        await tester.pumpAndSettle();
        expect(stub.opened, hasLength(1), reason: chrome.name);
      }
    });

    testWidgets('못 열어도 화면이 죽지 않는다', (tester) async {
      await _pump(
        tester,
        const DetailScreen(slug: 'galaxy-s25'),
        opener: _BrokenOpener(),
      );

      await tester.tap(find.text(K.dataSource.tr()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Galaxy S25'), findsWidgets);
    });

    testWidgets('스크린 리더가 링크로 읽는다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const DetailScreen(slug: 'galaxy-s25'));

      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.text(K.dataSource.tr()),
            matching: find.byType(TpTapTarget),
          ),
        ),
        // 포커스도 받는다 — 키보드로 닿을 수 있어야 한다.
        matchesSemantics(
          isLink: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          label: K.dataSource.tr(),
        ),
      );
      handle.dispose();
    });
  });

  group('You 푸터', () {
    testWidgets('버전 줄을 누르면 Apache-2.0 이 열린다', (tester) async {
      final stub = await _pump(tester, const YouScreen());

      await tester.tap(find.text(YouScreen.versionLine));
      await tester.pumpAndSettle();

      expect(stub.opened, <Uri>[TpUrls.appLicense]);
    });

    testWidgets('명세의 푸터 문구는 그대로다', (tester) async {
      await _pump(tester, const YouScreen());

      expect(find.text('TechPicks version 2.0.0 · Apache-2.0'), findsOneWidget);
    });

    testWidgets('데이터 출처로 가는 줄이 있다', (tester) async {
      // 표기가 어디에도 없으면 CC-BY-SA 를 안 지킨 것이다. You 에서 닿을
      // 수 있어야 한다.
      await _pump(tester, const YouScreen());

      expect(find.text(K.sources.tr()), findsOneWidget);
    });
  });

  group('데이터 출처 화면', () {
    testWidgets('카탈로그가 들고 온 출처 문자열을 그대로 적는다', (tester) async {
      // 손으로 적어두면 카탈로그를 다시 구울 때 어긋난다.
      await _pump(tester, const SourcesScreen());

      expect(find.text(readCatalog().source), findsOneWidget);
    });

    testWidgets('라이선스 본문과 원본에 닿는다', (tester) async {
      // 귀속은 "적는 것"에서 끝나지 않는다. 둘 다 열려야 한다.
      final stub = await _pump(tester, const SourcesScreen());

      await tester.tap(find.text(K.sourcesLicense.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(K.sourcesRepo.tr()));
      await tester.pumpAndSettle();

      expect(stub.opened, <Uri>[TpUrls.license, TpUrls.techApi]);
    });

    testWidgets('실린 것의 수를 적는다', (tester) async {
      // "TechAPI 에서 왔습니다" 한 줄보다 무엇이 얼마나 실렸는지가 정직하다.
      await _pump(tester, const SourcesScreen());
      final catalog = readCatalog();

      expect(
        find.text(
          K.sourcesPhones.tr(args: <String>['${catalog.smartphones.length}']),
        ),
        findsOneWidget,
      );
      expect(
        find.text(K.sourcesVersion.tr(args: <String>['${catalog.version}'])),
        findsOneWidget,
      );
    });

    testWidgets('두 크롬 모두에서 그려진다', (tester) async {
      for (final chrome in TpChrome.values) {
        await _pump(tester, const SourcesScreen(), chrome: chrome);
        expect(find.text(K.sources.tr()), findsWidgets, reason: chrome.name);
      }
    });

    testWidgets('못 열어도 화면이 죽지 않는다', (tester) async {
      await _pump(tester, const SourcesScreen(), opener: _BrokenOpener());

      await tester.tap(find.text(K.sourcesLicense.tr()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
