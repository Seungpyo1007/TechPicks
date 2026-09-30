// 네이티브 스플래시 PNG 를 TpLogo 의 첫 모습(토글 꺼짐)에서 뜬다.
//
//   flutter test tool/icons/render_splash_test.dart
//   dart run flutter_native_splash:create
//
// 스플래시에서 앱으로 넘어오는 첫 프레임이 픽셀까지 같아야 이음새가 안 보인다.
// PREVIEW=<폴더> 를 주면 꺼짐·중간·켜짐을 나란히 떠서 그 폴더에 둔다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/brand/tp_logo.dart';

Future<void> _shoot(WidgetTester tester, Widget logo, String path) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(key: key, child: logo),
      ),
    ),
  );
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('스플래시 PNG', (tester) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // iOS 125pt·Android 160dp 를 4배로(스플래시 도구는 xxxhdpi 로 본다).
    for (final (name, android, dark) in <(String, bool, bool)>[
      ('logo', false, false),
      ('logo_dark', false, true),
      ('logo_android', true, false),
      ('logo_android_dark', true, true),
    ]) {
      await _shoot(
        tester,
        TpLogo(size: android ? 640 : 500, on: 0, android: android, dark: dark),
        'assets/logo/$name.png',
      );
    }
    // Android 12+: 바탕 원은 시스템이 칠하고(icon_background_color), 그림은
    // 960 안의 지름 640 원에 막대만.
    for (final (name, dark) in <(String, bool)>[
      ('splash_android12', false),
      ('splash_android12_dark', true),
    ]) {
      await _shoot(
        tester,
        SizedBox.square(
          dimension: 960,
          child: Center(
            child: TpLogo(
              size: 640,
              on: 0,
              android: true,
              dark: dark,
              plate: false,
            ),
          ),
        ),
        'assets/logo/$name.png',
      );
    }
    final preview = Platform.environment['PREVIEW'];
    if (preview == null) return;
    for (final android in <bool>[false, true]) {
      for (final on in <double>[0, .5, 1]) {
        await _shoot(
          tester,
          TpLogo(size: 500, on: on, android: android),
          '$preview/${android ? 'a' : 'i'}_$on.png',
        );
      }
    }
  });
}
