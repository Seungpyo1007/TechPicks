// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laptop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Laptop _$LaptopFromJson(Map<String, dynamic> json) => _Laptop(
  slug: json['slug'] as String,
  name: json['name'] as String,
  baseModelSlug: json['base_model_slug'] as String?,
  brand: json['brand'] == null
      ? null
      : Brand.fromJson(json['brand'] as Map<String, dynamic>),
  releaseDate: json['release_date'] as String?,
  msrpUsd: (json['msrp_usd'] as num?)?.toInt(),
  deviceCategory: json['device_category'] as String?,
  cpuName: json['cpu_name'] as String?,
  gpuName: json['gpu_name'] as String?,
  gpuType: json['gpu_type'] as String?,
  ramGb: (json['ram_gb'] as num?)?.toInt(),
  storageGb: (json['storage_gb'] as num?)?.toInt(),
  display: json['display'] == null
      ? null
      : Display.fromJson(json['display'] as Map<String, dynamic>),
  weightG: (json['weight_g'] as num?)?.toInt(),
  os: json['os'] as String?,
  osVersion: json['os_version'] as String?,
  imageUrl: json['image_url'] as String?,
  verified: json['verified'] as bool? ?? false,
  sourceUrls:
      (json['source_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  url: json['url'] as String?,
);

Map<String, dynamic> _$LaptopToJson(_Laptop instance) => <String, dynamic>{
  'slug': instance.slug,
  'name': instance.name,
  'base_model_slug': instance.baseModelSlug,
  'brand': instance.brand?.toJson(),
  'release_date': instance.releaseDate,
  'msrp_usd': instance.msrpUsd,
  'device_category': instance.deviceCategory,
  'cpu_name': instance.cpuName,
  'gpu_name': instance.gpuName,
  'gpu_type': instance.gpuType,
  'ram_gb': instance.ramGb,
  'storage_gb': instance.storageGb,
  'display': instance.display?.toJson(),
  'weight_g': instance.weightG,
  'os': instance.os,
  'os_version': instance.osVersion,
  'image_url': instance.imageUrl,
  'verified': instance.verified,
  'source_urls': instance.sourceUrls,
  'url': instance.url,
};
