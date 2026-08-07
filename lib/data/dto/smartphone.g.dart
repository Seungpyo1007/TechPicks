// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smartphone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Display _$DisplayFromJson(Map<String, dynamic> json) => _Display(
  sizeInch: (json['size_inch'] as num?)?.toDouble(),
  resolution: json['resolution'] as String?,
  refreshHz: (json['refresh_hz'] as num?)?.toInt(),
  type: json['type'] as String?,
  ppi: (json['ppi'] as num?)?.toInt(),
  brightnessNits: (json['brightness_nits'] as num?)?.toInt(),
);

Map<String, dynamic> _$DisplayToJson(_Display instance) => <String, dynamic>{
  'size_inch': instance.sizeInch,
  'resolution': instance.resolution,
  'refresh_hz': instance.refreshHz,
  'type': instance.type,
  'ppi': instance.ppi,
  'brightness_nits': instance.brightnessNits,
};

_Camera _$CameraFromJson(Map<String, dynamic> json) => _Camera(
  type: json['type'] as String?,
  mp: (json['mp'] as num?)?.toDouble(),
  aperture: (json['aperture'] as num?)?.toDouble(),
  ois: json['ois'] as bool?,
  sensor: json['sensor'] as String?,
  opticalZoom: (json['optical_zoom'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CameraToJson(_Camera instance) => <String, dynamic>{
  'type': instance.type,
  'mp': instance.mp,
  'aperture': instance.aperture,
  'ois': instance.ois,
  'sensor': instance.sensor,
  'optical_zoom': instance.opticalZoom,
};

_Dimensions _$DimensionsFromJson(Map<String, dynamic> json) => _Dimensions(
  heightMm: (json['height_mm'] as num?)?.toDouble(),
  widthMm: (json['width_mm'] as num?)?.toDouble(),
  depthMm: (json['depth_mm'] as num?)?.toDouble(),
);

Map<String, dynamic> _$DimensionsToJson(_Dimensions instance) =>
    <String, dynamic>{
      'height_mm': instance.heightMm,
      'width_mm': instance.widthMm,
      'depth_mm': instance.depthMm,
    };

_Connectivity _$ConnectivityFromJson(Map<String, dynamic> json) =>
    _Connectivity(
      wifi: json['wifi'] as String?,
      bluetooth: json['bluetooth'] as String?,
      nfc: json['nfc'] as bool?,
      usb: json['usb'] as String?,
    );

Map<String, dynamic> _$ConnectivityToJson(_Connectivity instance) =>
    <String, dynamic>{
      'wifi': instance.wifi,
      'bluetooth': instance.bluetooth,
      'nfc': instance.nfc,
      'usb': instance.usb,
    };

_Smartphone _$SmartphoneFromJson(Map<String, dynamic> json) => _Smartphone(
  slug: json['slug'] as String,
  name: json['name'] as String,
  id: (json['id'] as num?)?.toInt(),
  baseModelSlug: json['base_model_slug'] as String?,
  brand: json['brand'] == null
      ? null
      : Brand.fromJson(json['brand'] as Map<String, dynamic>),
  soc: json['soc'] == null
      ? null
      : Soc.fromJson(json['soc'] as Map<String, dynamic>),
  releaseDate: json['release_date'] as String?,
  msrpUsd: (json['msrp_usd'] as num?)?.toInt(),
  ramGb: (json['ram_gb'] as num?)?.toInt(),
  storageOptionsGb:
      (json['storage_options_gb'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  variant:
      json['variant'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  display: json['display'] == null
      ? null
      : Display.fromJson(json['display'] as Map<String, dynamic>),
  cameras:
      (json['cameras'] as List<dynamic>?)
          ?.map((e) => Camera.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Camera>[],
  batteryMah: (json['battery_mah'] as num?)?.toInt(),
  chargingWiredW: (json['charging_wired_w'] as num?)?.toInt(),
  chargingWirelessW: (json['charging_wireless_w'] as num?)?.toInt(),
  weightG: (json['weight_g'] as num?)?.toDouble(),
  dimensions: json['dimensions'] == null
      ? null
      : Dimensions.fromJson(json['dimensions'] as Map<String, dynamic>),
  ipRating: json['ip_rating'] as String?,
  os: json['os'] as String?,
  osVersion: json['os_version'] as String?,
  connectivity: json['connectivity'] == null
      ? null
      : Connectivity.fromJson(json['connectivity'] as Map<String, dynamic>),
  imageUrl: json['image_url'] as String?,
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  score: json['score'] == null
      ? null
      : SmartphoneScore.fromJson(json['score'] as Map<String, dynamic>),
  verified: json['verified'] as bool? ?? false,
  sourceUrls:
      (json['source_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$SmartphoneToJson(_Smartphone instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'id': instance.id,
      'base_model_slug': instance.baseModelSlug,
      'brand': instance.brand?.toJson(),
      'soc': instance.soc?.toJson(),
      'release_date': instance.releaseDate,
      'msrp_usd': instance.msrpUsd,
      'ram_gb': instance.ramGb,
      'storage_options_gb': instance.storageOptionsGb,
      'variant': instance.variant,
      'display': instance.display?.toJson(),
      'cameras': instance.cameras.map((e) => e.toJson()).toList(),
      'battery_mah': instance.batteryMah,
      'charging_wired_w': instance.chargingWiredW,
      'charging_wireless_w': instance.chargingWirelessW,
      'weight_g': instance.weightG,
      'dimensions': instance.dimensions?.toJson(),
      'ip_rating': instance.ipRating,
      'os': instance.os,
      'os_version': instance.osVersion,
      'connectivity': instance.connectivity?.toJson(),
      'image_url': instance.imageUrl,
      'images': instance.images,
      'score': instance.score?.toJson(),
      'verified': instance.verified,
      'source_urls': instance.sourceUrls,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
