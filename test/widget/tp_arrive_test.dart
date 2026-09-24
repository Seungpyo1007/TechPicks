import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/widgets/tp_arrive.dart';
import 'package:techpicks/shared/widgets/tp_group.dart';
import 'package:techpicks/shared/widgets/tp_page.dart';

import '../support/harness.dart';

Widget _page() => TpPage(
  title: 'T',
  slivers: <Widget>[
    SliverToBoxAdapter(
      child: TpGroup(
        children: <Widget>[
          for (var i = 0; i < 5; i++)
            TpRow(title: 'row $i', value: '${70 + i}'),
        ],
      ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TpTrack(value: .8),
      ),
    ),
  ],
);

/// 지금 들어오고 있는 행.
Iterable<FadeTransition> _arriving(WidgetTester tester) => tester
    .widgetList<FadeTransition>(
      find.descendant(
        of: find.byType(TpArrive),
        matching: find.byType(FadeTransition),
      ),
    )
    .where((f) => f.opacity.value < 1);

double _fill(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(
      find.descendant(
        of: find.byType(TpTrack),
        matching: find.byType(FractionallySizedBox),
      ),
    )
    .widthFactor!;

void main() {
  setUp(initLocalization);

  testWidgets('화면이 나타나면 행이 차례로 들어오고 막대가 0 에서 찬다', (tester) async {
    await pumpScreenNoSettle(tester, _page());
    await tester.pump(const Duration(milliseconds: 40));
    expect(_arriving(tester), isNotEmpty);
    expect(_fill(tester), lessThan(.8));

    await tester.pumpAndSettle();
    expect(_arriving(tester), isEmpty);
    expect(_fill(tester), closeTo(.8, .01));
  });

  testWidgets('나중에 다시 그려져도 또 들어오지 않는다', (tester) async {
    await pumpScreen(tester, _page());
    await pumpScreenNoSettle(tester, _page());
    await tester.pump(const Duration(milliseconds: 40));
    expect(_arriving(tester), isEmpty);
  });

  testWidgets('동작을 줄이면 그냥 그 자리에 있다', (tester) async {
    await pumpScreenNoSettle(tester, _page(), disableAnimations: true);
    await tester.pump();
    expect(_arriving(tester), isEmpty);
    expect(_fill(tester), closeTo(.8, .001));
  });
}
