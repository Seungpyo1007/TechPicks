import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/widgets/tp_toggle_loader.dart';

/// 질문 기다림 표시의 한 주기: 꺼짐 → 켜짐 → 머묾 → 꺼짐.
void main() {
  test('꺼진 채 시작해서 켜졌다가 다시 꺼진다', () {
    expect(TpToggleLoader.phase(0).at, 0);
    expect(TpToggleLoader.phase(.5).at, 1);
    expect(TpToggleLoader.phase(.97).at, 0);
  });

  test('움직이는 동안만 렌즈처럼 늘어난다', () {
    expect(TpToggleLoader.phase(.05).moving, 0);
    expect(TpToggleLoader.phase(.28).moving, greaterThan(.9));
    expect(TpToggleLoader.phase(.53).moving, 0);
    expect(TpToggleLoader.phase(.78).moving, greaterThan(.9));
  });

  test('가는 길은 한 방향으로만', () {
    var last = -1.0;
    for (var t = .12; t < .44; t += .01) {
      final at = TpToggleLoader.phase(t).at;
      expect(at, greaterThanOrEqualTo(last));
      last = at;
    }
  });
}
