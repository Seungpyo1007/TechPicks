import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:techpicks/shared/widgets/tp_button.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

/// 마우스와 키보드.
///
/// 이 앱은 손가락만 보고 만들어졌다. `TpPressable` 이 `GestureDetector` 위에
/// 있는데 그건 포커스를 못 받아서, **Tab 으로 닿는 것이 입력칸과 슬라이더
/// 하나뿐이었다** — 버튼도 칩도 카드도 탭도 키보드로는 쓸 수 없었다.
void main() {
  setUp(initLocalization);

  testWidgets('Tab 으로 화면 안을 돌 수 있다', (tester) async {
    await pumpApp(tester, size: const Size(1440, 900));

    final reached = <String>{};
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final node = FocusManager.instance.primaryFocus;
      if (node != null) reached.add('${node.hashCode}');
    }

    // 예전에는 여기가 0 이나 1 이었다.
    expect(reached.length, greaterThan(3));
  });

  testWidgets('Enter 로 누를 수 있다', (tester) async {
    var taps = 0;
    await pumpScreen(
      tester,
      Center(child: TpButton(label: '눌러', onTap: () => taps++)),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('Space 로도 누를 수 있다', (tester) async {
    var taps = 0;
    await pumpScreen(
      tester,
      Center(child: TpButton(label: '눌러', onTap: () => taps++)),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
