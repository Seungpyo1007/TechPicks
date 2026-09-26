import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/app/theme/tp_page_transition.dart';
import 'package:animations/animations.dart'
    show SharedAxisPageTransitionsBuilder;

import '../support/harness.dart';

/// 화면을 밀어 올릴 때의 전환.
///
/// 명세 Interactions — iOS 는 오른쪽에서 슬라이드, Android 는 shared axis X.
void main() {
  setUp(initLocalization);

  PageTransitionsBuilder builderFor(TpChrome chrome, TargetPlatform platform) =>
      AppTheme.of(chrome).pageTransitionsTheme.builders[platform]!;

  test('크롬이 전환을 정한다', () {
    // 호스트 OS 가 아니라 크롬을 따라야 한다. 데스크톱에서 iOS 크롬으로
    // 대조할 때 전환만 Android 로 남으면 비교가 안 된다.
    for (final platform in TargetPlatform.values) {
      expect(
        builderFor(TpChrome.ios, platform),
        isA<TpIosPageTransitionsBuilder>(),
        reason: '$platform',
      );
      expect(
        builderFor(TpChrome.android, platform),
        isA<SharedAxisPageTransitionsBuilder>(),
        reason: '$platform',
      );
    }
  });

  test('shared axis 는 flutter.dev 의 공식 구현을 쓴다', () {
    // 직접 그렸다가 바꿨다. 곡선과 지속 시간은 패키지가 M3 정의대로 들고 있다.
    expect(
      builderFor(
        TpChrome.android,
        TargetPlatform.android,
      ).runtimeType.toString(),
      contains('SharedAxis'),
    );
  });

  testWidgets('Android 는 밀려 들어오며 나타난다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(TpChrome.android),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const Text('다음'))),
            child: const Text('밀기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('밀기'));
    await tester.pump();
    // 전환 중간. 아직 제자리가 아니고 아직 불투명하지도 않다.
    await tester.pump(const Duration(milliseconds: 150));

    // 공식 구현은 FadeTransition 을 쓴다. 전환 중이라 아직 불투명하지 않다.
    final fades = tester
        .widgetList<FadeTransition>(find.byType(FadeTransition))
        .toList();
    expect(fades, isNotEmpty);
    expect(
      fades.any((f) => f.opacity.value > 0 && f.opacity.value < 1),
      isTrue,
    );

    await tester.pumpAndSettle();
    expect(find.text('다음'), findsOneWidget);
  });

  testWidgets('전환이 끝나면 제자리에 온전히 선다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(TpChrome.android),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const Text('다음'))),
            child: const Text('밀기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('밀기'));
    await tester.pumpAndSettle();

    for (final f in tester.widgetList<FadeTransition>(
      find.byType(FadeTransition),
    )) {
      expect(f.opacity.value, 1);
    }
  });

  group('iOS 26 뒤로 밀기', () {
    Future<void> pushed(WidgetTester tester, Widget next) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(TpChrome.ios),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(body: Center(child: next)),
                ),
              ),
              child: const Text('밀기'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('밀기'));
      await tester.pumpAndSettle();
    }

    testWidgets('화면 가운데서 절반 넘게 밀면 뒤로 간다', (tester) async {
      await pushed(tester, const Text('다음'));

      // 시험 화면은 800 폭.
      await tester.dragFrom(const Offset(200, 400), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('다음'), findsNothing);
      expect(find.text('밀기'), findsOneWidget);
    });

    testWidgets('짧아도 빠르게 튕기면 뒤로 간다', (tester) async {
      await pushed(tester, const Text('다음'));

      await tester.flingFrom(const Offset(200, 400), const Offset(200, 0), 2000);
      await tester.pumpAndSettle();

      expect(find.text('다음'), findsNothing);
    });

    testWidgets('왼쪽으로 밀면 그대로다', (tester) async {
      await pushed(tester, const Text('다음'));

      await tester.dragFrom(const Offset(300, 400), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets('조금 밀다 놓으면 돌아온다', (tester) async {
      await pushed(tester, const Text('다음'));

      final g = await tester.startGesture(const Offset(200, 400));
      await g.moveBy(const Offset(30, 0));
      await g.moveBy(const Offset(30, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await g.up();
      await tester.pumpAndSettle();

      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets('안쪽 가로 스크롤이 먼저다', (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await pushed(
        tester,
        SizedBox(
          height: 80,
          child: ListView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              for (var i = 0; i < 20; i++)
                SizedBox(width: 120, child: Text('칩 $i')),
            ],
          ),
        ),
      );
      controller.jumpTo(600);
      await tester.pump();

      await tester.dragFrom(const Offset(200, 300), const Offset(200, 0));
      await tester.pumpAndSettle();

      // 페이지는 그대로, 목록만 되감겼다.
      expect(find.byType(ListView), findsOneWidget);
      expect(controller.offset, lessThan(600));
    });

    testWidgets('움직이는 동안만 모서리가 둥글다', (tester) async {
      await pushed(tester, const Text('다음'));
      expect(find.byType(ClipRRect), findsNothing);

      final g = await tester.startGesture(const Offset(200, 400));
      await g.moveBy(const Offset(40, 0));
      await g.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(find.byType(ClipRRect), findsWidgets);
      await g.up();
      await tester.pumpAndSettle();
    });
  });
}
