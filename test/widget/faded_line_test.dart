import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/widgets/tp_faded_line.dart';

import '../support/harness.dart';

/// 한 줄은 넘칠 때만 흐려진다.
///
/// 조건 없이 흐리면 ShaderMask 가 글자 폭에 맞춰 그러데이션을 걸어, 다 들어간
/// 줄의 끝 글자까지 사라져 보인다. 관심 목록의 "$799 · Dimensity 9500" 이
/// 시뮬레이터에서 그렇게 보였다.
void main() {
  setUp(initLocalization);

  Future<void> pumpIn(WidgetTester tester, double width) => pumpScreen(
    tester,
    Center(
      child: SizedBox(
        width: width,
        child: const TpFadedLine(text: r'$799  ·  Dimensity 9500'),
      ),
    ),
    size: const Size(600, 400),
  );

  testWidgets('다 들어가면 안 흐린다', (tester) async {
    await pumpIn(tester, 400);

    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('넘치면 흐린다', (tester) async {
    await pumpIn(tester, 60);

    expect(find.byType(ShaderMask), findsOneWidget);
  });
}
