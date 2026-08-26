import '../../data/dto/score.dart';
import 'tp_weights.dart';

/// TP Index — 5개 축을 사용자 가중치로 접은 하나의 숫자.
///
/// 데이터셋에는 축이 비어 있는 레코드가 흔하다. 구형·저가 기기는 벤치마크
/// 원본이 없어 `performance` 가, `msrp_usd` 가 없으면 `value` 가 null 로 온다.
///
/// **빠진 축은 0점이 아니라 없는 것으로 친다.** 있는 축의 가중치만 모아 다시
/// 정규화한다. 그러지 않으면 데이터가 덜 채워졌다는 이유만으로 지수가
/// 떨어져서, 실제 성능이 아니라 큐레이션 진척도를 보여주게 된다.
abstract final class TpIndex {
  /// [score] 를 [weights] 로 접은 0–100 값. 쓸 축이 하나도 없으면 null.
  static int? of(
    SmartphoneScore? score, [
    TpWeights weights = TpWeights.defaults,
  ]) {
    if (score == null) return null;

    var weighted = 0.0;
    var used = 0.0;

    void add(double? axis, double weight) {
      if (axis == null || weight <= 0) return;
      weighted += axis * weight;
      used += weight;
    }

    add(score.performance, weights.performance);
    add(score.camera, weights.camera);
    add(score.display, weights.display);
    add(score.battery, weights.battery);
    add(score.value, weights.value);

    if (used == 0) return null;
    return (weighted / used).round();
  }

  /// 축 하나하나를 이름과 함께. 막대 스트립과 You 화면 슬라이더가 이 순서로 쓴다.
  ///
  /// 순서는 명세의 `perf / camera / display / battery / value` 를 따른다.
  static List<TpAxis> axes(SmartphoneScore? score) => <TpAxis>[
    TpAxis(TpAxisKind.performance, score?.performance),
    TpAxis(TpAxisKind.camera, score?.camera),
    TpAxis(TpAxisKind.display, score?.display),
    TpAxis(TpAxisKind.battery, score?.battery),
    TpAxis(TpAxisKind.value, score?.value),
  ];
}

enum TpAxisKind {
  performance('performance'),
  camera('camera'),
  display('display'),
  battery('battery'),
  value('value');

  const TpAxisKind(this.key);

  /// `assets/translations/*.json` 의 번역 키.
  final String key;

  double weightIn(TpWeights w) => switch (this) {
    TpAxisKind.performance => w.performance,
    TpAxisKind.camera => w.camera,
    TpAxisKind.display => w.display,
    TpAxisKind.battery => w.battery,
    TpAxisKind.value => w.value,
  };
}

/// 축 하나. [score] 가 null 이면 그 축은 데이터가 없다.
class TpAxis {
  const TpAxis(this.kind, this.score);

  final TpAxisKind kind;
  final double? score;

  /// 막대 채움 비율 0–1. 데이터가 없으면 0 이지만, 그건 "0점"이 아니라
  /// "빈 트랙"으로 그려야 한다. [score] 가 null 인지로 구분할 것.
  double get fraction => ((score ?? 0) / 100).clamp(0, 1).toDouble();

  bool get hasData => score != null;
}
