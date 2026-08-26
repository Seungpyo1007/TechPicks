import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';

/// 골든은 한 기계에서만 맞춘다.
///
/// 렌더링 결과는 같은 Flutter·같은 OS 에서만 바이트가 같다. 리눅스 CI 나
/// 윈도우에서 돌리면 안티에일리어싱과 블러가 미세하게 달라 전부 실패한다.
/// 그래서 macOS 밖에서는 건너뛴다 — 여기서 굽고 여기서 본다.
///
/// CI 에서도 돌리고 싶어지면 그때 컨테이너 이미지를 고정하고 그 안에서 다시
/// 구워야 한다. `flutter test --update-goldens` 를 아무 데서나 돌리면
/// 기준선이 그 기계 것으로 덮인다.
final bool _runsHere = Platform.isMacOS;

/// 명세 Chrome geometry 의 프레임. 크롬마다 다르다.
const Map<TpChrome, Size> _frame = <TpChrome, Size>{
  TpChrome.ios: Size(402, 874),
  TpChrome.android: Size(412, 892),
};

Size frameOf(TpChrome chrome) => _frame[chrome]!;

/// 한 시나리오를 두 크롬으로 한 번씩 굽는다.
///
/// [slug] 가 파일 이름이 되고 [label] 이 테스트 이름이 된다. 이미지는
/// `test/golden/goldens/<slug>_<chrome>.png` 다.
///
/// 크롬을 나누는 게 이 테스트의 전부다. 유리(iOS)와 톤(Android)은 같은
/// 위젯 트리에서 다른 그림이 나오는데, 위젯 테스트로는 그 차이가
/// `find.byType` 몇 개로밖에 안 잡힌다.
void goldenScenario(
  String slug,
  String label,
  Future<void> Function(WidgetTester tester, TpChrome chrome) body,
) {
  for (final chrome in TpChrome.values) {
    testWidgets('$label · ${chrome.name}', (tester) async {
      await body(tester, chrome);
      await expectGolden(tester, '${slug}_${chrome.name}');
    }, skip: !_runsHere);
  }
}

/// 지금 화면 전체를 [name].png 와 맞춘다.
Future<void> expectGolden(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}
