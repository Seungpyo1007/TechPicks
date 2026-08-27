import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/widgets/tp_pressable.dart';

import '../support/harness.dart';

/// 눌림이 손가락을 따라오는가.
///
/// 여태는 셋 다 아니었다. 스크롤 안에서 눌림이 100ms 늦게 시작했고, 톡 치면
/// 아예 시작조차 안 했고, 중간에 놓으면 남은 거리를 제 시간 다 써서 기어왔다.
void main() {
  setUp(initLocalization);

  /// 목록 안에 눌리는 상자 하나. 실제 화면의 조건(스크롤 안)과 같다.
  Widget host({VoidCallback? onTap, ValueChanged<double>? onValue}) => ListView(
    children: <Widget>[
      const SizedBox(height: 200),
      TpPressable(
        onTap: onTap ?? () {},
        haptic: TpHaptic.none,
        builder: (context, t, child) {
          onValue?.call(t);
          return Opacity(opacity: 1 - t * 0.5, child: child);
        },
        child: const SizedBox(height: 120, child: Text('눌러')),
      ),
      const SizedBox(height: 1200),
    ],
  );

  double pressed(WidgetTester tester) =>
      1 - tester.widget<Opacity>(find.byType(Opacity)).opacity;

  testWidgets('스크롤 안에서도 손가락이 닿자마자 눌린다', (tester) async {
    await pumpScreen(tester, host());

    final press = await tester.startGesture(tester.getCenter(find.text('눌러')));
    // 첫 프레임은 티커를 시작만 하고 값은 그 다음 프레임부터 움직인다.
    // 둘 합쳐 32ms — 예전에는 아레나 데드라인(100ms) 전이라 여기서 아무 일도
    // 일어나지 않았다.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(pressed(tester), greaterThan(0));

    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('톡 치고 떼도 눌림이 보인다', (tester) async {
    var taps = 0;
    await pumpScreen(tester, host(onTap: () => taps++));

    // 60ms 면 탭 데드라인보다 짧다. 예전에는 down 과 up 이 같은 프레임에
    // 처리돼서 애니메이션이 시작조차 안 했다.
    final press = await tester.startGesture(tester.getCenter(find.text('눌러')));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 60));
    await press.up();

    await tester.pump(const Duration(milliseconds: 16));
    expect(pressed(tester), greaterThan(0), reason: '눌린 게 보여야 한다');

    await tester.pumpAndSettle();
    expect(pressed(tester), 0);
    expect(taps, 1);
  });

  testWidgets('중간에 놓으면 간 만큼만 돌아온다', (tester) async {
    await pumpScreen(tester, host());

    final press = await tester.startGesture(tester.getCenter(find.text('눌러')));
    // 90ms 중 30ms 만 내려간다.
    await tester.pump(const Duration(milliseconds: 30));
    await press.up();

    // 다 내려갔다가(남은 60ms) 올라온다. 전부 합쳐도 뗄 때 시간(180ms)을
    // 통째로 쓰는 것보다 짧아야 한다.
    var frames = 0;
    while (pressed(tester) > 0 && frames < 40) {
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    expect(pressed(tester), 0);
    expect(frames * 16, lessThan(300));
  });

  testWidgets('스크롤을 시작하면 눌림이 풀리고 탭도 안 된다', (tester) async {
    var taps = 0;
    await pumpScreen(tester, host(onTap: () => taps++));

    final press = await tester.startGesture(tester.getCenter(find.text('눌러')));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(pressed(tester), greaterThan(0));

    await press.moveBy(const Offset(0, -60));
    await tester.pump(const Duration(milliseconds: 16));

    await press.up();
    await tester.pumpAndSettle();
    expect(pressed(tester), 0);
    expect(taps, 0, reason: '끌었으면 누른 게 아니다');
  });

  testWidgets('길게 눌러도 손을 뗄 때까지 눌린 채로 있다', (tester) async {
    await pumpScreen(
      tester,
      ListView(
        children: <Widget>[
          TpPressable(
            onTap: () {},
            onLongPress: () {},
            haptic: TpHaptic.none,
            builder: (context, t, child) =>
                Opacity(opacity: 1 - t * 0.5, child: child),
            child: const SizedBox(height: 120, child: Text('눌러')),
          ),
        ],
      ),
    );

    final press = await tester.startGesture(tester.getCenter(find.text('눌러')));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 700));
    // 예전에는 길게 누르면 탭 인식기가 아레나에서 져서 onTapCancel 이 오고,
    // 손가락이 아직 붙어 있는데 눌림이 풀렸다.
    expect(pressed(tester), greaterThan(0));

    await press.up();
    await tester.pumpAndSettle();
    expect(pressed(tester), 0);
  });

  testWidgets('안쪽을 누르면 바깥은 안 눌린다', (tester) async {
    await pumpScreen(
      tester,
      TpPressable(
        onTap: () {},
        haptic: TpHaptic.none,
        builder: (context, t, child) =>
            Opacity(key: const Key('바깥'), opacity: 1 - t * 0.5, child: child),
        child: Center(
          child: TpPressable(
            onTap: () {},
            haptic: TpHaptic.none,
            builder: (context, t, child) => Opacity(
              key: const Key('안쪽'),
              opacity: 1 - t * 0.5,
              child: child,
            ),
            child: const SizedBox(height: 80, width: 200, child: Text('안')),
          ),
        ),
      ),
    );

    final press = await tester.startGesture(tester.getCenter(find.text('안')));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 30));

    double at(String key) =>
        1 - tester.widget<Opacity>(find.byKey(Key(key))).opacity;
    expect(at('안쪽'), greaterThan(0));
    expect(at('바깥'), 0);

    await press.up();
    await tester.pumpAndSettle();
  });

  testWidgets('동작 줄이기에서는 타이머가 안 남는다', (tester) async {
    await pumpScreen(tester, host(), disableAnimations: true);

    final press = await tester.startGesture(tester.getCenter(find.text('눌러')));
    await tester.pump();
    await press.up();
    // 시간이 0 이라 상태 콜백이 같은 호출 안에서 돌아온다. 재진입하면
    // 여기서 스택이 터지거나 타이머가 남는다.
    await tester.pumpAndSettle();
    expect(pressed(tester), 0);
  });
}
