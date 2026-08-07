// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScoreMetric _$ScoreMetricFromJson(Map<String, dynamic> json) => _ScoreMetric(
      index: (json['index'] as num?)?.toDouble(),
      percentile: (json['percentile'] as num?)?.toDouble(),
      tier: json['tier'] as String?,
      era: json['era'] as String?,
      source: json['source'] as String?,
    );

Map<String, dynamic> _$ScoreMetricToJson(_ScoreMetric instance) =>
    <String, dynamic>{
      'index': instance.index,
      'percentile': instance.percentile,
      'tier': instance.tier,
      'era': instance.era,
      'source': instance.source,
    };

_SmartphoneScore _$SmartphoneScoreFromJson(Map<String, dynamic> json) =>
    _SmartphoneScore(
      algorithmVersion: json['algorithm_version'] as String?,
      overall: (json['overall'] as num?)?.toDouble(),
      performance: (json['performance'] as num?)?.toDouble(),
      camera: (json['camera'] as num?)?.toDouble(),
      battery: (json['battery'] as num?)?.toDouble(),
      display: (json['display'] as num?)?.toDouble(),
      value: (json['value'] as num?)?.toDouble(),
      perf: json['perf'] == null
          ? null
          : ScoreMetric.fromJson(json['perf'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SmartphoneScoreToJson(_SmartphoneScore instance) =>
    <String, dynamic>{
      'algorithm_version': instance.algorithmVersion,
      'overall': instance.overall,
      'performance': instance.performance,
      'camera': instance.camera,
      'battery': instance.battery,
      'display': instance.display,
      'value': instance.value,
      'perf': instance.perf?.toJson(),
    };

_CpuScore _$CpuScoreFromJson(Map<String, dynamic> json) => _CpuScore(
      algorithmVersion: json['algorithm_version'] as String?,
      overall: (json['overall'] as num?)?.toDouble(),
      single: json['single'] == null
          ? null
          : ScoreMetric.fromJson(json['single'] as Map<String, dynamic>),
      multi: json['multi'] == null
          ? null
          : ScoreMetric.fromJson(json['multi'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CpuScoreToJson(_CpuScore instance) => <String, dynamic>{
      'algorithm_version': instance.algorithmVersion,
      'overall': instance.overall,
      'single': instance.single?.toJson(),
      'multi': instance.multi?.toJson(),
    };

_GpuScore _$GpuScoreFromJson(Map<String, dynamic> json) => _GpuScore(
      algorithmVersion: json['algorithm_version'] as String?,
      overall: (json['overall'] as num?)?.toDouble(),
      graphics: json['graphics'] == null
          ? null
          : ScoreMetric.fromJson(json['graphics'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GpuScoreToJson(_GpuScore instance) => <String, dynamic>{
      'algorithm_version': instance.algorithmVersion,
      'overall': instance.overall,
      'graphics': instance.graphics?.toJson(),
    };

_SocScore _$SocScoreFromJson(Map<String, dynamic> json) => _SocScore(
      algorithmVersion: json['algorithm_version'] as String?,
      overall: (json['overall'] as num?)?.toDouble(),
      cpu: json['cpu'] == null
          ? null
          : ScoreMetric.fromJson(json['cpu'] as Map<String, dynamic>),
      system: json['system'] == null
          ? null
          : ScoreMetric.fromJson(json['system'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SocScoreToJson(_SocScore instance) => <String, dynamic>{
      'algorithm_version': instance.algorithmVersion,
      'overall': instance.overall,
      'cpu': instance.cpu?.toJson(),
      'system': instance.system?.toJson(),
    };
