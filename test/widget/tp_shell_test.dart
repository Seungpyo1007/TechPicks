import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/shell/tp_shell.dart';
import 'package:techpicks/app/shell/tp_tab.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/app/theme/tp_tokens.dart';
import 'package:techpicks/app/theme/tp_typography.dart';

Widget _host(TpChrome chrome, Widget child) => MaterialApp(
      theme: AppTheme.of(chrome),
      home: child,
    );

void main() {
  group('테마', () {
    test('크롬은 플랫폼에서 정해진다', () {
      expect(TpChrome.forPlatform(TargetPlatform.iOS), TpChrome.ios);
      expect(TpChrome.forPlatform(TargetPlatform.macOS), TpChrome.ios);
      expect(TpChrome.forPlatform(TargetPlatform.android), TpChrome.android);
      // 데스크톱·웹은 유리 크롬을 흉내내지 않고 M3 쪽으로 떨어뜨린다.
      expect(TpChrome.forPlatform(TargetPlatform.windows), TpChrome.android);
    });

    test('두 크롬이 같은 팔레트를 쓴다', () {
      // 색은 앱 로고에서 뽑은 하나의 팔레트다. 플랫폼이 바꾸는 건 표현 방식뿐.
      expect(TpTokens.blue, const Color(0xFF0C78D8));
      expect(TpTokens.ios().barFill.colors.first, TpTokens.blue);
      expect(TpTokens.android().barFill.colors.first, TpTokens.blue);
    });

    test('iOS만 유리 효과를 쓴다', () {
      final ios = TpTokens.ios();
      final android = TpTokens.android();

      expect(ios.isGlass, isTrue);
      expect(ios.blurSigma, greaterThan(0));
      expect(ios.hasSpecular, isTrue);
      expect(ios.cardShadow, isNotEmpty);

      // M3는 반투명이 아니라 톤이다. 블러도 그림자도 스페큘러도 없다.
      expect(android.isGlass, isFalse);
      expect(android.blurSigma, 0);
      expect(android.hasSpecular, isFalse);
      expect(android.cardShadow, isEmpty);
    });

    test('동심 반지름 규칙 — 안쪽이 항상 더 작다', () {
      for (final t in <TpTokens>[TpTokens.ios(), TpTokens.android()]) {
        expect(t.rInner, lessThan(t.rCard));
      }
    });

    test('M3는 600 이상 굵기를 쓰지 않는다', () {
      final android = TpTypography.of(TpTokens.android());
      for (final s in <TextStyle>[
        android.largeTitle,
        android.cardTitle,
        android.indexNumeral,
        android.appBarTitle,
      ]) {
        expect(s.fontWeight!.value, lessThanOrEqualTo(FontWeight.w500.value));
      }

      final ios = TpTypography.of(TpTokens.ios());
      expect(ios.largeTitle.fontWeight, FontWeight.w700);
      expect(ios.cardTitle.fontWeight, FontWeight.w600);
    });
  });

  group('셸', () {
    for (final chrome in TpChrome.values) {
      testWidgets('$chrome — 탭 5개와 콘텐츠를 그린다', (tester) async {
        await tester.pumpWidget(_host(
          chrome,
          const TpShell(
            title: 'Today',
            tab: TpTab.home,
            child: Center(child: Text('본문')),
          ),
        ));

        expect(find.text('본문'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        for (final t in TpTab.values) {
          expect(find.text(t.key), findsOneWidget);
        }
      });

      testWidgets('$chrome — 탭을 누르면 콜백이 온다', (tester) async {
        TpTab? tapped;
        await tester.pumpWidget(_host(
          chrome,
          TpShell(
            tab: TpTab.home,
            onTabSelected: (t) => tapped = t,
            child: const SizedBox.shrink(),
          ),
        ));

        await tester.tap(find.text(TpTab.compare.key));
        expect(tapped, TpTab.compare);
      });

      testWidgets('$chrome — takeover는 크롬을 그리지 않는다', (tester) async {
        await tester.pumpWidget(_host(
          chrome,
          const TpShell(
            title: 'Scan',
            mode: TpChromeMode.takeover,
            child: Center(child: Text('뷰파인더')),
          ),
        ));

        expect(find.text('뷰파인더'), findsOneWidget);
        // 제목을 넘겨도 인수 화면에서는 헤더가 나오지 않는다.
        expect(find.text('Scan'), findsNothing);
        expect(find.byType(TpShell), findsOneWidget);
      });

      testWidgets('$chrome — 탭이 없으면 탭 바도 없다', (tester) async {
        await tester.pumpWidget(_host(
          chrome,
          const TpShell(
            title: '상세',
            child: SizedBox.shrink(),
          ),
        ));

        for (final t in TpTab.values) {
          expect(find.text(t.key), findsNothing);
        }
      });
    }

    testWidgets('Android만 FAB를 그린다', (tester) async {
      const fab = Text('비교하기');

      await tester.pumpWidget(_host(
        TpChrome.android,
        const TpShell(
          tab: TpTab.rank,
          floatingAction: fab,
          child: SizedBox.shrink(),
        ),
      ));
      expect(find.text('비교하기'), findsOneWidget);
    });
  });
}
