import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/widgets/tp_number.dart';

import '../support/harness.dart';

Widget _number(String text) =>
    Center(child: TpNumber(text, style: const TextStyle(fontSize: 40)));

/// 지금 들어오고 있는 글자 [char] 의 세로 이동(자기 높이 비율).
double _incoming(WidgetTester tester, String char) {
  final translation = tester.widget<FractionalTranslation>(
    find
        .ancestor(
          of: find.text(char),
          matching: find.byType(FractionalTranslation),
        )
        .first,
  );
  return translation.translation.dy;
}

final Finder _rolling = find.descendant(
  of: find.byType(TpNumber),
  matching: find.byType(FractionalTranslation),
);

void main() {
  setUp(initLocalization);

  testWidgets('가만히 있으면 글자 하나다', (tester) async {
    await pumpScreen(tester, _number('74'));
    expect(find.text('74'), findsOneWidget);
    expect(_rolling, findsNothing);
  });

  testWidgets('바뀐 자리만 굴러가고 끝나면 새 값 하나만 남는다', (tester) async {
    await pumpScreen(tester, _number('74'));
    await pumpScreenNoSettle(tester, _number('78'));
    await tester.pump(const Duration(milliseconds: 60));

    // 십의 자리 7 은 그대로, 일의 자리만 4 → 8.
    expect(find.text('7'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.bySemanticsLabel('78'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('78'), findsOneWidget);
    expect(_rolling, findsNothing);
  });

  testWidgets('커지면 아래에서 올라오고 작아지면 위에서 내려온다', (tester) async {
    await pumpScreen(tester, _number('70'));
    await pumpScreenNoSettle(tester, _number('75'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_incoming(tester, '5'), greaterThan(0));
    await tester.pumpAndSettle();

    await pumpScreenNoSettle(tester, _number('72'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_incoming(tester, '2'), lessThan(0));
  });

  testWidgets('동작을 줄이면 바로 바뀐다', (tester) async {
    await pumpScreen(tester, _number('74'), disableAnimations: true);
    await pumpScreenNoSettle(tester, _number('81'), disableAnimations: true);
    await tester.pump();
    expect(find.text('81'), findsOneWidget);
    expect(_rolling, findsNothing);
  });
}
