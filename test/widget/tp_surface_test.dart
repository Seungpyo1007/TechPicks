import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/shared/widgets/tp_surface.dart';

import '../support/harness.dart';

/// 카드 누름 피드백.
///
/// 명세 Interactions 는 두 플랫폼에 다른 걸 준다 — iOS 밝기 +4%,
/// Android M3 리플. 리플을 유리 위에 얹으면 안 맞는다.
void main() {
  setUp(initLocalization);

  Widget card(VoidCallback? onTap, {VoidCallback? onLongPress}) => Center(
    child: TpSurface(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: const EdgeInsets.all(20),
      child: const Text('카드'),
    ),
  );

  testWidgets('iOS 는 누르는 동안 밝아진다', (tester) async {
    await pumpScreen(tester, card(() {}), chrome: TpChrome.ios);

    expect(find.byType(ColorFiltered), findsNothing);
    expect(find.byType(InkWell), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('카드')),
    );
    // 밝기가 트윈된다. 시작 프레임은 아직 0 이라 필터가 없다.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    expect(find.byType(ColorFiltered), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('Android 는 리플을 쓴다', (tester) async {
    await pumpScreen(tester, card(() {}), chrome: TpChrome.android);

    expect(find.byType(InkWell), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('카드')),
    );
    await tester.pump();
    expect(find.byType(ColorFiltered), findsNothing);
    await gesture.up();
  });

  testWidgets('누를 수 없는 카드는 피드백도 없다', (tester) async {
    await pumpScreen(tester, card(null), chrome: TpChrome.ios);

    expect(find.byType(ColorFiltered), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('두 크롬 다 탭이 전달된다', (tester) async {
    for (final chrome in TpChrome.values) {
      var taps = 0;
      await pumpScreen(tester, card(() => taps++), chrome: chrome);
      await tester.tap(find.text('카드'));
      await tester.pumpAndSettle();
      expect(taps, 1, reason: '$chrome');
    }
  });

  testWidgets('두 크롬 다 길게 누르기가 전달된다', (tester) async {
    for (final chrome in TpChrome.values) {
      var held = 0;
      await pumpScreen(
        tester,
        card(() {}, onLongPress: () => held++),
        chrome: chrome,
      );
      await tester.longPress(find.text('카드'));
      await tester.pumpAndSettle();
      expect(held, 1, reason: '$chrome');
    }
  });

  testWidgets('길게 누르기만 있어도 반응한다', (tester) async {
    var held = 0;
    await pumpScreen(
      tester,
      card(null, onLongPress: () => held++),
      chrome: TpChrome.ios,
    );
    await tester.longPress(find.text('카드'));
    await tester.pumpAndSettle();
    expect(held, 1);
  });

  testWidgets('스크린 리더가 버튼으로 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, card(() {}), chrome: TpChrome.ios);

    expect(
      tester.getSemantics(find.byType(TpSurface)),
      matchesSemantics(hasTapAction: true, isButton: true, label: '카드'),
    );
    handle.dispose();
  });
}
