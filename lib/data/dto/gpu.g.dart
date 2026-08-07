// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gpu.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Gpu _$GpuFromJson(Map<String, dynamic> json) => _Gpu(
      slug: json['slug'] as String,
      name: json['name'] as String,
      id: (json['id'] as num?)?.toInt(),
      manufacturer: json['manufacturer'] == null
          ? null
          : Brand.fromJson(json['manufacturer'] as Map<String, dynamic>),
      architecture: json['architecture'] as String?,
      releaseDate: json['release_date'] as String?,
      msrpUsd: (json['msrp_usd'] as num?)?.toInt(),
      cudaCores: (json['cuda_cores'] as num?)?.toInt(),
      streamProcessors: (json['stream_processors'] as num?)?.toInt(),
      rtCores: (json['rt_cores'] as num?)?.toInt(),
      tensorCores: (json['tensor_cores'] as num?)?.toInt(),
      memoryGb: (json['memory_gb'] as num?)?.toDouble(),
      memoryType: json['memory_type'] as String?,
      memoryBusBit: (json['memory_bus_bit'] as num?)?.toInt(),
      memoryBandwidthGbps: (json['memory_bandwidth_gbps'] as num?)?.toDouble(),
      baseClockMhz: (json['base_clock_mhz'] as num?)?.toInt(),
      boostClockMhz: (json['boost_clock_mhz'] as num?)?.toInt(),
      tdpW: (json['tdp_w'] as num?)?.toInt(),
      pcieVersion: json['pcie_version'] as String?,
      fp32Tflops: (json['fp32_tflops'] as num?)?.toDouble(),
      blenderScore: (json['blender_score'] as num?)?.toDouble(),
      score: json['score'] == null
          ? null
          : GpuScore.fromJson(json['score'] as Map<String, dynamic>),
      verified: json['verified'] as bool? ?? false,
      sourceUrls: (json['source_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      url: json['url'] as String?,
    );

Map<String, dynamic> _$GpuToJson(_Gpu instance) => <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'id': instance.id,
      'manufacturer': instance.manufacturer?.toJson(),
      'architecture': instance.architecture,
      'release_date': instance.releaseDate,
      'msrp_usd': instance.msrpUsd,
      'cuda_cores': instance.cudaCores,
      'stream_processors': instance.streamProcessors,
      'rt_cores': instance.rtCores,
      'tensor_cores': instance.tensorCores,
      'memory_gb': instance.memoryGb,
      'memory_type': instance.memoryType,
      'memory_bus_bit': instance.memoryBusBit,
      'memory_bandwidth_gbps': instance.memoryBandwidthGbps,
      'base_clock_mhz': instance.baseClockMhz,
      'boost_clock_mhz': instance.boostClockMhz,
      'tdp_w': instance.tdpW,
      'pcie_version': instance.pcieVersion,
      'fp32_tflops': instance.fp32Tflops,
      'blender_score': instance.blenderScore,
      'score': instance.score?.toJson(),
      'verified': instance.verified,
      'source_urls': instance.sourceUrls,
      'url': instance.url,
    };
