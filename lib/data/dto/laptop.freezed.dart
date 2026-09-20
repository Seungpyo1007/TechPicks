// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'laptop.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Laptop {

 String get slug; String get name;/// 변형을 걷어낸 기본 모델. 같은 기기의 사양이 다른 변형이 여러 줄로 올 때
/// 묶는 데 쓴다.
 String? get baseModelSlug; Brand? get brand; String? get releaseDate; int? get msrpUsd;/// `Gaming` · `General` 등. 상류 분류를 그대로 옮긴다.
 String? get deviceCategory; String? get cpuName; String? get gpuName;/// `Integrated` · `Dedicated`.
 String? get gpuType; int? get ramGb; int? get storageGb; Display? get display; int? get weightG; String? get os; String? get osVersion; String? get imageUrl; bool get verified; List<String> get sourceUrls; String? get url;
/// Create a copy of Laptop
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LaptopCopyWith<Laptop> get copyWith => _$LaptopCopyWithImpl<Laptop>(this as Laptop, _$identity);

  /// Serializes this Laptop to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Laptop&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.baseModelSlug, baseModelSlug) || other.baseModelSlug == baseModelSlug)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.msrpUsd, msrpUsd) || other.msrpUsd == msrpUsd)&&(identical(other.deviceCategory, deviceCategory) || other.deviceCategory == deviceCategory)&&(identical(other.cpuName, cpuName) || other.cpuName == cpuName)&&(identical(other.gpuName, gpuName) || other.gpuName == gpuName)&&(identical(other.gpuType, gpuType) || other.gpuType == gpuType)&&(identical(other.ramGb, ramGb) || other.ramGb == ramGb)&&(identical(other.storageGb, storageGb) || other.storageGb == storageGb)&&(identical(other.display, display) || other.display == display)&&(identical(other.weightG, weightG) || other.weightG == weightG)&&(identical(other.os, os) || other.os == os)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.verified, verified) || other.verified == verified)&&const DeepCollectionEquality().equals(other.sourceUrls, sourceUrls)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,slug,name,baseModelSlug,brand,releaseDate,msrpUsd,deviceCategory,cpuName,gpuName,gpuType,ramGb,storageGb,display,weightG,os,osVersion,imageUrl,verified,const DeepCollectionEquality().hash(sourceUrls),url]);

@override
String toString() {
  return 'Laptop(slug: $slug, name: $name, baseModelSlug: $baseModelSlug, brand: $brand, releaseDate: $releaseDate, msrpUsd: $msrpUsd, deviceCategory: $deviceCategory, cpuName: $cpuName, gpuName: $gpuName, gpuType: $gpuType, ramGb: $ramGb, storageGb: $storageGb, display: $display, weightG: $weightG, os: $os, osVersion: $osVersion, imageUrl: $imageUrl, verified: $verified, sourceUrls: $sourceUrls, url: $url)';
}


}

/// @nodoc
abstract mixin class $LaptopCopyWith<$Res>  {
  factory $LaptopCopyWith(Laptop value, $Res Function(Laptop) _then) = _$LaptopCopyWithImpl;
@useResult
$Res call({
 String slug, String name, String? baseModelSlug, Brand? brand, String? releaseDate, int? msrpUsd, String? deviceCategory, String? cpuName, String? gpuName, String? gpuType, int? ramGb, int? storageGb, Display? display, int? weightG, String? os, String? osVersion, String? imageUrl, bool verified, List<String> sourceUrls, String? url
});


$BrandCopyWith<$Res>? get brand;$DisplayCopyWith<$Res>? get display;

}
/// @nodoc
class _$LaptopCopyWithImpl<$Res>
    implements $LaptopCopyWith<$Res> {
  _$LaptopCopyWithImpl(this._self, this._then);

  final Laptop _self;
  final $Res Function(Laptop) _then;

/// Create a copy of Laptop
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? name = null,Object? baseModelSlug = freezed,Object? brand = freezed,Object? releaseDate = freezed,Object? msrpUsd = freezed,Object? deviceCategory = freezed,Object? cpuName = freezed,Object? gpuName = freezed,Object? gpuType = freezed,Object? ramGb = freezed,Object? storageGb = freezed,Object? display = freezed,Object? weightG = freezed,Object? os = freezed,Object? osVersion = freezed,Object? imageUrl = freezed,Object? verified = null,Object? sourceUrls = null,Object? url = freezed,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseModelSlug: freezed == baseModelSlug ? _self.baseModelSlug : baseModelSlug // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as Brand?,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,msrpUsd: freezed == msrpUsd ? _self.msrpUsd : msrpUsd // ignore: cast_nullable_to_non_nullable
as int?,deviceCategory: freezed == deviceCategory ? _self.deviceCategory : deviceCategory // ignore: cast_nullable_to_non_nullable
as String?,cpuName: freezed == cpuName ? _self.cpuName : cpuName // ignore: cast_nullable_to_non_nullable
as String?,gpuName: freezed == gpuName ? _self.gpuName : gpuName // ignore: cast_nullable_to_non_nullable
as String?,gpuType: freezed == gpuType ? _self.gpuType : gpuType // ignore: cast_nullable_to_non_nullable
as String?,ramGb: freezed == ramGb ? _self.ramGb : ramGb // ignore: cast_nullable_to_non_nullable
as int?,storageGb: freezed == storageGb ? _self.storageGb : storageGb // ignore: cast_nullable_to_non_nullable
as int?,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as Display?,weightG: freezed == weightG ? _self.weightG : weightG // ignore: cast_nullable_to_non_nullable
as int?,os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,sourceUrls: null == sourceUrls ? _self.sourceUrls : sourceUrls // ignore: cast_nullable_to_non_nullable
as List<String>,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Laptop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BrandCopyWith<$Res>? get brand {
    if (_self.brand == null) {
    return null;
  }

  return $BrandCopyWith<$Res>(_self.brand!, (value) {
    return _then(_self.copyWith(brand: value));
  });
}/// Create a copy of Laptop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DisplayCopyWith<$Res>? get display {
    if (_self.display == null) {
    return null;
  }

  return $DisplayCopyWith<$Res>(_self.display!, (value) {
    return _then(_self.copyWith(display: value));
  });
}
}


/// Adds pattern-matching-related methods to [Laptop].
extension LaptopPatterns on Laptop {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Laptop value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Laptop() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Laptop value)  $default,){
final _that = this;
switch (_that) {
case _Laptop():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Laptop value)?  $default,){
final _that = this;
switch (_that) {
case _Laptop() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String name,  String? baseModelSlug,  Brand? brand,  String? releaseDate,  int? msrpUsd,  String? deviceCategory,  String? cpuName,  String? gpuName,  String? gpuType,  int? ramGb,  int? storageGb,  Display? display,  int? weightG,  String? os,  String? osVersion,  String? imageUrl,  bool verified,  List<String> sourceUrls,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Laptop() when $default != null:
return $default(_that.slug,_that.name,_that.baseModelSlug,_that.brand,_that.releaseDate,_that.msrpUsd,_that.deviceCategory,_that.cpuName,_that.gpuName,_that.gpuType,_that.ramGb,_that.storageGb,_that.display,_that.weightG,_that.os,_that.osVersion,_that.imageUrl,_that.verified,_that.sourceUrls,_that.url);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String name,  String? baseModelSlug,  Brand? brand,  String? releaseDate,  int? msrpUsd,  String? deviceCategory,  String? cpuName,  String? gpuName,  String? gpuType,  int? ramGb,  int? storageGb,  Display? display,  int? weightG,  String? os,  String? osVersion,  String? imageUrl,  bool verified,  List<String> sourceUrls,  String? url)  $default,) {final _that = this;
switch (_that) {
case _Laptop():
return $default(_that.slug,_that.name,_that.baseModelSlug,_that.brand,_that.releaseDate,_that.msrpUsd,_that.deviceCategory,_that.cpuName,_that.gpuName,_that.gpuType,_that.ramGb,_that.storageGb,_that.display,_that.weightG,_that.os,_that.osVersion,_that.imageUrl,_that.verified,_that.sourceUrls,_that.url);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String name,  String? baseModelSlug,  Brand? brand,  String? releaseDate,  int? msrpUsd,  String? deviceCategory,  String? cpuName,  String? gpuName,  String? gpuType,  int? ramGb,  int? storageGb,  Display? display,  int? weightG,  String? os,  String? osVersion,  String? imageUrl,  bool verified,  List<String> sourceUrls,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _Laptop() when $default != null:
return $default(_that.slug,_that.name,_that.baseModelSlug,_that.brand,_that.releaseDate,_that.msrpUsd,_that.deviceCategory,_that.cpuName,_that.gpuName,_that.gpuType,_that.ramGb,_that.storageGb,_that.display,_that.weightG,_that.os,_that.osVersion,_that.imageUrl,_that.verified,_that.sourceUrls,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Laptop implements Laptop {
  const _Laptop({required this.slug, required this.name, this.baseModelSlug, this.brand, this.releaseDate, this.msrpUsd, this.deviceCategory, this.cpuName, this.gpuName, this.gpuType, this.ramGb, this.storageGb, this.display, this.weightG, this.os, this.osVersion, this.imageUrl, this.verified = false, final  List<String> sourceUrls = const <String>[], this.url}): _sourceUrls = sourceUrls;
  factory _Laptop.fromJson(Map<String, dynamic> json) => _$LaptopFromJson(json);

@override final  String slug;
@override final  String name;
/// 변형을 걷어낸 기본 모델. 같은 기기의 사양이 다른 변형이 여러 줄로 올 때
/// 묶는 데 쓴다.
@override final  String? baseModelSlug;
@override final  Brand? brand;
@override final  String? releaseDate;
@override final  int? msrpUsd;
/// `Gaming` · `General` 등. 상류 분류를 그대로 옮긴다.
@override final  String? deviceCategory;
@override final  String? cpuName;
@override final  String? gpuName;
/// `Integrated` · `Dedicated`.
@override final  String? gpuType;
@override final  int? ramGb;
@override final  int? storageGb;
@override final  Display? display;
@override final  int? weightG;
@override final  String? os;
@override final  String? osVersion;
@override final  String? imageUrl;
@override@JsonKey() final  bool verified;
 final  List<String> _sourceUrls;
@override@JsonKey() List<String> get sourceUrls {
  if (_sourceUrls is EqualUnmodifiableListView) return _sourceUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceUrls);
}

@override final  String? url;

/// Create a copy of Laptop
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LaptopCopyWith<_Laptop> get copyWith => __$LaptopCopyWithImpl<_Laptop>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LaptopToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Laptop&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.baseModelSlug, baseModelSlug) || other.baseModelSlug == baseModelSlug)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.msrpUsd, msrpUsd) || other.msrpUsd == msrpUsd)&&(identical(other.deviceCategory, deviceCategory) || other.deviceCategory == deviceCategory)&&(identical(other.cpuName, cpuName) || other.cpuName == cpuName)&&(identical(other.gpuName, gpuName) || other.gpuName == gpuName)&&(identical(other.gpuType, gpuType) || other.gpuType == gpuType)&&(identical(other.ramGb, ramGb) || other.ramGb == ramGb)&&(identical(other.storageGb, storageGb) || other.storageGb == storageGb)&&(identical(other.display, display) || other.display == display)&&(identical(other.weightG, weightG) || other.weightG == weightG)&&(identical(other.os, os) || other.os == os)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.verified, verified) || other.verified == verified)&&const DeepCollectionEquality().equals(other._sourceUrls, _sourceUrls)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,slug,name,baseModelSlug,brand,releaseDate,msrpUsd,deviceCategory,cpuName,gpuName,gpuType,ramGb,storageGb,display,weightG,os,osVersion,imageUrl,verified,const DeepCollectionEquality().hash(_sourceUrls),url]);

@override
String toString() {
  return 'Laptop(slug: $slug, name: $name, baseModelSlug: $baseModelSlug, brand: $brand, releaseDate: $releaseDate, msrpUsd: $msrpUsd, deviceCategory: $deviceCategory, cpuName: $cpuName, gpuName: $gpuName, gpuType: $gpuType, ramGb: $ramGb, storageGb: $storageGb, display: $display, weightG: $weightG, os: $os, osVersion: $osVersion, imageUrl: $imageUrl, verified: $verified, sourceUrls: $sourceUrls, url: $url)';
}


}

/// @nodoc
abstract mixin class _$LaptopCopyWith<$Res> implements $LaptopCopyWith<$Res> {
  factory _$LaptopCopyWith(_Laptop value, $Res Function(_Laptop) _then) = __$LaptopCopyWithImpl;
@override @useResult
$Res call({
 String slug, String name, String? baseModelSlug, Brand? brand, String? releaseDate, int? msrpUsd, String? deviceCategory, String? cpuName, String? gpuName, String? gpuType, int? ramGb, int? storageGb, Display? display, int? weightG, String? os, String? osVersion, String? imageUrl, bool verified, List<String> sourceUrls, String? url
});


@override $BrandCopyWith<$Res>? get brand;@override $DisplayCopyWith<$Res>? get display;

}
/// @nodoc
class __$LaptopCopyWithImpl<$Res>
    implements _$LaptopCopyWith<$Res> {
  __$LaptopCopyWithImpl(this._self, this._then);

  final _Laptop _self;
  final $Res Function(_Laptop) _then;

/// Create a copy of Laptop
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? name = null,Object? baseModelSlug = freezed,Object? brand = freezed,Object? releaseDate = freezed,Object? msrpUsd = freezed,Object? deviceCategory = freezed,Object? cpuName = freezed,Object? gpuName = freezed,Object? gpuType = freezed,Object? ramGb = freezed,Object? storageGb = freezed,Object? display = freezed,Object? weightG = freezed,Object? os = freezed,Object? osVersion = freezed,Object? imageUrl = freezed,Object? verified = null,Object? sourceUrls = null,Object? url = freezed,}) {
  return _then(_Laptop(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,baseModelSlug: freezed == baseModelSlug ? _self.baseModelSlug : baseModelSlug // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as Brand?,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,msrpUsd: freezed == msrpUsd ? _self.msrpUsd : msrpUsd // ignore: cast_nullable_to_non_nullable
as int?,deviceCategory: freezed == deviceCategory ? _self.deviceCategory : deviceCategory // ignore: cast_nullable_to_non_nullable
as String?,cpuName: freezed == cpuName ? _self.cpuName : cpuName // ignore: cast_nullable_to_non_nullable
as String?,gpuName: freezed == gpuName ? _self.gpuName : gpuName // ignore: cast_nullable_to_non_nullable
as String?,gpuType: freezed == gpuType ? _self.gpuType : gpuType // ignore: cast_nullable_to_non_nullable
as String?,ramGb: freezed == ramGb ? _self.ramGb : ramGb // ignore: cast_nullable_to_non_nullable
as int?,storageGb: freezed == storageGb ? _self.storageGb : storageGb // ignore: cast_nullable_to_non_nullable
as int?,display: freezed == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as Display?,weightG: freezed == weightG ? _self.weightG : weightG // ignore: cast_nullable_to_non_nullable
as int?,os: freezed == os ? _self.os : os // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,sourceUrls: null == sourceUrls ? _self._sourceUrls : sourceUrls // ignore: cast_nullable_to_non_nullable
as List<String>,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Laptop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BrandCopyWith<$Res>? get brand {
    if (_self.brand == null) {
    return null;
  }

  return $BrandCopyWith<$Res>(_self.brand!, (value) {
    return _then(_self.copyWith(brand: value));
  });
}/// Create a copy of Laptop
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DisplayCopyWith<$Res>? get display {
    if (_self.display == null) {
    return null;
  }

  return $DisplayCopyWith<$Res>(_self.display!, (value) {
    return _then(_self.copyWith(display: value));
  });
}
}

// dart format on
