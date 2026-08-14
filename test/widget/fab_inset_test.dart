import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// Android 크롬의 랭킹은 확장 FAB 을 띄운다.
///
/// 셸이 그만큼 아래를 안 비우면 목록 끝 문구가 FAB 뒤에 영영 숨는다 —
/// 스크롤을 끝까지 내려도 안 나온다. 시뮬레이터에서 실제로 그랬다.
void main() {
  setUp(initLocalization);

  testWidgets('FAB 이 목록 끝 문구를 가리지 않는다', (tester) async {
    // 실제 기기 크기. 넉넉한 캔버스에서는 이 문제가 안 보인다.
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 24);
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 24);
    addTearDown(tester.view.reset);

    await pumpScreen(
      tester,
      RankScreen(onScan: () {}),
      chrome: TpChrome.android,
      size: const Size(412, 892),
    );

    final note = find.text(K.rankNote.tr());
    await tester.scrollUntilVisible(
      note,
      400,
      scrollable: find
          .descendant(
            of: find.byType(RankScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    // FAB 과 문구가 겹치면 그 문구는 못 읽는다.
    final fab = tester.getRect(find.text(K.scanShort.tr()));
    expect(tester.getRect(note).overlaps(fab), isFalse);
  });
}
