// 실기기 프레임 시간. 개편 전후를 같은 동작으로 잰다(#25).
//
//   flutter drive --profile -d <기기> \
//     --driver test_driver/perf_driver.dart \
//     --target integration_test/perf_test.dart
//
// 결과는 build/perf/<동작>.json. 온보딩과 로그인은 저장값으로 건너뛴다.

import 'dart:ui' show FrameTiming;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:techpicks/feature/viewer/viewer_stage.dart';
import 'package:techpicks/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('frame times', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tutorial_completed', true);
    await prefs.setBool('browsing_as_guest', true);
    await prefs.setStringList('shortlist_slugs', <String>[
      'galaxy-s26-ultra',
      'iphone-17-pro-max',
      'pixel-10-pro-xl',
    ]);

    app.main();
    await _settle(tester);

    GoRouter router() =>
        GoRouter.of(tester.element(find.byType(Scrollable).first));

    // binding.watchPerformance 는 GC 수를 세려고 VM 서비스에 붙는데, 무선
    // 기기에서는 그 포트에 못 닿는다. 프레임 시간만 앱 안에서 모은다.
    Future<void> watch(Future<void> Function() action, String key) async {
      await Future<void>.delayed(const Duration(seconds: 2));
      final timings = <FrameTiming>[];
      binding.addTimingsCallback(timings.addAll);
      await action();
      await Future<void>.delayed(const Duration(seconds: 2));
      binding.removeTimingsCallback(timings.addAll);
      binding.reportData ??= <String, dynamic>{};
      binding.reportData![key] = FrameTimingSummarizer(timings).summary;
    }

    Future<void> fling(String name) => watch(() async {
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, -600), 2400);
        await _settle(tester);
        await tester.fling(list, const Offset(0, 600), 2400);
        await _settle(tester);
      }
    }, name);

    await fling('today_scroll');

    await watch(() async {
      for (final path in <String>['/browse', '/', '/browse', '/']) {
        router().go(path);
        await _settle(tester);
      }
    }, 'tab_switch');

    router().go('/browse');
    await _settle(tester);
    await fling('rank_scroll');

    router().go('/you');
    await _settle(tester);
    final slider = find.byWidgetPredicate(
      (w) => w is Slider || w is CupertinoSlider,
    );
    if (slider.evaluate().isNotEmpty) {
      await tester.ensureVisible(slider.first);
      await _settle(tester);
      await watch(() async {
        for (var i = 0; i < 3; i++) {
          await tester.drag(slider.first, const Offset(160, 0));
          await _settle(tester);
          await tester.drag(slider.first, const Offset(-160, 0));
          await _settle(tester);
        }
      }, 'weight_slider');
    }

    // 뷰어: 드래그 회전과 분해도. 부품 칩은 언어와 무관하게 셋째 줄 첫 버튼.
    router().go('/device/galaxy-s26-ultra/3d');
    await _settle(tester);
    final stage = find.byType(ViewerStage);
    if (stage.evaluate().isNotEmpty) {
      await watch(() async {
        for (var i = 0; i < 3; i++) {
          await tester.fling(stage, const Offset(260, 40), 1800);
          await _settle(tester);
          await tester.fling(stage, const Offset(-260, -40), 1800);
          await _settle(tester);
        }
        final chips = find.descendant(
          of: find.byType(Wrap),
          matching: find.byType(GestureDetector),
        );
        for (var i = 0; i < 4; i++) {
          await tester.tap(chips.at(i % 4));
          await _settle(tester);
        }
      }, 'viewer');
    }
  });
}

/// pumpAndSettle 은 계속 도는 애니메이션이 있으면 끝나지 않는다. 시간으로 끊는다.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
