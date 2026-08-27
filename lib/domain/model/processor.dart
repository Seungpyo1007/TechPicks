import '../../data/dto/cpu.dart';
import '../../data/dto/soc.dart';

/// Processors 화면의 세그먼트. `docs/DESIGN_HANDOFF.md` §5 의 `Mobile`/`Laptop`.
enum ProcessorSegment {
  mobile('cpuMobile'),
  laptop('cpuLaptop');

  const ProcessorSegment(this.key);

  final String key;
}

/// 한 행에 필요한 것만 남긴 프로세서.
///
/// 카탈로그는 모바일 칩을 `socs`, 노트북 칩을 `cpus` 로 따로 담고 두 DTO 는
/// 필드가 겹치지 않는다. 화면은 둘을 같은 모양의 행으로 그리므로 여기서
/// 하나로 만든다.
class Processor {
  const Processor({
    required this.slug,
    required this.name,
    required this.segment,
    required this.sub,
    required this.index,
  });

  final String slug;
  final String name;
  final ProcessorSegment segment;

  /// 이름 아래 한 줄. 명세는 `sub` 라고만 적고 내용을 확정하지 않았다.
  /// 두 DTO 에 공통으로 있고 비교에 쓸모 있는 값만 골랐다 —
  /// 모바일은 제조사·공정·GPU, 노트북은 제조사·코어 구성·TDP.
  final String sub;

  /// TechAPI 의 `score.overall`. 폰의 TP Index 와 달리 사용자 가중치를 타지
  /// 않는다 — 프로세서 점수에는 카메라·화면 같은 축이 없다.
  final int? index;

  factory Processor.fromSoc(Soc soc) => Processor(
    slug: soc.slug,
    name: soc.name,
    segment: ProcessorSegment.mobile,
    sub: _join(<String?>[
      soc.manufacturer?.name,
      soc.processNm == null ? null : '${_trimZero(soc.processNm!)}nm',
      soc.gpuName,
    ]),
    index: soc.score?.overall?.round(),
  );

  factory Processor.fromCpu(Cpu cpu) => Processor(
    slug: cpu.slug,
    name: cpu.name,
    segment: ProcessorSegment.laptop,
    sub: _join(<String?>[
      cpu.manufacturer?.name,
      cpu.cores == null
          ? null
          : cpu.threads == null
          ? '${cpu.cores}C'
          : '${cpu.cores}C/${cpu.threads}T',
      cpu.tdpW == null ? null : '${cpu.tdpW}W',
    ]),
    index: cpu.score?.overall?.round(),
  );

  static String _join(List<String?> parts) =>
      parts.whereType<String>().where((p) => p.isNotEmpty).join(' · ');

  /// `3.0nm` 이 아니라 `3nm` 으로 쓴다.
  static String _trimZero(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
}

/// 정렬된 한 줄.
class RankedProcessor {
  const RankedProcessor({
    required this.processor,
    required this.position,
    required this.fraction,
  });

  final Processor processor;

  /// 1부터.
  final int position;

  /// 트랙 채움 비율 0–1.
  final double fraction;
}

/// 세그먼트 하나를 점수순으로 세운다.
///
/// 폰 랭킹과 같은 규칙이다 — 점수 없는 칩은 목록에서 빼지 않고 아래로 민다.
abstract final class ProcessorRanking {
  static List<RankedProcessor> of(List<Processor> processors) {
    final sorted = <Processor>[...processors]
      ..sort((a, b) {
        if (a.index == null && b.index == null) return a.name.compareTo(b.name);
        if (a.index == null) return 1;
        if (b.index == null) return -1;
        return b.index!.compareTo(a.index!);
      });

    final scores = sorted
        .map((p) => p.index)
        .whereType<int>()
        .where((v) => v > 0)
        .toList(growable: false);
    final max = scores.isEmpty ? 0 : scores.reduce((a, b) => a > b ? a : b);

    return <RankedProcessor>[
      for (var i = 0; i < sorted.length; i++)
        RankedProcessor(
          processor: sorted[i],
          position: i + 1,
          fraction: max <= 0 || (sorted[i].index ?? 0) <= 0
              ? 0
              : (sorted[i].index! / max).clamp(0, 1).toDouble(),
        ),
    ];
  }
}
