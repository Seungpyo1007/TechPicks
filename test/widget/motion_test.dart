import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/app/theme/tp_motion.dart';
import 'package:techpicks/feature/scan/scan_screen.dart';

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
