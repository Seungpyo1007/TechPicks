import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/dto/cpu.dart';
import 'package:techpicks/data/dto/gpu.dart';
import 'package:techpicks/data/dto/score.dart';
import 'package:techpicks/domain/model/build_estimate.dart';

import '../support/harness.dart';

/// 웹(`site/tests/build.test.ts`)의 16케이스를 그대로 옮긴 것.
///
/// 앞쪽은 손으로 만든 부품으로 하는 순수 계산이고, 뒤쪽은 **구워둔 실제
/// 애셋**에 대고 성질을 확인한다. 뒤쪽이 값진 쪽이다 — 정렬 비교자나 중복
/// 제거가 망가지면 거기서 걸린다.

Cpu _cpu({
  String slug = 'test-cpu',
  String? socket = 'AM5',
  String? memorySupport = 'DDR5-5600',
  int? tdpW = 120,
  int? maxTdpW = 162,
  String? integratedGraphics = 'Radeon Graphics',
  int? msrpUsd = 400,
  double single = 90,
  double multi = 60,
}) => Cpu(
  slug: slug,
  name: 'Test CPU',
  socket: socket,
  memorySupport: memorySupport,
  tdpW: tdpW,
  maxTdpW: maxTdpW,
  integratedGraphics: integratedGraphics,
  msrpUsd: msrpUsd,
  score: CpuScore(
    single: ScoreMetric(index: single),
    multi: ScoreMetric(index: multi),
  ),
);

Gpu _gpu({
  String slug = 'test-gpu',
  int? tdpW = 285,
  double? memoryGb = 16,
  String? pcieVersion = 'PCIe 5.0',
  int? msrpUsd = 600,
  double graphics = 80,
}) => Gpu(
  slug: slug,
  name: 'Test GPU',
  tdpW: tdpW,
  memoryGb: memoryGb,
  pcieVersion: pcieVersion,
  msrpUsd: msrpUsd,
  score: GpuScore(graphics: ScoreMetric(index: graphics)),
);

void main() {
  group('용도별 가중치', () {
    test('게이밍은 GPU 에, 사무는 CPU 에 기운다', () {
      final gaming = BuildEstimate.comboScore(
        _cpu(),
        _gpu(),
        BuildUseCase.gaming,
      );
      final office = BuildEstimate.comboScore(
        _cpu(),
        _gpu(),
        BuildUseCase.office,
      );

      // 같은 부품인데 용도가 다르면 점수가 달라야 가중치가 실제로 걸린 것이다.
      expect(gaming, isNot(office));
      expect(gaming, greaterThan(office));
    });

    test('VRAM 은 AI 용도에서만 점수에 든다', () {
      final small = _gpu(memoryGb: 8);
      final large = _gpu(slug: 'big-gpu', memoryGb: 32);

      expect(
        BuildEstimate.comboScore(_cpu(), large, BuildUseCase.ai),
        greaterThan(BuildEstimate.comboScore(_cpu(), small, BuildUseCase.ai)),
      );
      expect(
        BuildEstimate.comboScore(_cpu(), large, BuildUseCase.gaming),
        BuildEstimate.comboScore(_cpu(), small, BuildUseCase.gaming),
      );
    });
  });

  group('전력과 요구사양', () {
    test('플랫폼 몫을 더하고 50W 로 올림한다', () {
      // 162(CPU 최대) + 285(GPU) + 150(플랫폼) = 597 → 600
      expect(BuildEstimate.recommendedWatts(_cpu(), _gpu()), 600);
    });

    test('최대 TDP 가 없으면 TDP 로 떨어진다', () {
      expect(BuildEstimate.recommendedWatts(_cpu(maxTdpW: null), _gpu()), 600);
    });

    test('TechAPI 에 없는 부품을 도출한다', () {
      final rows = BuildEstimate.requirements(_cpu(), _gpu());
      final kinds = rows.map((r) => r.kind);

      expect(kinds, contains(RequirementKind.socket));
      expect(kinds, contains(RequirementKind.memory));
      expect(kinds, contains(RequirementKind.psu));
      expect(
        rows.firstWhere((r) => r.kind == RequirementKind.socket).value,
        'AM5',
      );
    });

    test('내장 그래픽이 없으면 값이 비고, 화면이 그 문구를 고른다', () {
      // 도메인은 "외장 GPU 필수"라고 적지 않는다 — 그것도 번역 대상이다.
      final rows = BuildEstimate.requirements(
        _cpu(integratedGraphics: null),
        null,
      );

      expect(
        rows
            .firstWhere((r) => r.kind == RequirementKind.integratedGraphics)
            .value,
        isNull,
      );
    });

    test('GPU 가 없으면 그래픽 줄을 안 만든다', () {
      final kinds = BuildEstimate.requirements(_cpu(), null).map((r) => r.kind);

      expect(kinds, isNot(contains(RequirementKind.pcie)));
      expect(kinds, isNot(contains(RequirementKind.gpuDraw)));
    });
  });

  group('병목', () {
    test('둘이 엇비슷하면 아무 말도 안 한다', () {
      final combo = BuildEstimate.combo(_cpu(), _gpu(), BuildUseCase.gaming);

      expect(combo.bottleneck, isA<Balanced>());
    });

    test('CPU 가 GPU 를 못 먹이면 그렇게 말한다', () {
      final weak = _cpu(single: 40, multi: 30);
      final combo = BuildEstimate.combo(
        weak,
        _gpu(graphics: 95),
        BuildUseCase.gaming,
      );

      expect(combo.bottleneck, isA<CpuBound>());
      expect((combo.bottleneck as CpuBound).gap, 55);
    });

    test('GPU 가 약하면 반대로 말한다', () {
      final combo = BuildEstimate.combo(
        _cpu(single: 95, multi: 95),
        _gpu(graphics: 30),
        BuildUseCase.gaming,
      );

      expect(combo.bottleneck, isA<GpuBound>());
      expect((combo.bottleneck as GpuBound).gap, 65);
    });

    test('게이밍은 싱글코어로 본다 — 멀티코어가 아니다', () {
      // 8코어 X3D 처럼 멀티는 평범해도 게임에 강한 CPU 를 병목으로 찍으면
      // 안 된다.
      final gamingChip = _cpu(single: 95, multi: 55);
      final fastGpu = _gpu(graphics: 99);

      expect(
        BuildEstimate.combo(
          gamingChip,
          fastGpu,
          BuildUseCase.gaming,
        ).bottleneck,
        isA<Balanced>(),
      );
      // 같은 부품이라도 렌더링에서는 멀티코어가 모자란 게 맞다.
      expect(
        BuildEstimate.combo(
          gamingChip,
          fastGpu,
          BuildUseCase.creator,
        ).bottleneck,
        isA<CpuBound>(),
      );
    });
  });

  group('실제 스냅샷에 대고 추천', () {
    test('예산을 절대 넘지 않는다', () {
      final parts = readParts();
      final picks = BuildEstimate.recommend(
        parts.cpus,
        parts.gpus,
        BuildUseCase.gaming,
        900,
      );

      expect(picks, isNotEmpty);
      for (final combo in picks) {
        expect(combo.priceUsd, lessThanOrEqualTo(900));
      }
    });

    test('예산으로 아무것도 못 사면 빈 목록이다', () {
      final parts = readParts();

      expect(
        BuildEstimate.recommend(
          parts.cpus,
          parts.gpus,
          BuildUseCase.gaming,
          BuildEstimate.minBudget,
        ),
        isEmpty,
      );
    });

    test('같은 부품을 두 번 안 고른다', () {
      final parts = readParts();
      final picks = BuildEstimate.recommend(
        parts.cpus,
        parts.gpus,
        BuildUseCase.creator,
        3000,
      );

      expect(picks.map((c) => c.cpu.slug).toSet(), hasLength(picks.length));
      expect(picks.map((c) => c.gpu.slug).toSet(), hasLength(picks.length));
    });

    test('게이밍과 사무는 다른 1등을 고른다', () {
      final parts = readParts();
      final gaming = BuildEstimate.recommend(
        parts.cpus,
        parts.gpus,
        BuildUseCase.gaming,
        1200,
      ).first;
      final office = BuildEstimate.recommend(
        parts.cpus,
        parts.gpus,
        BuildUseCase.office,
        1200,
      ).first;

      expect(
        gaming.gpu.slug == office.gpu.slug &&
            gaming.cpu.slug == office.cpu.slug,
        isFalse,
      );
    });

    test('점수 내림차순, 같으면 싼 것이 먼저', () {
      final parts = readParts();
      final picks = BuildEstimate.recommend(
        parts.cpus,
        parts.gpus,
        BuildUseCase.ai,
        4000,
        limit: 3,
      );

      for (var i = 0; i < picks.length - 1; i++) {
        expect(picks[i].score, greaterThanOrEqualTo(picks[i + 1].score));
      }
    });

    test('가격 없는 부품은 추천에 안 들어온다', () {
      // 0원은 "공짜"가 아니라 "안 적혔다"다. 남겨두면 예산이 얼마든 1등이 된다.
      final parts = readParts();
      final picks = BuildEstimate.recommend(
        parts.cpus,
        parts.gpus,
        BuildUseCase.gaming,
        BuildEstimate.maxBudget,
      );

      for (final combo in picks) {
        expect(combo.cpu.msrpUsd, greaterThan(0));
        expect(combo.gpu.msrpUsd, greaterThan(0));
      }
    });
  });

  group('공유된 링크에서 온 값', () {
    test('모르는 용도는 null — 404 로 떨어뜨리지 않는다', () {
      expect(BuildUseCase.parse('gaming'), BuildUseCase.gaming);
      expect(BuildUseCase.parse('없는용도'), isNull);
      expect(BuildUseCase.parse(null), isNull);
    });

    test('예산은 허용 구간 안으로 접는다', () {
      expect(BuildEstimate.clampBudget(0), BuildEstimate.minBudget);
      expect(BuildEstimate.clampBudget(999999), BuildEstimate.maxBudget);
      expect(BuildEstimate.clampBudget(1500), 1500);
    });
  });
}
