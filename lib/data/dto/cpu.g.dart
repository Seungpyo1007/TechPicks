// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cpu.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Cpu _$CpuFromJson(Map<String, dynamic> json) => _Cpu(
  slug: json['slug'] as String,
  name: json['name'] as String,
  id: (json['id'] as num?)?.toInt(),
  manufacturer: json['manufacturer'] == null
      ? null
      : Brand.fromJson(json['manufacturer'] as Map<String, dynamic>),
  releaseDate: json['release_date'] as String?,
  segment: json['segment'] as String?,
  architecture: json['architecture'] as String?,
  socket: json['socket'] as String?,
  processNode: json['process_node'] as String?,
  cores: (json['cores'] as num?)?.toInt(),
  threads: (json['threads'] as num?)?.toInt(),
  pCores: (json['p_cores'] as num?)?.toInt(),
  eCores: (json['e_cores'] as num?)?.toInt(),
  baseClockGhz: (json['base_clock_ghz'] as num?)?.toDouble(),
  boostClockGhz: (json['boost_clock_ghz'] as num?)?.toDouble(),
  l3CacheMb: (json['l3_cache_mb'] as num?)?.toDouble(),
  tdpW: (json['tdp_w'] as num?)?.toInt(),
  maxTdpW: (json['max_tdp_w'] as num?)?.toInt(),
  integratedGraphics: json['integrated_graphics'] as String?,
  memorySupport: json['memory_support'] as String?,
  msrpUsd: (json['msrp_usd'] as num?)?.toInt(),
  score: json['score'] == null
      ? null
      : CpuScore.fromJson(json['score'] as Map<String, dynamic>),
  verified: json['verified'] as bool? ?? false,
  sourceUrls:
      (json['source_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  url: json['url'] as String?,
);

Map<String, dynamic> _$CpuToJson(_Cpu instance) => <String, dynamic>{
  'slug': instance.slug,
  'name': instance.name,
  'id': instance.id,
  'manufacturer': instance.manufacturer?.toJson(),
  'release_date': instance.releaseDate,
  'segment': instance.segment,
  'architecture': instance.architecture,
  'socket': instance.socket,
  'process_node': instance.processNode,
  'cores': instance.cores,
  'threads': instance.threads,
  'p_cores': instance.pCores,
  'e_cores': instance.eCores,
  'base_clock_ghz': instance.baseClockGhz,
  'boost_clock_ghz': instance.boostClockGhz,
  'l3_cache_mb': instance.l3CacheMb,
  'tdp_w': instance.tdpW,
  'max_tdp_w': instance.maxTdpW,
  'integrated_graphics': instance.integratedGraphics,
  'memory_support': instance.memorySupport,
  'msrp_usd': instance.msrpUsd,
  'score': instance.score?.toJson(),
  'verified': instance.verified,
  'source_urls': instance.sourceUrls,
  'url': instance.url,
};
