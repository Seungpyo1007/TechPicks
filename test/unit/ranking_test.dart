import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/dto/score.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/domain/model/tp_weights.dart';

Smartphone _phone(
  String slug, {
  double? perf,
  double? cam,
  double? batt,
  double? val,
  int? usd,
}) => Smartphone(
  slug: slug,
  name: slug,
  msrpUsd: usd,
  score: SmartphoneScore(
    performance: perf,
    camera: cam,
    battery: batt,
    display: 50,
    value: val,
  ),
);

void main() {
  group('Ranking', () {
    final devices = <Smartphone>[
      _phone('a', perf: 90, cam: 40, batt: 60, val: 30, usd: 1200),
      _phone('b', perf: 60, cam: 90, batt: 80, val: 70, usd: 700),
      _phone('c', perf: 75, cam: 60, batt: 40, val: 90, usd: 400),
    ];

    test('TP Index 로 내림차순', () {
      // b 70.5 · c 60.75 · a 57.5
      final r = Ranking.of(devices, RankAxis.tpIndex);
      expect(r.map((e) => e.device.slug), <String>['b', 'c', 'a']);
      expect(r.first.position, 1);
      expect(r.last.position, 3);
    });

    test('축을 바꾸면 순서가 바뀐다', () {
      expect(
        Ranking.of(devices, RankAxis.camera).map((e) => e.device.slug),
        <String>['b', 'c', 'a'],
      );
      expect(
        Ranking.of(devices, RankAxis.battery).map((e) => e.device.slug),
        <String>['b', 'a', 'c'],
      );
    });

    test('가격은 싼 쪽이 위', () {
      final r = Ranking.of(devices, RankAxis.price);
      expect(r.map((e) => e.device.slug), <String>['c', 'b', 'a']);
    });

    test('긴 막대가 항상 더 좋음을 뜻한다', () {
      // 내림차순 축: 최고값이 가득
      final cam = Ranking.of(devices, RankAxis.camera);
      expect(cam.first.fraction, 1);
      expect(cam.last.fraction, closeTo(40 / 90, 1e-9));

      // 가격은 값이 작을수록 좋으므로 최저가가 가득 찬다
      final price = Ranking.of(devices, RankAxis.price);
      expect(price.first.device.slug, 'c');
      expect(price.first.fraction, 1);
      expect(price.last.fraction, closeTo(400 / 1200, 1e-9));
    });

    test('값 없는 기기는 뒤로 밀리되 사라지지 않는다', () {
      final withGap = <Smartphone>[
        ...devices,
        _phone('no-price', perf: 99, cam: 99, batt: 99, val: 99),
      ];
      final r = Ranking.of(withGap, RankAxis.price);

      expect(r, hasLength(4));
      expect(r.last.device.slug, 'no-price');
      expect(r.last.axisValue, isNull);
      expect(r.last.fraction, 0);
    });

    test('값이 다 없으면 이름순으로 안정된다', () {
      final none = <Smartphone>[_phone('z'), _phone('m'), _phone('a')];
      final r = Ranking.of(none, RankAxis.price);
      expect(r.map((e) => e.device.slug), <String>['a', 'm', 'z']);
    });

    test('축과 무관하게 TP Index 를 항상 들고 있다', () {
      final r = Ranking.of(devices, RankAxis.price);
      expect(r.every((e) => e.index != null), isTrue);
    });

    test('가중치를 바꾸면 index 축 순서가 바뀐다', () {
      const camOnly = TpWeights(
        performance: 0,
        camera: 1,
        display: 0,
        battery: 0,
        value: 0,
      );
      final r = Ranking.of(devices, RankAxis.tpIndex, camOnly);
      expect(r.map((e) => e.device.slug), <String>['b', 'c', 'a']);
    });

    test('빈 목록도 터지지 않는다', () {
      expect(Ranking.of(const <Smartphone>[], RankAxis.tpIndex), isEmpty);
    });
  });
}
