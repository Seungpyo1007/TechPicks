import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/feature/viewer/viewer_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

const Size _frame = Size(402, 874);
const double _safeBottom = 34;

/// 인수 화면(3D 뷰어)은 화면을 통째로 쓴다.
///
/// 셸이 아래 안전 영역만큼 비워 두던 때, 어두운 화면 밑에 밝은 배경이 띠처럼
/// 남았다. 시뮬레이터에서 눈에 띄었다 — 넉넉한 테스트 캔버스에서는 안전
/// 영역이 0 이라 안 보인다.
void main() {
  setUp(initLocalization);

  Future<void> pumpViewer(WidgetTester tester, TpChrome chrome) async {
    tester.view.physicalSize = _frame;
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(
      top: 62,
      bottom: _safeBottom,
    );
    tester.view.padding = const FakeViewPadding(top: 62, bottom: _safeBottom);
    addTearDown(tester.view.reset);

    await pumpScreenNoSettle(
      tester,
      const ViewerScreen(deviceName: 'Galaxy S25'),
      chrome: chrome,
      size: _frame,
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final chrome in TpChrome.values) {
    testWidgets('$chrome: 뷰어가 아래 끝까지 어둡다', (tester) async {
      await pumpViewer(tester, chrome);

      final dark = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == ViewerScreen.background,
        ),
      );
      expect(dark.top, 0);
      expect(dark.bottom, _frame.height);
    });

    // 셸이 아래를 안 비우니 화면이 직접 홈 인디케이터를 피해야 한다.
    testWidgets('$chrome: 뷰어 안내가 홈 인디케이터를 피한다', (tester) async {
      await pumpViewer(tester, chrome);

      final note = tester.getRect(find.text(K.viewerNote.tr()));
      expect(note.bottom, lessThanOrEqualTo(_frame.height - _safeBottom));
    });
  }
}
