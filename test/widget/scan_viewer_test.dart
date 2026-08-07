import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/feature/scan/scan_screen.dart';
import 'package:techpicks/feature/viewer/viewer_screen.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(File(key).readAsBytesSync().buffer);

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode(File(key).readAsBytesSync());
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  TpChrome chrome = TpChrome.ios,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(bundle: _FileBundle()),
        ),
      ],
      child: MaterialApp(theme: AppTheme.of(chrome), home: screen),
    ),
  );
  // 스캔 선이 계속 도니 settle 이 끝나지 않는다.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('스캔', () {
    testWidgets('대기 중에는 안내만', (tester) async {
      await _pump(tester, const ScanScreen());

      expect(find.text('Scan'), findsOneWidget);
      expect(find.text(ScanScreen.idleHint), findsOneWidget);
      expect(find.text('DETECTED'), findsNothing);
    });

    testWidgets('인식되면 결과 카드가 뜬다', (tester) async {
      await _pump(
        tester,
        const ScanScreen(recognizedText: 'SAMSUNG Galaxy S25 Ultra'),
      );

      expect(find.text('DETECTED'), findsOneWidget);
      expect(find.text('Galaxy S25 Ultra'), findsOneWidget);
      expect(find.text('Open device'), findsOneWidget);
      expect(find.text(ScanScreen.doneHint), findsOneWidget);
    });

    testWidgets('못 맞추면 대기 상태 그대로', (tester) async {
      await _pump(
        tester,
        const ScanScreen(recognizedText: 'FCC ID A3LSMS931U'),
      );

      expect(find.text('DETECTED'), findsNothing);
      expect(find.text(ScanScreen.idleHint), findsOneWidget);
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
      for (final part in ViewerScreen.parts) {
        expect(find.text(part), findsOneWidget, reason: part);
      }
      expect(find.text(ViewerScreen.note), findsOneWidget);
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
