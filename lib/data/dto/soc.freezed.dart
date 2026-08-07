// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'soc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CpuConfig {

/// 고성능 코어 수.
 int? get performance;/// 효율 코어 수.
 int? get efficiency; String? get architecture;/// 클러스터별 최대 클럭. 길이는 고정이 아니다.
 List<double> get clocksGhz;
/// Create a copy of CpuConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CpuConfigCopyWith<CpuConfig> get copyWith => _$CpuConfigCopyWithImpl<CpuConfig>(this as CpuConfig, _$identity);

  /// Serializes this CpuConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CpuConfig&&(identical(other.performance, performance) || other.performance == performance)&&(identical(other.efficiency, efficiency) || other.efficiency == efficiency)&&(identical(other.architecture, architecture) || other.architecture == architecture)&&const DeepCollectionEquality().equals(other.clocksGhz, clocksGhz));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,performance,efficiency,architecture,const DeepCollectionEquality().hash(clocksGhz));

@override
String toString() {
  return 'CpuConfig(performance: $performance, efficiency: $efficiency, architecture: $architecture, clocksGhz: $clocksGhz)';
}


}

/// @nodoc
abstract mixin class $CpuConfigCopyWith<$Res>  {
  factory $CpuConfigCopyWith(CpuConfig value, $Res Function(CpuConfig) _then) = _$CpuConfigCopyWithImpl;
@useResult
$Res call({
 int? performance, int? efficiency, String? architecture, List<double> clocksGhz
});




}
/// @nodoc
class _$CpuConfigCopyWithImpl<$Res>
    implements $CpuConfigCopyWith<$Res> {
  _$CpuConfigCopyWithImpl(this._self, this._then);

  final CpuConfig _self;
  final $Res Function(CpuConfig) _then;

/// Create a copy of CpuConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? performance = freezed,Object? efficiency = freezed,Object? architecture = freezed,Object? clocksGhz = null,}) {
  return _then(_self.copyWith(
performance: freezed == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as int?,efficiency: freezed == efficiency ? _self.efficiency : efficiency // ignore: cast_nullable_to_non_nullable
as int?,architecture: freezed == architecture ? _self.architecture : architecture // ignore: cast_nullable_to_non_nullable
as String?,clocksGhz: null == clocksGhz ? _self.clocksGhz : clocksGhz // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}

}


/// Adds pattern-matching-related methods to [CpuConfig].
extension CpuConfigPatterns on CpuConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CpuConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CpuConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CpuConfig value)  $default,){
final _that = this;
switch (_that) {
case _CpuConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CpuConfig value)?  $default,){
final _that = this;
switch (_that) {
case _CpuConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? performance,  int? efficiency,  String? architecture,  List<double> clocksGhz)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CpuConfig() when $default != null:
return $default(_that.performance,_that.efficiency,_that.architecture,_that.clocksGhz);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? performance,  int? efficiency,  String? architecture,  List<double> clocksGhz)  $default,) {final _that = this;
switch (_that) {
case _CpuConfig():
return $default(_that.performance,_that.efficiency,_that.architecture,_that.clocksGhz);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? performance,  int? efficiency,  String? architecture,  List<double> clocksGhz)?  $default,) {final _that = this;
switch (_that) {
case _CpuConfig() when $default != null:
return $default(_that.performance,_that.efficiency,_that.architecture,_that.clocksGhz);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CpuConfig implements CpuConfig {
  const _CpuConfig({this.performance, this.efficiency, this.architecture, final  List<double> clocksGhz = const <double>[]}): _clocksGhz = clocksGhz;
  factory _CpuConfig.fromJson(Map<String, dynamic> json) => _$CpuConfigFromJson(json);

/// 고성능 코어 수.
@override final  int? performance;
/// 효율 코어 수.
@override final  int? efficiency;
@override final  String? architecture;
/// 클러스터별 최대 클럭. 길이는 고정이 아니다.
 final  List<double> _clocksGhz;
/// 클러스터별 최대 클럭. 길이는 고정이 아니다.
@override@JsonKey() List<double> get clocksGhz {
  if (_clocksGhz is EqualUnmodifiableListView) return _clocksGhz;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_clocksGhz);
}


/// Create a copy of CpuConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CpuConfigCopyWith<_CpuConfig> get copyWith => __$CpuConfigCopyWithImpl<_CpuConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CpuConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CpuConfig&&(identical(other.performance, performance) || other.performance == performance)&&(identical(other.efficiency, efficiency) || other.efficiency == efficiency)&&(identical(other.architecture, architecture) || other.architecture == architecture)&&const DeepCollectionEquality().equals(other._clocksGhz, _clocksGhz));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,performance,efficiency,architecture,const DeepCollectionEquality().hash(_clocksGhz));

@override
String toString() {
  return 'CpuConfig(performance: $performance, efficiency: $efficiency, architecture: $architecture, clocksGhz: $clocksGhz)';
}


}

/// @nodoc
abstract mixin class _$CpuConfigCopyWith<$Res> implements $CpuConfigCopyWith<$Res> {
  factory _$CpuConfigCopyWith(_CpuConfig value, $Res Function(_CpuConfig) _then) = __$CpuConfigCopyWithImpl;
@override @useResult
$Res call({
 int? performance, int? efficiency, String? architecture, List<double> clocksGhz
});




}
/// @nodoc
class __$CpuConfigCopyWithImpl<$Res>
    implements _$CpuConfigCopyWith<$Res> {
  __$CpuConfigCopyWithImpl(this._self, this._then);

  final _CpuConfig _self;
  final $Res Function(_CpuConfig) _then;

/// Create a copy of CpuConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? performance = freezed,Object? efficiency = freezed,Object? architecture = freezed,Object? clocksGhz = null,}) {
  return _then(_CpuConfig(
performance: freezed == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as int?,efficiency: freezed == efficiency ? _self.efficiency : efficiency // ignore: cast_nullable_to_non_nullable
as int?,architecture: freezed == architecture ? _self.architecture : architecture // ignore: cast_nullable_to_non_nullable
as String?,clocksGhz: null == clocksGhz ? _self._clocksGhz : clocksGhz // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}


}


/// @nodoc
mixin _$Soc {

 String get slug; String get name; int? get id; Brand? get manufacturer; String? get releaseDate;/// 공정 (나노미터).
 double? get processNm; double? get transistorsBillion; CpuConfig? get cpuConfig; String? get gpuName; int? get gpuCores; int? get gpuClockMhz;/// NPU 연산 성능 (TOPS).
 double? get npuTops; String? get modem; SocScore? get score;/// 큐레이터가 출처를 검증했는지. 데이터셋 상당수가 false다.
 bool get verified; List<String> get sourceUrls; String? get url;
/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocCopyWith<Soc> get copyWith => _$SocCopyWithImpl<Soc>(this as Soc, _$identity);

  /// Serializes this Soc to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Soc&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.processNm, processNm) || other.processNm == processNm)&&(identical(other.transistorsBillion, transistorsBillion) || other.transistorsBillion == transistorsBillion)&&(identical(other.cpuConfig, cpuConfig) || other.cpuConfig == cpuConfig)&&(identical(other.gpuName, gpuName) || other.gpuName == gpuName)&&(identical(other.gpuCores, gpuCores) || other.gpuCores == gpuCores)&&(identical(other.gpuClockMhz, gpuClockMhz) || other.gpuClockMhz == gpuClockMhz)&&(identical(other.npuTops, npuTops) || other.npuTops == npuTops)&&(identical(other.modem, modem) || other.modem == modem)&&(identical(other.score, score) || other.score == score)&&(identical(other.verified, verified) || other.verified == verified)&&const DeepCollectionEquality().equals(other.sourceUrls, sourceUrls)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,name,id,manufacturer,releaseDate,processNm,transistorsBillion,cpuConfig,gpuName,gpuCores,gpuClockMhz,npuTops,modem,score,verified,const DeepCollectionEquality().hash(sourceUrls),url);

@override
String toString() {
  return 'Soc(slug: $slug, name: $name, id: $id, manufacturer: $manufacturer, releaseDate: $releaseDate, processNm: $processNm, transistorsBillion: $transistorsBillion, cpuConfig: $cpuConfig, gpuName: $gpuName, gpuCores: $gpuCores, gpuClockMhz: $gpuClockMhz, npuTops: $npuTops, modem: $modem, score: $score, verified: $verified, sourceUrls: $sourceUrls, url: $url)';
}


}

/// @nodoc
abstract mixin class $SocCopyWith<$Res>  {
  factory $SocCopyWith(Soc value, $Res Function(Soc) _then) = _$SocCopyWithImpl;
@useResult
$Res call({
 String slug, String name, int? id, Brand? manufacturer, String? releaseDate, double? processNm, double? transistorsBillion, CpuConfig? cpuConfig, String? gpuName, int? gpuCores, int? gpuClockMhz, double? npuTops, String? modem, SocScore? score, bool verified, List<String> sourceUrls, String? url
});


$BrandCopyWith<$Res>? get manufacturer;$CpuConfigCopyWith<$Res>? get cpuConfig;$SocScoreCopyWith<$Res>? get score;

}
/// @nodoc
class _$SocCopyWithImpl<$Res>
    implements $SocCopyWith<$Res> {
  _$SocCopyWithImpl(this._self, this._then);

  final Soc _self;
  final $Res Function(Soc) _then;

/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? name = null,Object? id = freezed,Object? manufacturer = freezed,Object? releaseDate = freezed,Object? processNm = freezed,Object? transistorsBillion = freezed,Object? cpuConfig = freezed,Object? gpuName = freezed,Object? gpuCores = freezed,Object? gpuClockMhz = freezed,Object? npuTops = freezed,Object? modem = freezed,Object? score = freezed,Object? verified = null,Object? sourceUrls = null,Object? url = freezed,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as Brand?,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,processNm: freezed == processNm ? _self.processNm : processNm // ignore: cast_nullable_to_non_nullable
as double?,transistorsBillion: freezed == transistorsBillion ? _self.transistorsBillion : transistorsBillion // ignore: cast_nullable_to_non_nullable
as double?,cpuConfig: freezed == cpuConfig ? _self.cpuConfig : cpuConfig // ignore: cast_nullable_to_non_nullable
as CpuConfig?,gpuName: freezed == gpuName ? _self.gpuName : gpuName // ignore: cast_nullable_to_non_nullable
as String?,gpuCores: freezed == gpuCores ? _self.gpuCores : gpuCores // ignore: cast_nullable_to_non_nullable
as int?,gpuClockMhz: freezed == gpuClockMhz ? _self.gpuClockMhz : gpuClockMhz // ignore: cast_nullable_to_non_nullable
as int?,npuTops: freezed == npuTops ? _self.npuTops : npuTops // ignore: cast_nullable_to_non_nullable
as double?,modem: freezed == modem ? _self.modem : modem // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as SocScore?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,sourceUrls: null == sourceUrls ? _self.sourceUrls : sourceUrls // ignore: cast_nullable_to_non_nullable
as List<String>,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BrandCopyWith<$Res>? get manufacturer {
    if (_self.manufacturer == null) {
    return null;
  }

  return $BrandCopyWith<$Res>(_self.manufacturer!, (value) {
    return _then(_self.copyWith(manufacturer: value));
  });
}/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CpuConfigCopyWith<$Res>? get cpuConfig {
    if (_self.cpuConfig == null) {
    return null;
  }

  return $CpuConfigCopyWith<$Res>(_self.cpuConfig!, (value) {
    return _then(_self.copyWith(cpuConfig: value));
  });
}/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SocScoreCopyWith<$Res>? get score {
    if (_self.score == null) {
    return null;
  }

  return $SocScoreCopyWith<$Res>(_self.score!, (value) {
    return _then(_self.copyWith(score: value));
  });
}
}


/// Adds pattern-matching-related methods to [Soc].
extension SocPatterns on Soc {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Soc value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Soc() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Soc value)  $default,){
final _that = this;
switch (_that) {
case _Soc():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Soc value)?  $default,){
final _that = this;
switch (_that) {
case _Soc() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  String name,  int? id,  Brand? manufacturer,  String? releaseDate,  double? processNm,  double? transistorsBillion,  CpuConfig? cpuConfig,  String? gpuName,  int? gpuCores,  int? gpuClockMhz,  double? npuTops,  String? modem,  SocScore? score,  bool verified,  List<String> sourceUrls,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Soc() when $default != null:
return $default(_that.slug,_that.name,_that.id,_that.manufacturer,_that.releaseDate,_that.processNm,_that.transistorsBillion,_that.cpuConfig,_that.gpuName,_that.gpuCores,_that.gpuClockMhz,_that.npuTops,_that.modem,_that.score,_that.verified,_that.sourceUrls,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  String name,  int? id,  Brand? manufacturer,  String? releaseDate,  double? processNm,  double? transistorsBillion,  CpuConfig? cpuConfig,  String? gpuName,  int? gpuCores,  int? gpuClockMhz,  double? npuTops,  String? modem,  SocScore? score,  bool verified,  List<String> sourceUrls,  String? url)  $default,) {final _that = this;
switch (_that) {
case _Soc():
return $default(_that.slug,_that.name,_that.id,_that.manufacturer,_that.releaseDate,_that.processNm,_that.transistorsBillion,_that.cpuConfig,_that.gpuName,_that.gpuCores,_that.gpuClockMhz,_that.npuTops,_that.modem,_that.score,_that.verified,_that.sourceUrls,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  String name,  int? id,  Brand? manufacturer,  String? releaseDate,  double? processNm,  double? transistorsBillion,  CpuConfig? cpuConfig,  String? gpuName,  int? gpuCores,  int? gpuClockMhz,  double? npuTops,  String? modem,  SocScore? score,  bool verified,  List<String> sourceUrls,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _Soc() when $default != null:
return $default(_that.slug,_that.name,_that.id,_that.manufacturer,_that.releaseDate,_that.processNm,_that.transistorsBillion,_that.cpuConfig,_that.gpuName,_that.gpuCores,_that.gpuClockMhz,_that.npuTops,_that.modem,_that.score,_that.verified,_that.sourceUrls,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Soc implements Soc {
  const _Soc({required this.slug, required this.name, this.id, this.manufacturer, this.releaseDate, this.processNm, this.transistorsBillion, this.cpuConfig, this.gpuName, this.gpuCores, this.gpuClockMhz, this.npuTops, this.modem, this.score, this.verified = false, final  List<String> sourceUrls = const <String>[], this.url}): _sourceUrls = sourceUrls;
  factory _Soc.fromJson(Map<String, dynamic> json) => _$SocFromJson(json);

@override final  String slug;
@override final  String name;
@override final  int? id;
@override final  Brand? manufacturer;
@override final  String? releaseDate;
/// 공정 (나노미터).
@override final  double? processNm;
@override final  double? transistorsBillion;
@override final  CpuConfig? cpuConfig;
@override final  String? gpuName;
@override final  int? gpuCores;
@override final  int? gpuClockMhz;
/// NPU 연산 성능 (TOPS).
@override final  double? npuTops;
@override final  String? modem;
@override final  SocScore? score;
/// 큐레이터가 출처를 검증했는지. 데이터셋 상당수가 false다.
@override@JsonKey() final  bool verified;
 final  List<String> _sourceUrls;
@override@JsonKey() List<String> get sourceUrls {
  if (_sourceUrls is EqualUnmodifiableListView) return _sourceUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceUrls);
}

@override final  String? url;

/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocCopyWith<_Soc> get copyWith => __$SocCopyWithImpl<_Soc>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SocToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Soc&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id)&&(identical(other.manufacturer, manufacturer) || other.manufacturer == manufacturer)&&(identical(other.releaseDate, releaseDate) || other.releaseDate == releaseDate)&&(identical(other.processNm, processNm) || other.processNm == processNm)&&(identical(other.transistorsBillion, transistorsBillion) || other.transistorsBillion == transistorsBillion)&&(identical(other.cpuConfig, cpuConfig) || other.cpuConfig == cpuConfig)&&(identical(other.gpuName, gpuName) || other.gpuName == gpuName)&&(identical(other.gpuCores, gpuCores) || other.gpuCores == gpuCores)&&(identical(other.gpuClockMhz, gpuClockMhz) || other.gpuClockMhz == gpuClockMhz)&&(identical(other.npuTops, npuTops) || other.npuTops == npuTops)&&(identical(other.modem, modem) || other.modem == modem)&&(identical(other.score, score) || other.score == score)&&(identical(other.verified, verified) || other.verified == verified)&&const DeepCollectionEquality().equals(other._sourceUrls, _sourceUrls)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,name,id,manufacturer,releaseDate,processNm,transistorsBillion,cpuConfig,gpuName,gpuCores,gpuClockMhz,npuTops,modem,score,verified,const DeepCollectionEquality().hash(_sourceUrls),url);

@override
String toString() {
  return 'Soc(slug: $slug, name: $name, id: $id, manufacturer: $manufacturer, releaseDate: $releaseDate, processNm: $processNm, transistorsBillion: $transistorsBillion, cpuConfig: $cpuConfig, gpuName: $gpuName, gpuCores: $gpuCores, gpuClockMhz: $gpuClockMhz, npuTops: $npuTops, modem: $modem, score: $score, verified: $verified, sourceUrls: $sourceUrls, url: $url)';
}


}

/// @nodoc
abstract mixin class _$SocCopyWith<$Res> implements $SocCopyWith<$Res> {
  factory _$SocCopyWith(_Soc value, $Res Function(_Soc) _then) = __$SocCopyWithImpl;
@override @useResult
$Res call({
 String slug, String name, int? id, Brand? manufacturer, String? releaseDate, double? processNm, double? transistorsBillion, CpuConfig? cpuConfig, String? gpuName, int? gpuCores, int? gpuClockMhz, double? npuTops, String? modem, SocScore? score, bool verified, List<String> sourceUrls, String? url
});


@override $BrandCopyWith<$Res>? get manufacturer;@override $CpuConfigCopyWith<$Res>? get cpuConfig;@override $SocScoreCopyWith<$Res>? get score;

}
/// @nodoc
class __$SocCopyWithImpl<$Res>
    implements _$SocCopyWith<$Res> {
  __$SocCopyWithImpl(this._self, this._then);

  final _Soc _self;
  final $Res Function(_Soc) _then;

/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? name = null,Object? id = freezed,Object? manufacturer = freezed,Object? releaseDate = freezed,Object? processNm = freezed,Object? transistorsBillion = freezed,Object? cpuConfig = freezed,Object? gpuName = freezed,Object? gpuCores = freezed,Object? gpuClockMhz = freezed,Object? npuTops = freezed,Object? modem = freezed,Object? score = freezed,Object? verified = null,Object? sourceUrls = null,Object? url = freezed,}) {
  return _then(_Soc(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,manufacturer: freezed == manufacturer ? _self.manufacturer : manufacturer // ignore: cast_nullable_to_non_nullable
as Brand?,releaseDate: freezed == releaseDate ? _self.releaseDate : releaseDate // ignore: cast_nullable_to_non_nullable
as String?,processNm: freezed == processNm ? _self.processNm : processNm // ignore: cast_nullable_to_non_nullable
as double?,transistorsBillion: freezed == transistorsBillion ? _self.transistorsBillion : transistorsBillion // ignore: cast_nullable_to_non_nullable
as double?,cpuConfig: freezed == cpuConfig ? _self.cpuConfig : cpuConfig // ignore: cast_nullable_to_non_nullable
as CpuConfig?,gpuName: freezed == gpuName ? _self.gpuName : gpuName // ignore: cast_nullable_to_non_nullable
as String?,gpuCores: freezed == gpuCores ? _self.gpuCores : gpuCores // ignore: cast_nullable_to_non_nullable
as int?,gpuClockMhz: freezed == gpuClockMhz ? _self.gpuClockMhz : gpuClockMhz // ignore: cast_nullable_to_non_nullable
as int?,npuTops: freezed == npuTops ? _self.npuTops : npuTops // ignore: cast_nullable_to_non_nullable
as double?,modem: freezed == modem ? _self.modem : modem // ignore: cast_nullable_to_non_nullable
as String?,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as SocScore?,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,sourceUrls: null == sourceUrls ? _self._sourceUrls : sourceUrls // ignore: cast_nullable_to_non_nullable
as List<String>,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BrandCopyWith<$Res>? get manufacturer {
    if (_self.manufacturer == null) {
    return null;
  }

  return $BrandCopyWith<$Res>(_self.manufacturer!, (value) {
    return _then(_self.copyWith(manufacturer: value));
  });
}/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CpuConfigCopyWith<$Res>? get cpuConfig {
    if (_self.cpuConfig == null) {
    return null;
  }

  return $CpuConfigCopyWith<$Res>(_self.cpuConfig!, (value) {
    return _then(_self.copyWith(cpuConfig: value));
  });
}/// Create a copy of Soc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SocScoreCopyWith<$Res>? get score {
    if (_self.score == null) {
    return null;
  }

  return $SocScoreCopyWith<$Res>(_self.score!, (value) {
    return _then(_self.copyWith(score: value));
  });
}
}

// dart format on
