// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ResourceRef _$ResourceRefFromJson(Map<String, dynamic> json) => _ResourceRef(
  slug: json['slug'] as String,
  name: json['name'] as String,
  url: json['url'] as String?,
);

Map<String, dynamic> _$ResourceRefToJson(_ResourceRef instance) =>
    <String, dynamic>{
      'slug': instance.slug,
      'name': instance.name,
      'url': instance.url,
    };

_CollectionPage _$CollectionPageFromJson(Map<String, dynamic> json) =>
    _CollectionPage(
      count: (json['count'] as num?)?.toInt() ?? 0,
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => ResourceRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ResourceRef>[],
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );

Map<String, dynamic> _$CollectionPageToJson(_CollectionPage instance) =>
    <String, dynamic>{
      'count': instance.count,
      'results': instance.results.map((e) => e.toJson()).toList(),
      'next': instance.next,
      'previous': instance.previous,
    };
