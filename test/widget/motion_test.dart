import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/app/tab_host.dart';
import 'package:techpicks/app/shell/tp_tab.dart';
import 'package:techpicks/app/shell/tp_shell.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/feature/home/home_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/app/theme/tp_motion.dart';
import 'package:techpicks/feature/scan/scan_screen.dart';
import 'package:techpicks/shared/widgets/tp_bar.dart';

import '../support/harness.dart';

/// 모션 토큰.
///
/// 지금까지 애니메이션 값을 검사하는 테스트가 없었다. 220ms·240ms·90ms 가
/// 명세에서 온 값인데 누가 바꿔도 아무도 몰랐다.

TpMotion motionOf(TpChrome chrome) =>
    AppTheme.of(chrome).extension<TpMotion>()!;

/// [BuildContext.motion] 을 꺼내오는 최소 트리.
Future<TpMotion> readMotion(
  WidgetTester tester, {
  required TpChrome chrome,
  bool disableAnimations = false,
}) async {
  late TpMotion captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.of(chrome),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Builder(
          builder: (context) {
            captured = context.motion;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  return captured;
}

void main() {
  setUp(initLocalization);

  group('명세가 정한 값', () {
    // 이 값들은 디자인 결정이라 플랫폼과 무관하게 같아야 한다.
    for (final chrome in TpChrome.values) {
      test('$chrome — 랭킹 재정렬은 220ms 에 명세 커브', () {
        final m = motionOf(chrome).reorder;
        expect(m.duration, const Duration(milliseconds: 220));
        expect(m.curve, const Cubic(.2, .8, .2, 1));
      });

      test('$chrome — 스캔 결과 카드는 240ms 에 같은 커브', () {
        final m = motionOf(chrome).reveal;
        expect(m.duration, const Duration(milliseconds: 240));
        expect(m.curve, const Cubic(.2, .8, .2, 1));
      });

      test('$chrome — 누름은 90ms', () {
        expect(
          motionOf(chrome).press.duration,
          const Duration(milliseconds: 90),
        );
      });
    }

    test('iOS 탭 알약은 180ms', () {
      // 명세 Interactions 표가 iOS 만 못박았다.
      expect(
        motionOf(TpChrome.ios).selection.duration,
        const Duration(milliseconds: 180),
      );
    });
  });

  group('명세가 침묵한 자리는 플랫폼이 갈린다', () {
    final ios = motionOf(TpChrome.ios);
    final android = motionOf(TpChrome.android);

    test('내용 교체', () {
      expect(ios.contentSwap, isNot(android.contentSwap));
      // Android 는 Flutter 가 들고 있는 M3 토큰을 그대로 쓴다.
      expect(android.contentSwap.duration, Durations.medium2);
      expect(android.contentSwap.curve, Easing.emphasizedDecelerate);
    });

    test('값 변화', () {
      expect(ios.valueChange, isNot(android.valueChange));
      expect(android.valueChange.duration, Durations.medium1);
    });

    test('목록 항목', () {
      expect(ios.listItem, isNot(android.listItem));
      expect(android.listItem.duration, Durations.medium1);
    });

    test('고른 상태', () {
      expect(android.selection.duration, Durations.short4);
    });

    test('iOS 는 감속 커브를 쓴다', () {
      expect(ios.press.curve, Curves.easeOutCubic);
      expect(ios.selection.curve, Curves.easeOutCubic);
      expect(ios.valueChange.curve, Curves.easeOutCubic);
    });
  });

  group('동작 줄이기', () {
    for (final chrome in TpChrome.values) {
      testWidgets('$chrome — 켜면 모든 시간이 0 이 된다', (tester) async {
        final m = await readMotion(
          tester,
          chrome: chrome,
          disableAnimations: true,
        );

        for (final move in <TpMove>[
          m.press,
          m.selection,
          m.reorder,
          m.reveal,
          m.valueChange,
          m.contentSwap,
          m.listItem,
        ]) {
          expect(move.duration, Duration.zero, reason: '$move');
        }
        expect(m.isReduced, isTrue);
      });

      testWidgets('$chrome — 끄면 그대로다', (tester) async {
        final m = await readMotion(tester, chrome: chrome);
        expect(m.reorder.duration, const Duration(milliseconds: 220));
        expect(m.isReduced, isFalse);
      });
    }

    testWidgets('커브는 남는다', (tester) async {
      // 시간만 없앤다. 커브를 바꾸면 값이 두 벌이 된다.
      final m = await readMotion(
        tester,
        chrome: TpChrome.ios,
        disableAnimations: true,
      );
      expect(m.reorder.curve, const Cubic(.2, .8, .2, 1));
    });
  });

  group('진행 막대', () {
    /// 지금 그려진 채움 비율.
    double filled(WidgetTester tester) => tester
        .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .widthFactor!;

    Widget bar(double fraction) => Center(
      child: SizedBox(width: 200, child: TpBar(fraction: fraction)),
    );

    Future<void> pumpBar(
      WidgetTester tester,
      double fraction, {
      bool reduce = false,
    }) => pumpScreen(tester, bar(fraction), disableAnimations: reduce);

    testWidgets('값이 바뀌면 중간 프레임을 거친다', (tester) async {
      await pumpBar(tester, 0.2);
      expect(filled(tester), closeTo(0.2, 0.001));

      // settle 하면 다 끝난 뒤라 중간을 못 본다. 한 프레임만 돌린다.
      await pumpScreenNoSettle(tester, bar(0.9));
      await tester.pump(const Duration(milliseconds: 80));

      // 아직 도착하지 않았다. 예전에는 여기서 이미 0.9 였다.
      final mid = filled(tester);
      expect(mid, greaterThan(0.2));
      expect(mid, lessThan(0.9));

      await tester.pumpAndSettle();
      expect(filled(tester), closeTo(0.9, 0.001));
    });

    testWidgets('동작을 줄이면 즉시 간다', (tester) async {
      await pumpBar(tester, 0.2, reduce: true);
      await pumpScreenNoSettle(tester, bar(0.9), disableAnimations: true);
      await tester.pump();
      expect(filled(tester), closeTo(0.9, 0.001));
    });

    testWidgets('범위를 벗어난 값은 자른다', (tester) async {
      await pumpBar(tester, 1.7);
      await tester.pumpAndSettle();
      expect(filled(tester), 1.0);
    });
  });

  group('홈 상태 변화', _homeMotion);

  group('스캔 라인', () {
    testWidgets('평소에는 계속 돈다', (tester) async {
      await pumpScreenNoSettle(
        tester,
        ScanScreen(onBack: () {}),
        size: const Size(1200, 2400),
      );
      // 무한 반복이라 settle 이 끝나지 않는다.
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('동작을 줄이면 멈춘다', (tester) async {
      // 반복이 없으니 settle 이 끝난다. 안 끝나면 여기서 타임아웃이 난다.
      await pumpScreen(
        tester,
        ScanScreen(onBack: () {}),
        size: const Size(1200, 2400),
        disableAnimations: true,
      );

      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}

/// 홈의 상태 변화.
void _homeMotion() {
  testWidgets('빈 상태에서 결론 카드로 갈 때 겹쳐서 넘어간다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final container = await pumpScreen(tester, const HomeScreen());
    expect(find.text(K.emptyShortlist.tr()), findsOneWidget);

    container.read(shortlistProvider.notifier).toggle('galaxy-s25-ultra');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    // 전환 중에는 둘 다 트리에 있다. 하드컷이면 하나만 있다.
    expect(find.byType(AnimatedSwitcher), findsWidgets);
    expect(find.byType(FadeTransition), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.text(K.emptyShortlist.tr()), findsNothing);
    expect(find.text(K.verdict.tr().toUpperCase()), findsOneWidget);
  });

  testWidgets('관심 목록 행이 접히며 사라진다', (tester) async {
    await initLocalization();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25-ultra', 'iphone-16-pro-max'],
    });

    final container = await pumpScreen(tester, const HomeScreen());
    final before = tester.getSize(find.byType(AnimatedSize).first).height;
    expect(before, greaterThan(0));

    container.read(shortlistProvider.notifier).remove('iphone-16-pro-max');
    await tester.pumpAndSettle();

    expect(container.read(shortlistProvider), <String>['galaxy-s25-ultra']);
    expect(tester.takeException(), isNull);
  });

  // 같은 동작이 두 크롬에서 정반대였다 — iOS 는 선택만 움직이고 눌림이 없었고,
  // 안드로이드는 눌림만 있고 선택이 툭 바뀌었다.
  testWidgets('안드로이드 탭도 선택이 움직인다', (tester) async {
    await pumpScreen(
      tester,
      HomeScreen(onTabSelected: (_) {}),
      chrome: TpChrome.android,
    );

    final labels = find.descendant(
      of: find.byType(TpShell),
      matching: find.byType(AnimatedDefaultTextStyle),
    );
    // 탭 다섯 개 + 앱 바 제목. 여섯 개면 다섯 개가 다 감싸졌다는 뜻이다.
    expect(labels, findsNWidgets(TpTab.values.length + 1));
  });

  // 알약이 칸마다 따로 있어 색만 교차하던 때는 **아무것도 움직이지 않았다**.
  // 이제 한 장이 칸에서 칸으로 미끄러진다.
  testWidgets('iOS 탭 알약은 한 장이고 고른 칸으로 옮겨간다', (tester) async {
    await pumpScreen(
      tester,
      const TabHost(),
      size: const Size(402, 874),
      overrides: <Override>[
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );
    await tester.pumpAndSettle();

    final pill = find.byKey(const ValueKey<String>('tab-pill'));
    expect(pill, findsOneWidget);
    // 자리를 시간에 걸쳐 옮기는 위젯이어야 한다.
    expect(
      tester.widget<AnimatedPositioned>(pill).duration.inMilliseconds,
      180,
    );

    final home = tester.getRect(pill);

    await tester.tap(find.text(K.tab(TpTab.you).tr()));
    await tester.pumpAndSettle();

    expect(tester.getRect(pill).left, greaterThan(home.left));
    expect(find.byKey(const ValueKey<String>('tab-pill')), findsOneWidget);
  });
}
