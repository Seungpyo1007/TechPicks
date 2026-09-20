/// 조립 견적의 추천 엔진.
///
/// 웹(`site/lib/build.ts`)에 있던 것을 옮겼다. 계산은 그대로고, **문장을
/// 만들지 않는 것**만 다르다 — 원본은 `comboReason`·`requirements`·
/// `bottleneckMessage` 가 한국어를 직접 만들었는데 그러면 번역이 도메인에
/// 묶인다. 여기서는 사실(숫자와 종류)만 돌려주고 문장은 화면이 쓴다.
///
/// TechAPI 에는 메인보드·메모리·저장장치·파워·케이스가 없다. 그래서 실제
/// 제품을 고르는 것은 CPU 와 GPU 뿐이고, 나머지는 두 부품에서 **도출되는
/// 요구사양**으로만 제시한다. 없는 제품을 지어내지 않는다.
///
/// 점수는 전부 TechAPI 가 발행하는 0–100 정규화 지수다. 원시 벤치마크가
/// 아니다.
library;

import '../../data/dto/cpu.dart';
import '../../data/dto/gpu.dart';

/// 용도별 가중치.
class BuildWeights {
  const BuildWeights({
    required this.gpu,
    required this.cpuSingle,
    required this.cpuMulti,
    required this.vram,
  });

  final double gpu;
  final double cpuSingle;
  final double cpuMulti;
  final double vram;
}

/// 무엇에 쓸 컴퓨터인가.
///
/// `TpTab`·`RankCategory` 와 같은 모양으로 값에 필드를 붙인다 — 목록과
/// 가중치가 따로 놀면 한쪽만 고치는 일이 생긴다.
enum BuildUseCase {
  gaming(
    'buildUseGaming',
    BuildWeights(gpu: 0.7, cpuSingle: 0.25, cpuMulti: 0.05, vram: 0),
  ),
  creator(
    'buildUseCreator',
    BuildWeights(gpu: 0.45, cpuSingle: 0.15, cpuMulti: 0.4, vram: 0),
  ),
  office(
    'buildUseOffice',
    BuildWeights(gpu: 0.1, cpuSingle: 0.45, cpuMulti: 0.45, vram: 0),
    allowsIntegratedGpu: true,
  ),
  ai(
    'buildUseAi',
    BuildWeights(gpu: 0.5, cpuSingle: 0.15, cpuMulti: 0.25, vram: 0.1),
  );

  const BuildUseCase(
    this.key,
    this.weights, {
    this.allowsIntegratedGpu = false,
  });

  /// 번역 키의 앞머리. 설명문은 `${key}Sub`.
  final String key;

  final BuildWeights weights;

  /// 내장 그래픽만으로도 성립하는 용도인지. 사무·개발만 해당한다.
  final bool allowsIntegratedGpu;

  /// 공유된 링크에서 온 값. 모르는 것은 null — 404 로 떨어뜨리지 않는다.
  static BuildUseCase? parse(String? key) {
    if (key == null) return null;
    for (final value in values) {
      if (value.name == key) return value;
    }
    return null;
  }
}

/// 병목.
///
/// sealed 로 두면 화면이 세 경우를 빠짐없이 다룬다 — `TpLinkTarget` 과 같은
/// 관용구다.
sealed class Bottleneck {
  const Bottleneck();
}

/// 둘이 엇비슷하다. 할 말이 없다.
class Balanced extends Bottleneck {
  const Balanced();
}

/// CPU 가 GPU 를 못 먹인다.
class CpuBound extends Bottleneck {
  const CpuBound(this.gap);

  /// 지수 차. 항상 양수.
  final int gap;
}

/// GPU 가 CPU 에 비해 약하다.
class GpuBound extends Bottleneck {
  const GpuBound(this.gap);

  final int gap;
}

/// CPU + GPU 한 쌍.
///
/// freezed 를 안 쓴다. 매 계산마다 파생되고 직렬화되지 않는다 — 생성 코드
/// 천 줄을 얻을 게 없다.
class BuildCombo {
  const BuildCombo({
    required this.cpu,
    required this.gpu,
    required this.score,
    required this.priceUsd,
    required this.psuWatts,
    required this.bottleneck,
  });

  final Cpu cpu;
  final Gpu gpu;

  /// 용도 가중치를 적용한 0–100 점수.
  final double score;

  final int priceUsd;

  /// 권장 파워 용량(W). 50W 단위로 올림.
  final int psuWatts;

  final Bottleneck bottleneck;
}

/// 요구사양 한 줄이 말하는 것.
///
/// 라벨을 문자열로 들고 있지 않다. 화면이 번역 키로 바꾼다.
enum RequirementKind {
  socket('buildReqSocket'),
  memory('buildReqMemory'),
  psu('buildReqPsu'),
  pcie('buildReqPcie'),
  gpuDraw('buildReqGpuDraw'),
  integratedGraphics('buildReqIgpu');

  const RequirementKind(this.key);

  final String key;
}

/// 도출된 요구사양 한 줄.
class Requirement {
  const Requirement(this.kind, this.value);

  final RequirementKind kind;

  /// 기록이 없으면 null. "기록 없음"이라고 **여기서** 적지 않는다 —
  /// 그 문구도 번역 대상이다.
  final String? value;
}

abstract final class BuildEstimate {
  /// 조립에서 흔히 쓰는 예산 구간(두 부품 MSRP 합계 기준, USD).
  static const List<int> budgetPresets = <int>[600, 1000, 1500, 2500];
  static const int minBudget = 200;
  static const int maxBudget = 6000;
  static const int defaultBudget = 1500;

  /// 보드·메모리·저장장치·팬이 쓰는 몫. 파워 용량 계산에만 쓰는 가정값이고
  /// 화면에 밝힌다.
  static const int platformWatts = 150;

  /// 병목으로 볼 지수 차이.
  static const int bottleneckGap = 20;

  /// VRAM 만점 기준. 현행 소비자용 최대 용량이다.
  static const double vramFullGb = 32;

  static double cpuSingle(Cpu cpu) => cpu.score?.single?.index ?? 0;
  static double cpuMulti(Cpu cpu) => cpu.score?.multi?.index ?? 0;
  static double gpuGraphics(Gpu gpu) => gpu.score?.graphics?.index ?? 0;

  /// VRAM 을 0–100 으로.
  static double vramIndex(Gpu gpu) {
    final gb = gpu.memoryGb ?? 0;
    final raw = gb / vramFullGb * 100;
    return raw > 100 ? 100 : raw;
  }

  /// 예산을 허용 구간 안으로. 공유된 링크가 아무 숫자나 들고 올 수 있다.
  static int clampBudget(int usd) =>
      usd < minBudget ? minBudget : (usd > maxBudget ? maxBudget : usd);

  /// 병목을 볼 때 쓰는 CPU 축.
  ///
  /// 용도가 실제로 기대는 쪽으로 골라야 한다. 게이밍을 멀티코어와 견주면
  /// 8코어 X3D 처럼 게임에 강한 CPU 가 병목으로 잘못 찍힌다.
  static double cpuAxisFor(Cpu cpu, BuildUseCase useCase) => switch (useCase) {
    BuildUseCase.gaming => cpuSingle(cpu),
    BuildUseCase.office => (cpuSingle(cpu) + cpuMulti(cpu)) / 2,
    _ => cpuMulti(cpu),
  };

  static Bottleneck bottleneckOf(Cpu cpu, Gpu gpu, BuildUseCase useCase) {
    final gap = (gpuGraphics(gpu) - cpuAxisFor(cpu, useCase)).round();
    if (gap.abs() < bottleneckGap) return const Balanced();
    // GPU 지수가 훨씬 높으면 CPU 가 그래픽을 못 먹인다.
    return gap > 0 ? CpuBound(gap) : GpuBound(-gap);
  }

  /// CPU 최대 소비전력 + GPU 소비전력 + 플랫폼 몫, 50W 단위 올림.
  static int recommendedWatts(Cpu cpu, Gpu? gpu) {
    final cpuDraw = cpu.maxTdpW ?? cpu.tdpW ?? 0;
    final gpuDraw = gpu?.tdpW ?? 0;
    return ((cpuDraw + gpuDraw + platformWatts) / 50).ceil() * 50;
  }

  static double comboScore(Cpu cpu, Gpu gpu, BuildUseCase useCase) {
    final w = useCase.weights;
    final raw =
        w.gpu * gpuGraphics(gpu) +
        w.cpuSingle * cpuSingle(cpu) +
        w.cpuMulti * cpuMulti(cpu) +
        w.vram * vramIndex(gpu);
    return (raw * 10).round() / 10;
  }

  static BuildCombo combo(Cpu cpu, Gpu gpu, BuildUseCase useCase) => BuildCombo(
    cpu: cpu,
    gpu: gpu,
    score: comboScore(cpu, gpu, useCase),
    priceUsd: (cpu.msrpUsd ?? 0) + (gpu.msrpUsd ?? 0),
    psuWatts: recommendedWatts(cpu, gpu),
    bottleneck: bottleneckOf(cpu, gpu, useCase),
  );

  /// 예산 안에서 점수가 가장 높은 조합을 고른다.
  ///
  /// 가격이 없는 부품은 예산 판단이 불가능해 **자동 추천에서 뺀다.** 손으로
  /// 고를 때는 쓸 수 있다 — 그때는 예산을 따지지 않는다.
  static List<BuildCombo> recommend(
    List<Cpu> cpus,
    List<Gpu> gpus,
    BuildUseCase useCase,
    int budgetUsd, {
    int limit = 3,
  }) {
    final pricedCpus = cpus.where((c) => (c.msrpUsd ?? 0) > 0);
    final pricedGpus = gpus
        .where((g) => (g.msrpUsd ?? 0) > 0)
        .toList(growable: false);

    final combos = <BuildCombo>[];
    for (final cpu in pricedCpus) {
      for (final gpu in pricedGpus) {
        final price = (cpu.msrpUsd ?? 0) + (gpu.msrpUsd ?? 0);
        if (price > budgetUsd) continue;
        combos.add(combo(cpu, gpu, useCase));
      }
    }

    combos.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.priceUsd.compareTo(b.priceUsd);
    });

    // 같은 CPU 나 같은 GPU 로 상위가 도배되면 고를 이유가 없다. 한 번씩만.
    final seenCpu = <String>{};
    final seenGpu = <String>{};
    final picked = <BuildCombo>[];
    for (final c in combos) {
      if (seenCpu.contains(c.cpu.slug) || seenGpu.contains(c.gpu.slug)) {
        continue;
      }
      seenCpu.add(c.cpu.slug);
      seenGpu.add(c.gpu.slug);
      picked.add(c);
      if (picked.length >= limit) break;
    }
    return picked;
  }

  /// 조합을 고른 이유에 쓰는 대표 수치.
  ///
  /// 사무·개발은 CPU 멀티코어가, 나머지는 GPU 가 결정적이다. 화면이 이
  /// 숫자로 한 줄을 쓴다.
  static (bool cpuLed, int value) lead(
    BuildCombo combo,
    BuildUseCase useCase,
  ) => useCase == BuildUseCase.office
      ? (true, cpuMulti(combo.cpu).round())
      : (false, gpuGraphics(combo.gpu).round());

  /// CPU·GPU 레코드에서 **도출되는** 나머지 부품 요구사양.
  static List<Requirement> requirements(Cpu cpu, Gpu? gpu) => <Requirement>[
    Requirement(RequirementKind.socket, cpu.socket),
    Requirement(RequirementKind.memory, cpu.memorySupport),
    Requirement(RequirementKind.psu, '${recommendedWatts(cpu, gpu)}'),
    if (gpu != null) ...<Requirement>[
      Requirement(RequirementKind.pcie, gpu.pcieVersion),
      Requirement(RequirementKind.gpuDraw, gpu.tdpW?.toString()),
    ],
    Requirement(RequirementKind.integratedGraphics, cpu.integratedGraphics),
  ];
}
