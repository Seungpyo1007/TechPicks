import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:easy_localization/easy_localization.dart';

import '../support/harness.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/feature/scan/scan_screen.dart';
import 'package:techpicks/feature/viewer/viewer_screen.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  TpChrome chrome = TpChrome.ios,
}) async {
  // 스캔 선이 계속 도니 pumpAndSettle 이 끝나지 않는다. 시간을 정해 넘긴다.
  await pumpScreenNoSettle(
    tester,
    screen,
    chrome: chrome,
    size: const Size(1200, 2400),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(initLocalization);

  group('기기 찾기', () {
    testWidgets('빈 칸이면 안내만', (tester) async {
      await _pump(tester, const ScanScreen());

      expect(find.text('Find your device'), findsOneWidget);
      expect(find.text(K.scanHintIdle.tr()), findsOneWidget);
      expect(find.text('MATCH'), findsNothing);
    });

    testWidgets('적으면 결과 카드가 뜬다', (tester) async {
      await _pump(tester, const ScanScreen());

      await tester.enterText(
        find.byType(TextField),
        'SAMSUNG Galaxy S25 Ultra',
      );
      await tester.pump();

      expect(find.text('MATCH'), findsOneWidget);
      expect(find.text('Galaxy S25 Ultra'), findsOneWidget);
      expect(find.text('Open device'), findsOneWidget);
      expect(find.text(K.scanHintDone.tr()), findsOneWidget);
    });

    testWidgets('못 맞추면 못 찾았다고 말한다', (tester) async {
      await _pump(tester, const ScanScreen());

      await tester.enterText(find.byType(TextField), 'FCC ID A3LSMS931U');
      await tester.pump();

      expect(find.text('MATCH'), findsNothing);
      expect(find.text(K.scanNoMatch.tr()), findsOneWidget);
    });

    // 카메라가 붙는 날 OCR 결과가 이 자리로 들어온다.
    testWidgets('미리 채워둔 글자도 그대로 맞춘다', (tester) async {
      await _pump(
        tester,
        const ScanScreen(recognizedText: 'SAMSUNG Galaxy S25 Ultra'),
      );

      expect(find.text('Galaxy S25 Ultra'), findsOneWidget);
    });

    testWidgets('Open device 가 slug 를 넘긴다', (tester) async {
      String? opened;
      await _pump(
        tester,
        ScanScreen(
          recognizedText: 'Galaxy S25 Ultra Samsung',
          onOpenDevice: (s) => opened = s,
        ),
      );

      await tester.tap(find.text('Open device'));
      await tester.pump();
      expect(opened, 'galaxy-s25-ultra');
    });
  });

  group('3D 뷰어', () {
    testWidgets('부품 칩 네 개와 안내 문구', (tester) async {
      await _pump(tester, const ViewerScreen(deviceName: 'Galaxy S25'));

      expect(find.text('Galaxy S25'), findsOneWidget);
      for (final key in ViewerScreen.partKeys) {
        expect(find.text(key.tr()), findsOneWidget, reason: key);
      }
      expect(find.text(K.viewerNote.tr()), findsOneWidget);
    });

    testWidgets('칩을 누르면 강조가 토글된다', (tester) async {
      await _pump(tester, const ViewerScreen(deviceName: 'Galaxy S25'));

      // 강조 상태는 페인터 안이라 예외 없이 눌리는지까지만 본다.
      await tester.tap(find.text('Battery'));
      await tester.pump();
      await tester.tap(find.text('Battery'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('두 크롬 모두에서 그려진다', (tester) async {
      for (final chrome in TpChrome.values) {
        await _pump(
          tester,
          const ViewerScreen(deviceName: 'Galaxy S25'),
          chrome: chrome,
        );
        expect(find.text('Display'), findsOneWidget);
      }
    });
  });
}
