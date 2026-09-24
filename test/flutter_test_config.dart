import 'dart:async';

import 'package:techpicks/app/theme/tp_motion.dart';

/// 모든 테스트 공통. 끝없이 도는 모션을 끈다 — 하나라도 돌면 `pumpAndSettle` 이
/// 끝나지 않는다. 반복 자체는 `motion_test` 가 이 값을 켜고 따로 본다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TpMotion.loopsAllowed = false;
  await testMain();
}
