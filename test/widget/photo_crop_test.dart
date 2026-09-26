import 'dart:typed_data' show Uint8List;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/feature/you/photo_crop_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 가로로 긴 사진. 왼쪽 절반 빨강, 오른쪽 절반 파랑.
Uint8List _wide() {
  final image = img.Image(width: 400, height: 200);
  img.fill(image, color: img.ColorRgb8(0, 0, 255));
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: 199,
    y2: 199,
    color: img.ColorRgb8(255, 0, 0),
  );
  return img.encodePng(image);
}

void main() {
  setUp(initLocalization);

  for (final chrome in TpChrome.values) {
    testWidgets('원 안을 512 정사각 JPEG 로 준다 · ${chrome.name}', (tester) async {
      Uint8List? result;
      await pumpScreen(
        tester,
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                result = await Navigator.of(context).push<Uint8List>(
                  MaterialPageRoute<Uint8List>(
                    builder: (_) => PhotoCropScreen(bytes: _wide()),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
        chrome: chrome,
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 풀기는 다른 아이솔레이트에서 한다. 진짜 시간을 준다.
      await tester.runAsync(() async {
        for (
          var i = 0;
          i < 50 && find.byType(RawImage).evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(RawImage), findsOneWidget);

      final choose = chrome == TpChrome.ios ? K.cropChoose : K.done;
      await tester.tap(find.text(choose.tr()));
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && result == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
        }
      });
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      final out = img.decodeJpg(result!)!;
      expect(out.width, PhotoCropScreen.size);
      expect(out.height, PhotoCropScreen.size);
      // 처음엔 가운데. 왼쪽 끝은 빨강, 오른쪽 끝은 파랑.
      expect(out.getPixel(10, 256).r, greaterThan(200));
      expect(out.getPixel(500, 256).b, greaterThan(200));
    });
  }
}
