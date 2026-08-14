import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/service/link_opener.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
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
      expect(find.text('Galaxy S25'), findsOneWidget);
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
        matchesSemantics(
          isLink: true,
          hasTapAction: true,
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
  });
}
