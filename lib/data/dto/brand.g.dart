// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Brand _$BrandFromJson(Map<String, dynamic> json) => _Brand(
      slug: json['slug'] as String,
      name: json['name'] as String,
      id: (json['id'] as num?)?.toInt(),
      country: json['country'] as String?,
      foundedYear: (json['founded_year'] as num?)?.toInt(),
      logoUrl: json['logo_url'] as String?,
      website: json['website'] as String?,
      descriptionEn: json['description_en'] as String?,
      descriptionKo: json['description_ko'] as String?,
      url: json['url'] as String?,
      sourceUrls: (json['source_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$BrandToJson(_Brand instance) => <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'id': instance.id,
      'country': instance.country,
      'founded_year': instance.foundedYear,
      'logo_url': instance.logoUrl,
      'website': instance.website,
      'description_en': instance.descriptionEn,
      'description_ko': instance.descriptionKo,
      'url': instance.url,
      'source_urls': instance.sourceUrls,
    };
