// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CpuConfig _$CpuConfigFromJson(Map<String, dynamic> json) => _CpuConfig(
  performance: (json['performance'] as num?)?.toInt(),
  efficiency: (json['efficiency'] as num?)?.toInt(),
  architecture: json['architecture'] as String?,
  clocksGhz:
      (json['clocks_ghz'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const <double>[],
);

Map<String, dynamic> _$CpuConfigToJson(_CpuConfig instance) =>
    <String, dynamic>{
      'performance': instance.performance,
      'efficiency': instance.efficiency,
      'architecture': instance.architecture,
      'clocks_ghz': instance.clocksGhz,
    };

_Soc _$SocFromJson(Map<String, dynamic> json) => _Soc(
  slug: json['slug'] as String,
  name: json['name'] as String,
  id: (json['id'] as num?)?.toInt(),
  manufacturer: json['manufacturer'] == null
      ? null
      : Brand.fromJson(json['manufacturer'] as Map<String, dynamic>),
  releaseDate: json['release_date'] as String?,
  processNm: (json['process_nm'] as num?)?.toDouble(),
  transistorsBillion: (json['transistors_billion'] as num?)?.toDouble(),
  cpuConfig: json['cpu_config'] == null
      ? null
      : CpuConfig.fromJson(json['cpu_config'] as Map<String, dynamic>),
  gpuName: json['gpu_name'] as String?,
  gpuCores: (json['gpu_cores'] as num?)?.toInt(),
  gpuClockMhz: (json['gpu_clock_mhz'] as num?)?.toInt(),
  npuTops: (json['npu_tops'] as num?)?.toDouble(),
  modem: json['modem'] as String?,
  score: json['score'] == null
      ? null
      : SocScore.fromJson(json['score'] as Map<String, dynamic>),
  verified: json['verified'] as bool? ?? false,
  sourceUrls:
      (json['source_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  url: json['url'] as String?,
);

Map<String, dynamic> _$SocToJson(_Soc instance) => <String, dynamic>{
  'slug': instance.slug,
  'name': instance.name,
  'id': instance.id,
  'manufacturer': instance.manufacturer?.toJson(),
  'release_date': instance.releaseDate,
  'process_nm': instance.processNm,
  'transistors_billion': instance.transistorsBillion,
  'cpu_config': instance.cpuConfig?.toJson(),
  'gpu_name': instance.gpuName,
  'gpu_cores': instance.gpuCores,
  'gpu_clock_mhz': instance.gpuClockMhz,
  'npu_tops': instance.npuTops,
  'modem': instance.modem,
  'score': instance.score?.toJson(),
  'verified': instance.verified,
  'source_urls': instance.sourceUrls,
  'url': instance.url,
};
