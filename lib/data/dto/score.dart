import 'package:freezed_annotation/freezed_annotation.dart';

part 'score.freezed.dart';
part 'score.g.dart';

/// 벤치마크 하나에서 나온 지표.
///
/// 어느 컬렉션이든 이 구조는 동일하다. 다만 **모든 필드가 null일 수 있다** —
/// 구형 기기는 벤치마크 원본이 없어 `era`만 채워지고 나머지가 비어 온다.
///
/// ```json
/// { "index": null, "percentile": null, "tier": null,
///   "era": "2014-2016", "source": null }
/// ```
@freezed
abstract class ScoreMetric with _$ScoreMetric {
  const factory ScoreMetric({
    /// 0–100 정규화 지수.
    double? index,

    /// 같은 세대 안에서의 백분위.
    double? percentile,

    /// S / A / B / C … 등급.
    String? tier,

    /// 비교 기준이 된 세대 (예: `2024-2026`).
    String? era,

    /// 원본 벤치마크 (예: `geekbench`, `timespy_score`).
    String? source,
  }) = _ScoreMetric;

  factory ScoreMetric.fromJson(Map<String, dynamic> json) =>
      _$ScoreMetricFromJson(json);
}

/// 스마트폰 점수. 5개 축 + 종합.
///
/// `score` 객체가 있어도 개별 축은 null일 수 있다. 저가·구형 기기에서
/// `performance`와 `value`가 비는 경우가 흔하다.
@freezed
abstract class SmartphoneScore with _$SmartphoneScore {
  const factory SmartphoneScore({
    String? algorithmVersion,
    double? overall,
    double? performance,
    double? camera,
    double? battery,
    double? display,

    /// 가격 대비 가치. `msrp_usd`가 없으면 산출되지 않는다.
    double? value,

    /// 성능 축의 근거가 된 벤치마크 지표.
    ScoreMetric? perf,
  }) = _SmartphoneScore;

  factory SmartphoneScore.fromJson(Map<String, dynamic> json) =>
      _$SmartphoneScoreFromJson(json);
}

/// CPU 점수 — 싱글/멀티 코어로 나뉜다.
@freezed
abstract class CpuScore with _$CpuScore {
  const factory CpuScore({
    String? algorithmVersion,
    double? overall,
    ScoreMetric? single,
    ScoreMetric? multi,
  }) = _CpuScore;

  factory CpuScore.fromJson(Map<String, dynamic> json) =>
      _$CpuScoreFromJson(json);
}

/// GPU 점수 — 그래픽 단일 축.
@freezed
abstract class GpuScore with _$GpuScore {
  const factory GpuScore({
    String? algorithmVersion,
    double? overall,
    ScoreMetric? graphics,
  }) = _GpuScore;

  factory GpuScore.fromJson(Map<String, dynamic> json) =>
      _$GpuScoreFromJson(json);
}

/// SoC 점수 — CPU와 시스템 전체.
@freezed
abstract class SocScore with _$SocScore {
  const factory SocScore({
    String? algorithmVersion,
    double? overall,
    ScoreMetric? cpu,
    ScoreMetric? system,
  }) = _SocScore;

  factory SocScore.fromJson(Map<String, dynamic> json) =>
      _$SocScoreFromJson(json);
}
