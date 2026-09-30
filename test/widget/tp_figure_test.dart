import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/tp_sys.dart';
import 'package:techpicks/shared/figures/tp_figure.dart';
import 'package:techpicks/shared/figures/tp_figures.dart';

import '../support/harness.dart';

/// 마지막으로 그린 진행도.
double? _last;

void _record(Canvas canvas, Size size, double t, TpSys sys) => _last = t;

Widget _figure({bool active = true}) => TpFigure(
  height: 40,
  active: active,
  duration: const Duration(milliseconds: 400),
  paint: _record,
);

void main() {
  setUp(() async {
    _last = null;
    await initLocalization();
  });

  testWidgets('한 번 재생하고 끝 프레임에서 멈춘다', (tester) async {
    await pumpScreenNoSettle(tester, _figure());
    await tester.pump(const Duration(milliseconds: 200));
    expect(_last, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(_last, 1);
  });

  testWidgets('활성이 되기 전에는 첫 프레임, 되면 처음부터', (tester) async {
    await pumpScreen(tester, _figure(active: false));
    expect(_last, 0);
    await pumpScreenNoSettle(tester, _figure());
    await tester.pump(const Duration(milliseconds: 100));
    expect(_last, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(_last, 1);
  });

  testWidgets('동작을 줄이면 끝 프레임만 그린다', (tester) async {
    await pumpScreenNoSettle(tester, _figure(), disableAnimations: true);
    await tester.pump();
    expect(_last, 1);
  });

  // 그림마다 처음·중간·끝에서 예외 없이 그린다. 다크도.
  for (final dark in <bool>[false, true]) {
    for (final entry in <String, TpFigurePaint>{
      'index': TpFigures.index,
      'compare': TpFigures.compare,
      'ask': TpFigures.ask,
      'shortlist': TpFigures.shortlist,
      'search': TpFigures.search,
      'offline': TpFigures.offline,
    }.entries) {
      testWidgets('${entry.key} 그림 · ${dark ? '다크' : '라이트'}', (tester) async {
        await pumpScreenNoSettle(
          tester,
          SizedBox(
            width: 320,
            child: TpFigure(height: 120, paint: entry.value),
          ),
          dark: dark,
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 130));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
