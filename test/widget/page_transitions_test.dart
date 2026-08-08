import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/app/theme/page_transitions.dart';

import '../support/harness.dart';

/// 화면을 밀어 올릴 때의 전환.
///
/// 명세 Interactions — iOS 는 오른쪽에서 슬라이드, Android 는 shared axis X.
void main() {
  setUp(initLocalization);

  PageTransitionsBuilder builderFor(TpChrome chrome, TargetPlatform platform) =>
      AppTheme.of(chrome).pageTransitionsTheme.builders[platform]!;

  test('크롬이 전환을 정한다', () {
    // 호스트 OS 가 아니라 크롬을 따라야 한다. 데스크톱에서 iOS 크롬으로
    // 대조할 때 전환만 Android 로 남으면 비교가 안 된다.
    for (final platform in TargetPlatform.values) {
      expect(
        builderFor(TpChrome.ios, platform),
        isA<CupertinoPageTransitionsBuilder>(),
        reason: '$platform',
      );
      expect(
        builderFor(TpChrome.android, platform),
        isA<SharedAxisXPageTransitionsBuilder>(),
        reason: '$platform',
      );
    }
  });

  test('shared axis X 는 300ms 다', () {
    expect(
      const SharedAxisXPageTransitionsBuilder().transitionDuration,
      const Duration(milliseconds: 300),
    );
  });

  testWidgets('Android 는 밀려 들어오며 나타난다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(TpChrome.android),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const Text('다음'))),
            child: const Text('밀기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('밀기'));
    await tester.pump();
    // 전환 중간. 아직 제자리가 아니고 아직 불투명하지도 않다.
    await tester.pump(const Duration(milliseconds: 150));

    final opacity = tester.widgetList<Opacity>(find.byType(Opacity));
    expect(opacity, isNotEmpty);
    expect(opacity.any((o) => o.opacity > 0 && o.opacity < 1), isTrue);

    await tester.pumpAndSettle();
    expect(find.text('다음'), findsOneWidget);
  });

  testWidgets('전환이 끝나면 제자리에 온전히 선다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.of(TpChrome.android),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const Text('다음'))),
            child: const Text('밀기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('밀기'));
    await tester.pumpAndSettle();

    for (final o in tester.widgetList<Opacity>(find.byType(Opacity))) {
      expect(o.opacity, 1);
    }
  });
}
