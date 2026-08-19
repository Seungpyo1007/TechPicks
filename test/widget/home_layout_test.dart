import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/feature/home/home_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:techpicks/shared/widgets/tp_faded_line.dart';

import '../support/harness.dart';

/// 홈의 자리 배치.
///
/// 이 화면의 알맹이는 **한 번도 검사된 적이 없었다.** 하네스가 저장소를 비워서
/// 레이아웃·글자 배율·접근성 스윕이 전부 "관심 목록이 비어 있습니다" 카드
/// 하나만 보고 지나갔다. 결론 카드도, 관심목록 행도, 변동 행도 402×874 에서
/// 그려진 적이 없고 1.6배에서는 더더욱 없었다.
///
/// 그리고 여기 있는 것들은 **예외를 안 낸다** — 넘침 예외만 보는 스윕으로는
/// 못 잡는다. `Text` 는 자기 상자를 넘어도 조용히 자르고, 고정 폭 상자 안의
/// 숫자는 글리프 한가운데서 끊긴다.
void main() {
  setUp(initLocalization);
  setUp(seedHomeContent);

  const frames = <TpChrome, Size>{
    TpChrome.ios: Size(402, 874),
    TpChrome.android: Size(412, 892),
  };

  /// [finder] 의 글자가 제 상자 안에 다 들어갔는가.
  ///
  /// `Text` 가 잘렸는지는 렌더 오브젝트의 `didExceedMaxLines` 로도 못 본다 —
  /// 한 줄로 묶어 뒀으니 줄 수는 안 넘는다. 대신 글자가 원하는 폭과 실제로
  /// 받은 폭을 잰다.
  void expectFits(WidgetTester tester, Finder finder, {required String why}) {
    for (final element in finder.evaluate()) {
      final box = element.renderObject! as RenderBox;
      final text = element.widget as Text;
      final painter = TextPainter(
        text: TextSpan(text: text.data, style: text.style),
        textDirection: ui.TextDirection.ltr,
        maxLines: text.maxLines,
        textScaler: MediaQuery.textScalerOf(element),
      )..layout();
      expect(
        painter.width,
        lessThanOrEqualTo(box.size.width + 0.5),
        reason: '$why — "${text.data}"',
      );
      painter.dispose();
    }
  }

  for (final scale in <double>[1, 1.6]) {
    for (final entry in frames.entries) {
      final label = '${entry.key.name} · 배율 $scale';

      testWidgets('결론 카드의 지수 숫자가 안 잘린다 · $label', (tester) async {
        await pumpScreen(
          tester,
          HomeScreen(onDeviceTap: (_) {}, onAdd: () {}),
          chrome: entry.key,
          size: entry.value,
          textScale: scale,
        );

        // 62pt 숫자와 "TP Index" 라벨이 한 Row 에 있고 유연한 자식이 없었다.
        // 1.6배에서 둘을 합치면 카드 폭을 넘는다.
        expectFits(
          tester,
          find.text(K.tpIndex.tr()),
          why: 'TP Index 라벨이 잘린다',
        );
      });

      testWidgets('관심목록 행의 지수와 이름이 안 잘린다 · $label', (tester) async {
        await pumpScreen(
          tester,
          HomeScreen(onDeviceTap: (_) {}, onAdd: () {}),
          chrome: entry.key,
          size: entry.value,
          textScale: scale,
        );

        await tester.scrollUntilVisible(
          find.text(K.shortlist.tr()),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // 34pt 숫자가 52pt 상자에 있었다. 세 자리(100)는 배율 1.0 에서도
        // 안 들어가고, 두 자리도 1.6배면 넘는다.
        // TpFadedLine 은 빼둔다. 거기서 잘리는 것은 **설계**다 — 폭을 재고
        // 넘칠 때만 오른쪽을 흐린다.
        final numerals = find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byWidgetPredicate(
            (w) => w is Text && w.softWrap == false,
          ),
          matchRoot: false,
        );
        final outsideFade = find.descendant(
          of: find.byType(TpFadedLine),
          matching: numerals,
        );
        final faded = outsideFade.evaluate().map((e) => e.widget).toSet();
        expectFits(
          tester,
          find.byWidgetPredicate(
            (w) => w is Text && w.softWrap == false && !faded.contains(w),
          ),
          why: '고정 폭 상자 안의 숫자가 잘린다',
        );
      });
    }
  }

}
