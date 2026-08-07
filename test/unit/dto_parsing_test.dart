import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/dto/brand.dart';
import 'package:techpicks/data/dto/collection_page.dart';
import 'package:techpicks/data/dto/cpu.dart';
import 'package:techpicks/data/dto/gpu.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/dto/soc.dart';

import '../fixtures/fixtures.dart';

void main() {
  group('Smartphone', () {
    test('galaxy-s25의 점수 5축과 종합을 뽑아낸다 (issue #4 완료 기준)', () {
      final phone =
          Smartphone.fromJson(loadFixture('smartphone_galaxy_s25'));

      expect(phone.slug, 'galaxy-s25');
      expect(phone.name, 'Galaxy S25');

      final score = phone.score;
      expect(score, isNotNull, reason: '갤럭시 S25는 점수가 산출된 기기다');
      expect(score!.overall, closeTo(60.8, 0.01));
      expect(score.performance, closeTo(88.9, 0.01));
      expect(score.camera, closeTo(36.1, 0.01));
      expect(score.battery, closeTo(54.4, 0.01));
      expect(score.display, closeTo(63.8, 0.01));
      expect(score.value, closeTo(59.0, 0.01));
      expect(score.algorithmVersion, '2.0.0');

      // 성능 축의 근거
      expect(score.perf?.tier, 'A');
      expect(score.perf?.source, 'geekbench');
      expect(score.perf?.percentile, closeTo(92.0, 0.01));
    });

    test('brand와 soc가 조인되어 있어 추가 요청이 필요 없다', () {
      final phone =
          Smartphone.fromJson(loadFixture('smartphone_galaxy_s25'));

      expect(phone.brand?.slug, 'samsung');
      expect(phone.brand?.country, 'KR');
      expect(phone.soc?.slug, 'snapdragon-8-elite');
      expect(phone.soc?.gpuName, 'Adreno 830');
      expect(phone.soc?.processNm, 3.0);
      // SoC의 manufacturer는 id 없이 온다 — Brand.id가 nullable이어야 하는 이유
      expect(phone.soc?.manufacturer?.slug, 'qualcomm');
      expect(phone.soc?.manufacturer?.id, isNull);
    });

    test('중첩 스펙을 구조화해 읽는다', () {
      final phone =
          Smartphone.fromJson(loadFixture('smartphone_galaxy_s25'));

      expect(phone.display?.sizeInch, 6.2);
      expect(phone.display?.refreshHz, 120);
      expect(phone.display?.brightnessNits, 2600);
      expect(phone.dimensions?.heightMm, closeTo(146.9, 0.01));
      expect(phone.connectivity?.nfc, isTrue);
      expect(phone.connectivity?.wifi, 'Wi-Fi 7');
      expect(phone.storageOptionsGb, [128, 256, 512]);

      expect(phone.cameras, hasLength(4));
      final main = phone.cameras.firstWhere((c) => c.type == 'main');
      expect(main.mp, 50);
      expect(main.ois, isTrue);
      expect(main.sensor, 'Samsung GN3');
      // 셀피 카메라에는 ois/sensor가 없다
      final selfie = phone.cameras.firstWhere((c) => c.type == 'selfie');
      expect(selfie.ois, isNull);
      expect(selfie.sensor, isNull);
    });

    test('점수 객체가 있어도 개별 축은 null일 수 있다', () {
      // 저가·구형 기기. 데이터셋의 상당수가 이 형태다.
      final phone = Smartphone.fromJson(loadFixture('smartphone_unscored'));

      expect(phone.score, isNotNull);
      expect(phone.score!.overall, closeTo(13.3, 0.01));
      // 벤치마크 원본이 없어 비어 있는 축들
      expect(phone.score!.performance, isNull);
      expect(phone.score!.value, isNull);
      expect(phone.score!.perf?.index, isNull);
      expect(phone.score!.perf?.tier, isNull);
      // era만 채워져 온다
      expect(phone.score!.perf?.era, '2014-2016');
    });

    test('빈 필드가 많은 레코드도 예외 없이 파싱된다', () {
      final phone = Smartphone.fromJson(loadFixture('smartphone_unscored'));

      expect(phone.msrpUsd, isNull);
      expect(phone.ipRating, isNull);
      expect(phone.display?.refreshHz, isNull);
      expect(phone.display?.brightnessNits, isNull);
      expect(phone.verified, isFalse);
      // 리스트형 필드는 null 대신 빈 리스트로 정규화된다
      expect(phone.images, isEmpty);
      expect(phone.sourceUrls, isNotEmpty);
    });
  });

  group('Cpu', () {
    test('싱글/멀티 축을 각각 읽는다', () {
      final cpu = Cpu.fromJson(loadFixture('cpu_ryzen_9950x3d'));

      expect(cpu.slug, 'ryzen-9-9950x3d');
      expect(cpu.manufacturer?.slug, 'amd');
      expect(cpu.segment, 'desktop');
      expect(cpu.cores, 16);
      expect(cpu.threads, 32);
      expect(cpu.l3CacheMb, 144.0);
      // 하이브리드 구조가 아니므로 비어 있다
      expect(cpu.pCores, isNull);
      expect(cpu.eCores, isNull);

      expect(cpu.score?.overall, closeTo(82.9, 0.01));
      expect(cpu.score?.single?.tier, 'A');
      expect(cpu.score?.single?.source, 'cinebench_r23_single');
      expect(cpu.score?.multi?.tier, 'B');
      expect(cpu.verified, isTrue);
    });
  });

  group('Gpu', () {
    test('그래픽 단일 축과 NVIDIA 전용 필드를 읽는다', () {
      final gpu = Gpu.fromJson(loadFixture('gpu_rtx_5090'));

      expect(gpu.slug, 'geforce-rtx-5090');
      expect(gpu.cudaCores, 21760);
      // AMD 전용 필드는 비어 있다
      expect(gpu.streamProcessors, isNull);
      expect(gpu.memoryGb, 32.0);
      expect(gpu.fp32Tflops, closeTo(104.8, 0.01));
      expect(gpu.pcieVersion, 'PCIe 5.0');

      expect(gpu.score?.overall, 100.0);
      expect(gpu.score?.graphics?.tier, 'S');
    });
  });

  group('Soc', () {
    test('cpu/system 두 축과 클러스터 구성을 읽는다', () {
      final soc = Soc.fromJson(loadFixture('soc_snapdragon_8_elite'));

      expect(soc.slug, 'snapdragon-8-elite');
      expect(soc.processNm, 3.0);
      expect(soc.npuTops, 45.0);
      expect(soc.cpuConfig?.performance, 2);
      expect(soc.cpuConfig?.efficiency, 6);
      expect(soc.cpuConfig?.architecture, 'Oryon (2nd gen)');
      expect(soc.cpuConfig?.clocksGhz, [4.32, 3.53]);

      expect(soc.score?.cpu?.source, 'geekbench');
      expect(soc.score?.system?.source, 'antutu_score');
    });
  });

  group('Brand', () {
    test('상세는 한국어 설명까지 포함한다', () {
      final brand = Brand.fromJson(loadFixture('brand_samsung'));

      expect(brand.slug, 'samsung');
      expect(brand.country, 'KR');
      expect(brand.foundedYear, 1969);
      expect(brand.descriptionKo, contains('갤럭시'));
      expect(brand.descriptionEn, isNotEmpty);
    });
  });

  group('CollectionPage', () {
    test('목록은 slug/name/url만 담는다', () {
      final page = CollectionPage.fromJson(loadFixture('brands_list'));

      expect(page.count, 207);
      expect(page.results, isNotEmpty);
      expect(page.results.first.slug, isNotEmpty);
      // 정적 덤프에는 페이지네이션이 없다
      expect(page.next, isNull);
      expect(page.previous, isNull);
    });
  });
}
