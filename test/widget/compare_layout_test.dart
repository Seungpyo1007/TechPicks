import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/domain/model/tp_index.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:techpicks/shared/spec_labels.dart';
import 'package:techpicks/shared/widgets/tp_bar.dart';
import 'package:techpicks/shared/widgets/tp_shimmer.dart';

import '../support/harness.dart';

/// 비교 화면의 자리 배치.
///
/// 넘침 예외가 안 나는 것과 글자가 안 겹치는 것은 다른 일이다. 여기 있는
/// 것들은 전부 예외 없이 조용히 틀려 있던 것들이다.
void main() {
  setUp(initLocalization);

  testWidgets('글자를 키워도 열 머리가 아래 캡션을 덮지 않는다', (tester) async {
    // 예전에는 이름이 `SizedBox(height: 44)` 안에 있었다. 1.6배면 17pt 두 줄이
    // 54pt 라 상자를 10pt 넘어 "눌러서 바꾸기" 위에 겹쳐 그려졌다. 넘침
    // 예외는 안 난다 — Text 는 자기 상자를 넘어도 조용히 그린다.
    await pumpScreen(
      tester,
      const CompareScreen(),
      size: const Size(402, 874),
      textScale: 1.6,
    );

    final name = tester.getRect(find.text(readRanking()[0].device.name));
    final caption = tester.getRect(find.text(K.tapToChange.tr()).first);
    expect(name.bottom, lessThanOrEqualTo(caption.top));
  });

  testWidgets('마지막 줄에는 아래 선이 없다', (tester) async {
    await pumpScreen(
      tester,
      const CompareScreen(),
      size: const Size(1200, 3200),
    );

    // 표의 마지막 줄은 Released 다. 그 줄을 그리는 상자에 테두리가 있으면
    // 카드 안쪽에 선이 하나 떠 있게 된다.
    final decorations = tester
        .widgetList<Container>(
          find.ancestor(
            of: find.text(SpecLabels.of(SpecKind.released)),
            matching: find.byType(Container),
          ),
        )
        .map((c) => c.decoration)
        .whereType<BoxDecoration>();
    expect(decorations.where((d) => d.border != null), isEmpty);
  });

  testWidgets('이긴 칸은 셀 전체가 아니라 값만 감싼다', (tester) async {
    await pumpScreen(
      tester,
      const CompareScreen(),
      size: const Size(1200, 3200),
    );

    final ranked = readRanking();
    final a = ranked[0].device;
    final b = ranked[1].device;
    final cheaper = (a.msrpUsd ?? 0) <= (b.msrpUsd ?? 0) ? a : b;

    // 값 텍스트를 감싼 가장 가까운 칠해진 상자.
    final value = find.text(DeviceSpecs.formatPrice(cheaper.msrpUsd));
    final fill = tester.getRect(
      find.ancestor(of: value, matching: find.byType(AnimatedContainer)).first,
    );
    final cell = tester.getRect(
      find.ancestor(of: value, matching: find.byType(ConstrainedBox)).first,
    );

    // 예전에는 IntrinsicHeight + stretch 라 칠이 셀 높이를 통째로 채웠다.
    expect(fill.height, lessThan(cell.height));
    expect(fill.width, lessThan(cell.width));
  });

  testWidgets('승부를 못 가리는 세 줄만 점수 막대를 깐다', (tester) async {
    await pumpScreen(
      tester,
      const CompareScreen(),
      size: const Size(1200, 3200),
    );

    // (화면·프로세서·카메라) × 두 열. 열 머리는 TpTrack 이다.
    expect(find.byType(TpBar), findsNWidgets(6));
  });

  testWidgets('이유 물어보기 버튼이 없다', (tester) async {
    await pumpScreen(tester, const CompareScreen(), size: const Size(402, 874));
    expect(find.text(K.askWhy.tr()), findsNothing);
  });

  testWidgets('스켈레톤도 표처럼 좌우 16 을 띄운다', (tester) async {
    // 끝나지 않는 카탈로그. 읽는 중에 머문다.
    final never = Completer<Catalog>();
    await pumpScreenNoSettle(
      tester,
      const CompareScreen(),
      size: const Size(402, 874),
      overrides: <Override>[
        catalogProvider.overrideWith((ref) => never.future),
      ],
    );

    final skeleton = tester.getRect(find.byType(TpShimmer));
    expect(skeleton.left, 16);
    expect(skeleton.right, 402 - 16);
  });

  test('점수 막대는 승자를 못 가리는 줄에만 있다', () {
    // 표시할 승자가 있는 줄에까지 막대를 깔면 같은 것을 두 번 말한다.
    expect(SpecKind.screen.scoreAxis, TpAxisKind.display);
    expect(SpecKind.chipset.scoreAxis, TpAxisKind.performance);
    expect(SpecKind.camera.scoreAxis, TpAxisKind.camera);
    for (final kind in <SpecKind>[
      SpecKind.tpIndex,
      SpecKind.price,
      SpecKind.battery,
      SpecKind.os,
      SpecKind.weight,
      SpecKind.thickness,
      SpecKind.released,
    ]) {
      expect(kind.scoreAxis, isNull, reason: kind.name);
    }
  });
}
