import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/repository/laptop_repository.dart';
import 'package:techpicks/data/repository/parts_repository.dart';

import '../support/harness.dart';

/// 구워둔 애셋을 **실제로** 읽는다.
///
/// 손으로 만든 픽스처로 하면 애셋이 깨져도 안 걸린다. 견적기와 노트북 화면은
/// 이 파일 하나에 통째로 의존하므로, 파일이 비거나 필드 이름이 바뀌면 여기서
/// 먼저 터져야 한다.
void main() {
  group('데스크톱 부품 애셋', () {
    test('CPU 와 GPU 가 실려 있다', () {
      final parts = readParts();

      expect(parts.version, greaterThan(0));
      expect(parts.source, isNotEmpty, reason: 'CC-BY-SA 표기에 쓴다');
      expect(parts.cpus, isNotEmpty);
      expect(parts.gpus, isNotEmpty);
    });

    test('카탈로그의 CPU 와 다른 물건이다', () {
      // 카탈로그 CPU 40종은 전부 노트북용이라 조립에 못 쓴다. 이 애셋을
      // 따로 둔 이유가 그것이다 — 둘이 같아지면 존재 이유가 없다.
      final desktop = readParts().cpus.map((c) => c.slug).toSet();
      final mobile = readCatalog().cpus.map((c) => c.slug).toSet();

      expect(desktop.intersection(mobile), isEmpty);
    });

    test('견적기가 쓰는 필드가 채워져 있다', () {
      final parts = readParts();

      // 가격이 없는 부품은 견적에서 빠진다. 전부 빠지면 화면이 빈다.
      expect(parts.pricedCpus, isNotEmpty);
      expect(parts.pricedGpus, isNotEmpty);

      for (final cpu in parts.pricedCpus) {
        expect(cpu.tdpW, isNotNull, reason: '${cpu.slug} — 파워 계산에 쓴다');
        expect(cpu.socket, isNotNull, reason: '${cpu.slug} — 요구사항 표에 쓴다');
        expect(cpu.score, isNotNull, reason: '${cpu.slug} — 점수 없이 못 고른다');
      }
      for (final gpu in parts.pricedGpus) {
        expect(gpu.tdpW, isNotNull, reason: '${gpu.slug} — 파워 계산에 쓴다');
        expect(gpu.score, isNotNull, reason: gpu.slug);
      }
    });

    test('가격 없는 부품은 조합 후보에서 빠진다', () {
      final parts = readParts();

      expect(parts.pricedGpus.length, lessThanOrEqualTo(parts.gpus.length));
      expect(parts.pricedGpus.every((g) => g.msrpUsd != null), isTrue);
    });

    test('슬러그로 찾는다', () {
      final parts = readParts();
      final slug = parts.cpus.first.slug;

      expect(parts.cpu(slug)?.slug, slug);
      expect(parts.cpu('없는-부품'), isNull);
    });

    test('리포지토리가 같은 것을 읽는다', () async {
      final result = await PartsRepository(bundle: FileBundle()).load();

      expect(result.isOk, isTrue);
      expect(
        result.fold((p) => p.cpus.length, (_) => 0),
        readParts().cpus.length,
      );
    });

    test('애셋이 없으면 실패로 떨어진다', () async {
      final result = await PartsRepository(
        bundle: FileBundle(),
        assetPath: '없는파일.json',
      ).load();

      expect(result.isOk, isFalse);
    });
  });

  group('노트북 애셋', () {
    test('실려 있고 출처를 들고 있다', () {
      final laptops = readLaptops();

      expect(laptops.items, isNotEmpty);
      expect(laptops.source, isNotEmpty);
    });

    test('이어붙이기 사고가 구울 때 접혀 있다', () {
      // 상류가 `Apple M4 M4 Max`, `NVIDIA GeForce RTX RTX 5090` 처럼 준다.
      // tool/normalize_names.dart 가 굽는 단계에서 접는다 — 런타임이 아니다.
      for (final laptop in readLaptops().items) {
        for (final name in <String?>[
          laptop.name,
          laptop.cpuName,
          laptop.gpuName,
        ]) {
          if (name == null) continue;
          final words = name.split(' ');
          for (var i = 0; i < words.length - 1; i++) {
            expect(
              words[i],
              isNot(words[i + 1]),
              reason: '$name — 붙어 있는 중복 낱말',
            );
          }
        }
        expect(laptop.name, isNot(contains('(')), reason: laptop.slug);
      }
    });

    test('점수가 없다 — 있는 척하지 않는다', () {
      // TechAPI 의 노트북에는 벤치마크가 없다. DTO 에 score 필드 자체를 두지
      // 않았고, 화면도 지수를 그리지 않는다.
      final laptops = readLaptops();

      expect(laptops.items.first.toJson().containsKey('score'), isFalse);
    });

    test('가격 내림차순으로 준다', () {
      final sorted = readLaptops().byPrice;
      final priced = sorted
          .where((l) => l.msrpUsd != null)
          .map((l) => l.msrpUsd!)
          .toList();

      expect(priced, isNotEmpty);
      for (var i = 0; i < priced.length - 1; i++) {
        expect(priced[i], greaterThanOrEqualTo(priced[i + 1]));
      }
      // 값 없는 것은 뒤로. 0원처럼 보이면 안 된다.
      final firstUnpriced = sorted.indexWhere((l) => l.msrpUsd == null);
      if (firstUnpriced >= 0) {
        expect(firstUnpriced, greaterThanOrEqualTo(priced.length));
      }
    });

    test('리포지토리가 같은 것을 읽는다', () async {
      final result = await LaptopRepository(bundle: FileBundle()).load();

      expect(result.isOk, isTrue);
      expect(
        result.fold((l) => l.items.length, (_) => 0),
        readLaptops().items.length,
      );
    });
  });
}
