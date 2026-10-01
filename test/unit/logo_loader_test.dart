import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/shared/brand/tp_logo.dart';

/// 앱의 모든 기다림에 쓰는 로고 로더.
void main() {
  test('막대 하나는 차올랐다가 머물고 비워진다', () {
    expect(TpLogoLoader.fillAt(0), closeTo(.06, 1e-9));
    expect(TpLogoLoader.fillAt(.6), 1);
    expect(TpLogoLoader.fillAt(.99), lessThan(.2));
    // 한 주기가 지나면 같은 자리.
    expect(TpLogoLoader.fillAt(1.3), closeTo(TpLogoLoader.fillAt(.3), 1e-9));
  });

  test('차오르는 동안은 줄지 않는다', () {
    var last = 0.0;
    for (var t = 0.0; t < .55; t += .01) {
      final f = TpLogoLoader.fillAt(t);
      expect(f, greaterThanOrEqualTo(last));
      last = f;
    }
  });

  testWidgets('두 크롬에서 그려지고 스크린 리더에는 숨는다', (tester) async {
    for (final chrome in TpChrome.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.of(chrome),
          home: const Center(child: TpLogoLoader(size: 48)),
        ),
      );
      expect(tester.getSize(find.byType(TpLogoLoader)), const Size(48, 48));
      expect(
        find.descendant(
          of: find.byType(TpLogoLoader),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    }
  });
}
