import 'dart:async';

import 'package:techpicks/app/theme/tp_motion.dart';
import 'package:techpicks/shared/coach/tp_coach.dart';

/// 모든 테스트 공통. 끝없이 도는 모션을 끈다 — 하나라도 돌면 `pumpAndSettle` 이
/// 끝나지 않는다. 반복 자체는 `motion_test` 가 이 값을 켜고 따로 본다.
///
/// 화면 안 안내도 끈다. 켜 두면 첫 방문마다 막이 떠서 다른 테스트의 탭을
/// 가로챈다. 안내는 `coach_test` 가 켜고 본다.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TpMotion.loopsAllowed = false;
  TpCoach.enabled = false;
  await testMain();
}
