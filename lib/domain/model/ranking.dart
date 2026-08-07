import '../../data/dto/smartphone.dart';
import 'tp_index.dart';
import 'tp_weights.dart';

/// 랭킹 정렬 축. `docs/DESIGN_HANDOFF.md` — Rankings 의 "Rank by" 칩과 같다.
enum RankAxis {
  tpIndex('rank_axis_index'),
  battery('rank_axis_battery'),
  camera('rank_axis_camera'),
  value('rank_axis_value'),
  price('rank_axis_price');

  const RankAxis(this.key);

  /// `assets/translations/*.json` 의 번역 키.
  final String key;

  /// 값이 작을수록 위로 가는 축. 가격뿐이다.
  bool get ascending => this == RankAxis.price;
}

/// 정렬된 한 줄.
class RankedDevice {
  const RankedDevice({
    required this.device,
    required this.position,
    required this.index,
    required this.axisValue,
    required this.fraction,
  });

  final Smartphone device;

  /// 1부터. 1–3 은 파란 숫자로 그린다.
  final int position;

  /// 현재 가중치로 계산한 TP Index. 축과 무관하게 항상 들고 있는다.
  final int? index;

  /// 활성 축의 값. 행 오른쪽에 강조해서 보여준다.
  final double? axisValue;

  /// 트랙 채움 비율 0–1.
  final double fraction;
}

/// 카탈로그를 축 하나로 세운다.
///
/// 값이 없는 기기는 **아래로 밀되 목록에서 빼지 않는다.** 데이터가 덜 채워진
/// 것과 성능이 낮은 것은 다르고, 사용자는 그 기기가 목록에 있다는 사실 자체를
/// 알아야 한다.
abstract final class Ranking {
  static List<RankedDevice> of(
    List<Smartphone> devices,
    RankAxis axis, [
    TpWeights weights = TpWeights.defaults,
  ]) {
    double? valueOf(Smartphone d) => switch (axis) {
          RankAxis.tpIndex => TpIndex.of(d.score, weights)?.toDouble(),
          RankAxis.battery => d.score?.battery,
          RankAxis.camera => d.score?.camera,
          RankAxis.value => d.score?.value,
          RankAxis.price => d.msrpUsd?.toDouble(),
        };

    final entries = devices
        .map((d) => (device: d, value: valueOf(d)))
        .toList(growable: false);

    final ranked = <({Smartphone device, double? value})>[...entries]..sort((a, b) {
        // 값 없는 쪽이 항상 뒤로.
        if (a.value == null && b.value == null) {
          return a.device.name.compareTo(b.device.name);
        }
        if (a.value == null) return 1;
        if (b.value == null) return -1;
        return axis.ascending
            ? a.value!.compareTo(b.value!)
            : b.value!.compareTo(a.value!);
      });

    final values = ranked
        .map((e) => e.value)
        .whereType<double>()
        .where((v) => v > 0)
        .toList(growable: false);
    final max = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final min = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);

    return <RankedDevice>[
      for (var i = 0; i < ranked.length; i++)
        RankedDevice(
          device: ranked[i].device,
          position: i + 1,
          index: TpIndex.of(ranked[i].device.score, weights),
          axisValue: ranked[i].value,
          // 긴 막대가 항상 "더 좋음"을 뜻하게 맞춘다. 가격은 작을수록 좋으므로
          // 최저가를 가득 채운 것으로 본다.
          fraction: _fraction(ranked[i].value, min: min, max: max, axis: axis),
        ),
    ];
  }

  static double _fraction(
    double? value, {
    required double min,
    required double max,
    required RankAxis axis,
  }) {
    if (value == null || value <= 0) return 0;
    if (axis.ascending) {
      if (min <= 0) return 0;
      return (min / value).clamp(0, 1).toDouble();
    }
    if (max <= 0) return 0;
    return (value / max).clamp(0, 1).toDouble();
  }
}
