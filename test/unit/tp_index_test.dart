import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/dto/score.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/domain/model/tp_index.dart';
import 'package:techpicks/domain/model/tp_weights.dart';

import '../fixtures/fixtures.dart';

void main() {
  group('TpIndex', () {
    test('명세의 기본 가중치 식과 일치한다', () {
      // idx = perf*.25 + cam*.25 + disp*.20 + batt*.20 + val*.10
      const score = SmartphoneScore(
        performance: 80,
        camera: 60,
        display: 90,
        battery: 70,
        value: 50,
      );
      // 20 + 15 + 18 + 14 + 5 = 72
      expect(TpIndex.of(score), 72);
    });

    test('가중치를 바꾸면 지수가 따라 움직인다', () {
      const score = SmartphoneScore(
        performance: 100,
        camera: 0,
        display: 50,
        battery: 50,
        value: 50,
      );
      expect(TpIndex.of(score), 50);

      // 카메라를 버리고 성능만 보면 지수가 올라간다.
      const perfOnly = TpWeights(
        performance: 1,
        camera: 0,
        display: 0,
        battery: 0,
        value: 0,
      );
      expect(TpIndex.of(score, perfOnly), 100);
    });

    test('빈 축은 0점이 아니라 계산에서 빠진다', () {
      // 성능만 있고 나머지가 비었다. 0점 처리하면 20 이 되어버린다.
      const partial = SmartphoneScore(performance: 80);
      expect(TpIndex.of(partial), 80);

      // 두 축만 있는 경우도 그 둘의 가중치로만 정규화한다.
      // (80*.25 + 60*.25) / .50 = 70
      const two = SmartphoneScore(performance: 80, camera: 60);
      expect(TpIndex.of(two), 70);
    });

    test('쓸 축이 없으면 null', () {
      expect(TpIndex.of(null), isNull);
      expect(TpIndex.of(const SmartphoneScore()), isNull);
      expect(TpIndex.of(const SmartphoneScore(overall: 60)), isNull,
          reason: 'overall 은 TechAPI 가 자기 가중치로 접은 값이라 쓰지 않는다');
    });

    test('가중치가 전부 0이면 null', () {
      const score = SmartphoneScore(performance: 80, camera: 60);
      const zero = TpWeights(
        performance: 0,
        camera: 0,
        display: 0,
        battery: 0,
        value: 0,
      );
      expect(TpIndex.of(score, zero), isNull);
    });

    test('실제 레코드 — galaxy-s25', () {
      final phone = Smartphone.fromJson(loadFixture('smartphone_galaxy_s25'));
      final idx = TpIndex.of(phone.score);

      // 88.9*.25 + 36.1*.25 + 63.8*.20 + 54.4*.20 + 59*.10 = 60.79
      expect(idx, 61);

      // 기본 가중치로 계산하면 TechAPI 의 overall 과 사실상 같은 값이 나온다.
      // TechAPI 도 같은 비중을 쓴다는 뜻이다. 그래도 앱에서 다시 계산하는 이유는
      // 사용자가 가중치를 바꿀 수 있어야 하기 때문이다. overall 은 고정값이다.
      expect(phone.score!.overall, closeTo(60.8, 0.01));
      expect((idx! - phone.score!.overall!).abs(), lessThan(1));
    });

    test('실제 레코드 — 축이 비어 있는 저가 기기', () {
      final phone = Smartphone.fromJson(loadFixture('smartphone_unscored'));
      final idx = TpIndex.of(phone.score);

      // performance 와 value 가 null 이라 나머지 셋으로만 계산된다.
      // (5*.25 + 35*.20 + 0*.20) / .65 = 12.69 -> 13
      expect(idx, 13);
      expect(phone.score!.performance, isNull);
      expect(phone.score!.value, isNull);
    });
  });

  group('TpAxis', () {
    test('명세 순서를 지킨다', () {
      final kinds = TpIndex.axes(null).map((a) => a.kind).toList();
      expect(kinds, <TpAxisKind>[
        TpAxisKind.performance,
        TpAxisKind.camera,
        TpAxisKind.display,
        TpAxisKind.battery,
        TpAxisKind.value,
      ]);
    });

    test('데이터 없음과 0점을 구분한다', () {
      final axes = TpIndex.axes(
        const SmartphoneScore(performance: 0, camera: null),
      );
      final perf = axes.firstWhere((a) => a.kind == TpAxisKind.performance);
      final cam = axes.firstWhere((a) => a.kind == TpAxisKind.camera);

      expect(perf.hasData, isTrue);
      expect(perf.fraction, 0);
      // 둘 다 fraction 은 0 이지만 의미가 다르다. 빈 트랙으로 그려야 한다.
      expect(cam.hasData, isFalse);
      expect(cam.fraction, 0);
    });

    test('100을 넘는 값도 트랙을 벗어나지 않는다', () {
      final axes = TpIndex.axes(const SmartphoneScore(performance: 140));
      expect(axes.first.fraction, 1);
    });
  });

  group('TpWeights', () {
    test('기본값 합이 1이다', () {
      expect(TpWeights.defaults.total, closeTo(1.0, 1e-9));
    });

    test('저장했다 읽으면 그대로다', () {
      const w = TpWeights(
        performance: 0.4,
        camera: 0.1,
        display: 0.2,
        battery: 0.2,
        value: 0.1,
      );
      expect(TpWeights.fromJson(w.toJson()), w);
    });

    test('깨진 값은 기본값으로 떨어진다', () {
      final w = TpWeights.fromJson(const <String, dynamic>{
        'performance': 'x',
        'camera': -1,
        'display': double.nan,
      });
      expect(w, TpWeights.defaults);
    });
  });
}
