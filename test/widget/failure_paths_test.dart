import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/feature/ask/ask_screen.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/compare/picker_screen.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/home/home_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 카탈로그 애셋이 없을 때.
///
/// 애셋이 빠진 빌드, 파일 손상, 경로 오타 어느 쪽이든 화면이 죽으면 안 된다.

void main() {
  setUp(initLocalization);

  testWidgets('랭킹은 빈 목록을 보여준다', (tester) async {
    await pumpScreen(tester, const RankScreen(),
        catalogAsset: missingCatalogAsset);
    // 실패는 비동기로 전파된다. 한 프레임 더 돌린다.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(K.noDevices.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('홈은 빈 shortlist 상태로 떨어진다', (tester) async {
    await pumpScreen(tester, const HomeScreen(),
        catalogAsset: missingCatalogAsset);

    expect(find.text(K.emptyShortlist.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('비교는 고르라고 안내한다', (tester) async {
    await pumpScreen(tester, const CompareScreen(),
        catalogAsset: missingCatalogAsset);

    expect(find.text(K.chooseTwo.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('선택 시트는 빈 목록으로 뜬다', (tester) async {
    await pumpScreen(tester, const PickerScreen(),
        catalogAsset: missingCatalogAsset);

    expect(find.text(K.choose.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('상세는 못 불러왔다고 알린다', (tester) async {
    // 카탈로그가 없으면 원격으로 넘어가는데 테스트에서는 그것도 실패한다.
    await pumpScreen(tester, const DetailScreen(slug: 'galaxy-s25'),
        catalogAsset: missingCatalogAsset);

    expect(find.text(K.loadFailed.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('상담은 보내도 터지지 않는다', (tester) async {
    await pumpScreen(
      tester,
      const AskScreen(),
      size: const Size(1200, 2400),
      catalogAsset: missingCatalogAsset,
      overrides: <Override>[
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );

    await tester.enterText(find.byType(TextField), '뭐가 좋아?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // 카탈로그를 못 읽으면 답할 수 없다. 조용히 죽는 대신 안내를 띄운다.
    expect(find.text(K.askFailed.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
