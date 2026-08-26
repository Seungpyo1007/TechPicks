import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/dto/score.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/dto/soc.dart';
import 'package:techpicks/domain/model/device_specs.dart';

Smartphone _phone(
  String slug, {
  int? usd,
  int? mah,
  double? perf,
  String? soc,
}) => Smartphone(
  slug: slug,
  name: slug,
  msrpUsd: usd,
  batteryMah: mah,
  soc: soc == null ? null : Soc(slug: soc, name: soc),
  score: SmartphoneScore(
    performance: perf,
    camera: 50,
    display: 50,
    battery: 50,
    value: 50,
  ),
);

void main() {
  group('DeviceComparison', () {
    test('열 줄을 명세 순서로 짝짓는다', () {
      final pairs = DeviceComparison.of(_phone('a'), _phone('b'));
      expect(pairs, hasLength(10));
      expect(pairs.first.kind, SpecKind.tpIndex);
      expect(pairs.last.kind, SpecKind.released);
    });

    test('지수와 배터리는 높은 쪽이 이긴다', () {
      final pairs = DeviceComparison.of(
        _phone('a', perf: 90, mah: 5000),
        _phone('b', perf: 50, mah: 4000),
      );
      final by = <SpecKind, SpecPair>{for (final p in pairs) p.kind: p};

      expect(by[SpecKind.tpIndex]!.winner, CompareSide.a);
      expect(by[SpecKind.battery]!.winner, CompareSide.a);
    });

    test('가격은 싼 쪽이 이긴다', () {
      final pairs = DeviceComparison.of(
        _phone('a', usd: 1200),
        _phone('b', usd: 700),
      );
      final price = pairs.firstWhere((p) => p.kind == SpecKind.price);
      expect(price.winner, CompareSide.b);
    });

    test('같으면 아무도 안 이긴다', () {
      final pairs = DeviceComparison.of(
        _phone('a', usd: 999),
        _phone('b', usd: 999),
      );
      final price = pairs.firstWhere((p) => p.kind == SpecKind.price);
      expect(price.winner, isNull);
      expect(price.isTie, isTrue);
    });

    test('한쪽만 값이 있으면 표시하지 않는다', () {
      // 없는 값은 나쁜 값이 아니라 모르는 값이다.
      final pairs = DeviceComparison.of(_phone('a', usd: 700), _phone('b'));
      final price = pairs.firstWhere((p) => p.kind == SpecKind.price);
      expect(price.winner, isNull);
    });

    test('문자열 줄은 비교하지 않는다', () {
      final pairs = DeviceComparison.of(
        _phone('a', soc: 'Snapdragon 8 Elite'),
        _phone('b', soc: 'Tensor G4'),
      );
      for (final kind in <SpecKind>[
        SpecKind.screen,
        SpecKind.chipset,
        SpecKind.camera,
        SpecKind.os,
        SpecKind.weight,
        SpecKind.thickness,
        SpecKind.released,
      ]) {
        expect(
          pairs.firstWhere((p) => p.kind == kind).winner,
          isNull,
          reason: '$kind 는 데이터만으로 우열을 정할 수 없다',
        );
      }
    });

    test('양쪽 값을 그대로 들고 있다', () {
      final pairs = DeviceComparison.of(
        _phone('a', usd: 1200),
        _phone('b', usd: 700),
      );
      final price = pairs.firstWhere((p) => p.kind == SpecKind.price);
      expect(price.a.value, r'$1,200');
      expect(price.b.value, r'$700');
    });
  });
}
