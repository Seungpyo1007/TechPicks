import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/domain/model/device_specs.dart';

import '../fixtures/fixtures.dart';

void main() {
  group('DeviceSpecs', () {
    final s25 = Smartphone.fromJson(loadFixture('smartphone_galaxy_s25'));
    final low = Smartphone.fromJson(loadFixture('smartphone_unscored'));

    test('명세의 속성 순서를 지킨다', () {
      expect(
        DeviceSpecs.of(s25).map((s) => s.kind),
        <SpecKind>[
          SpecKind.tpIndex,
          SpecKind.price,
          SpecKind.screen,
          SpecKind.chipset,
          SpecKind.camera,
          SpecKind.battery,
          SpecKind.os,
          SpecKind.weight,
          SpecKind.thickness,
          SpecKind.released,
        ],
      );
    });

    test('실제 레코드를 사람이 읽는 문자열로 만든다', () {
      final by = <SpecKind, DeviceSpec>{
        for (final s in DeviceSpecs.of(s25)) s.kind: s,
      };

      expect(by[SpecKind.price]!.value, r'$799');
      expect(by[SpecKind.chipset]!.value, 'Snapdragon 8 Elite');
      expect(by[SpecKind.screen]!.value, contains('6.2"'));
      expect(by[SpecKind.screen]!.value, contains('120Hz'));
      expect(by[SpecKind.battery]!.value, '4000mAh · 25W');
      expect(by[SpecKind.os]!.value, 'Android 15');
      expect(by[SpecKind.thickness]!.value, '7.2 mm');
      expect(by[SpecKind.released]!.value, '2025-02-07');
    });

    test('후면 카메라만 큰 순서로 붙인다', () {
      final cam = DeviceSpecs.of(s25)
          .firstWhere((s) => s.kind == SpecKind.camera)
          .value;
      // 셀피 12MP 는 빠지고 후면 50/12/10 만 남는다.
      expect(cam, '50MP + 12MP + 10MP');
    });

    test('값이 없으면 대시', () {
      final by = <SpecKind, DeviceSpec>{
        for (final s in DeviceSpecs.of(low)) s.kind: s,
      };
      expect(by[SpecKind.price]!.value, DeviceSpecs.empty);
      expect(by[SpecKind.price]!.hasValue, isFalse);
      expect(by[SpecKind.thickness]!.value, DeviceSpecs.empty);
    });

    test('비교 대상은 지수·가격·배터리 셋뿐', () {
      final comparable = DeviceSpecs.of(s25)
          .where((s) => s.comparable != null)
          .map((s) => s.kind)
          .toSet();
      expect(comparable, <SpecKind>{
        SpecKind.tpIndex,
        SpecKind.price,
        SpecKind.battery,
      });
    });

    test('가격만 낮은 쪽이 이긴다', () {
      final specs = DeviceSpecs.of(s25);
      for (final s in specs.where((s) => s.comparable != null)) {
        expect(
          s.higherIsBetter,
          s.kind != SpecKind.price,
          reason: '${s.kind}',
        );
      }
    });

    test('소수점이 0이면 떼고 찍는다', () {
      // 6.2 인치는 그대로, 두께 7.2mm 도 그대로.
      final screen = DeviceSpecs.of(s25)
          .firstWhere((s) => s.kind == SpecKind.screen)
          .value;
      expect(screen.startsWith('6.2"'), isTrue);
      // 50.0MP 는 50MP 로.
      final cam = DeviceSpecs.of(s25)
          .firstWhere((s) => s.kind == SpecKind.camera)
          .value;
      expect(cam.contains('50.0'), isFalse);
    });

    test('가격 천 단위 구분', () {
      expect(DeviceSpecs.formatPrice(null), DeviceSpecs.empty);
      expect(DeviceSpecs.formatPrice(799), r'$799');
      expect(DeviceSpecs.formatPrice(1299), r'$1,299');
      expect(DeviceSpecs.formatPrice(1000000), r'$1,000,000');
    });
  });
}
