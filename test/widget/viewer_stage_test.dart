import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/feature/viewer/viewer_screen.dart';
import 'package:techpicks/feature/viewer/viewer_stage.dart';

import '../support/harness.dart';

const Size _frame = Size(402, 874);

ViewerStageState _stage(WidgetTester tester) =>
    tester.state<ViewerStageState>(find.byType(ViewerStage));

Future<void> _pumpViewer(WidgetTester tester, {bool reduce = false}) async {
  await pumpScreen(
    tester,
    const ViewerScreen(deviceName: 'Galaxy S25'),
    size: _frame,
    disableAnimations: reduce,
  );
}

void main() {
  setUp(initLocalization);

  testWidgets('세게 던져도 한계 안으로 돌아온다', (tester) async {
    await _pumpViewer(tester);
    await tester.fling(find.byType(ViewerStage), const Offset(400, 0), 3000);
    await tester.pumpAndSettle();
    expect(
      _stage(tester).yaw.abs(),
      lessThanOrEqualTo(ViewerStage.yawLimit + 1e-3),
    );
    expect(_stage(tester).yaw, greaterThan(0));
  });

  testWidgets('두 번 탭하면 정면으로', (tester) async {
    await _pumpViewer(tester);
    await tester.drag(find.byType(ViewerStage), const Offset(60, 30));
    await tester.pumpAndSettle();
    expect(_stage(tester).yaw, isNot(0));

    final center = tester.getCenter(find.byType(ViewerStage));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(_stage(tester).yaw, closeTo(0, 1e-3));
    expect(_stage(tester).pitch, closeTo(0, 1e-3));
  });

  testWidgets('부품을 고르면 벌어지고 다시 누르면 합쳐진다', (tester) async {
    await _pumpViewer(tester);
    expect(_stage(tester).explode, 0);

    await tester.tap(find.text(ViewerScreen.partKeys[1].tr()));
    await tester.pumpAndSettle();
    expect(_stage(tester).explode, closeTo(1, 1e-3));
    expect(_stage(tester).yaw, closeTo(ViewerStage.explodedYaw, 1e-3));

    await tester.tap(find.text(ViewerScreen.partKeys[1].tr()));
    await tester.pumpAndSettle();
    expect(_stage(tester).explode, closeTo(0, 1e-3));
    expect(_stage(tester).yaw, closeTo(0, 1e-3));
  });

  testWidgets('동작을 줄이면 돌지도 벌어지지도 않는다', (tester) async {
    await _pumpViewer(tester, reduce: true);
    await tester.drag(find.byType(ViewerStage), const Offset(120, 0));
    await tester.tap(find.text(ViewerScreen.partKeys[3].tr()));
    await tester.pumpAndSettle();
    expect(_stage(tester).yaw, 0);
    expect(_stage(tester).explode, 0);
  });

  testWidgets('무대가 기기 이름과 고른 부품을 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpViewer(tester);
    await tester.tap(find.text(ViewerScreen.partKeys[3].tr()));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Galaxy S25, ${ViewerScreen.partKeys[3].tr()}'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
