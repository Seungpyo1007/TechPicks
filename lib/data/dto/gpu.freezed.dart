// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gpu.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Gpu {
  String get slug;
  String get name;
  int? get id;
  Brand? get manufacturer;
  String? get architecture;
  String? get releaseDate;
  int? get msrpUsd;
  int? get cudaCores;
  int? get streamProcessors;
  int? get rtCores;
  int? get tensorCores;
  double? get memoryGb;
  String? get memoryType;
  int? get memoryBusBit;
  double? get memoryBandwidthGbps;
  int? get baseClockMhz;
  int? get boostClockMhz;
  int? get tdpW;
  String? get pcieVersion;
  double? get fp32Tflops;
  double? get blenderScore;
  GpuScore? get score;
  bool get verified;
  List<String> get sourceUrls;
  String? get url;

  /// Create a copy of Gpu
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GpuCopyWith<Gpu> get copyWith =>
      _$GpuCopyWithImpl<Gpu>(this as Gpu, _$identity);

  /// Serializes this Gpu to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Gpu &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.manufacturer, manufacturer) ||
                other.manufacturer == manufacturer) &&
            (identical(other.architecture, architecture) ||
                other.architecture == architecture) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.msrpUsd, msrpUsd) || other.msrpUsd == msrpUsd) &&
            (identical(other.cudaCores, cudaCores) ||
                other.cudaCores == cudaCores) &&
            (identical(other.streamProcessors, streamProcessors) ||
                other.streamProcessors == streamProcessors) &&
            (identical(other.rtCores, rtCores) || other.rtCores == rtCores) &&
            (identical(other.tensorCores, tensorCores) ||
                other.tensorCores == tensorCores) &&
            (identical(other.memoryGb, memoryGb) ||
                other.memoryGb == memoryGb) &&
            (identical(other.memoryType, memoryType) ||
                other.memoryType == memoryType) &&
            (identical(other.memoryBusBit, memoryBusBit) ||
                other.memoryBusBit == memoryBusBit) &&
            (identical(other.memoryBandwidthGbps, memoryBandwidthGbps) ||
                other.memoryBandwidthGbps == memoryBandwidthGbps) &&
            (identical(other.baseClockMhz, baseClockMhz) ||
                other.baseClockMhz == baseClockMhz) &&
            (identical(other.boostClockMhz, boostClockMhz) ||
                other.boostClockMhz == boostClockMhz) &&
            (identical(other.tdpW, tdpW) || other.tdpW == tdpW) &&
            (identical(other.pcieVersion, pcieVersion) ||
                other.pcieVersion == pcieVersion) &&
            (identical(other.fp32Tflops, fp32Tflops) ||
                other.fp32Tflops == fp32Tflops) &&
            (identical(other.blenderScore, blenderScore) ||
                other.blenderScore == blenderScore) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            const DeepCollectionEquality()
                .equals(other.sourceUrls, sourceUrls) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        slug,
        name,
        id,
        manufacturer,
        architecture,
        releaseDate,
        msrpUsd,
        cudaCores,
        streamProcessors,
        rtCores,
        tensorCores,
        memoryGb,
        memoryType,
        memoryBusBit,
        memoryBandwidthGbps,
        baseClockMhz,
        boostClockMhz,
        tdpW,
        pcieVersion,
        fp32Tflops,
        blenderScore,
        score,
        verified,
        const DeepCollectionEquality().hash(sourceUrls),
        url
      ]);

  @override
  String toString() {
    return 'Gpu(slug: $slug, name: $name, id: $id, manufacturer: $manufacturer, architecture: $architecture, releaseDate: $releaseDate, msrpUsd: $msrpUsd, cudaCores: $cudaCores, streamProcessors: $streamProcessors, rtCores: $rtCores, tensorCores: $tensorCores, memoryGb: $memoryGb, memoryType: $memoryType, memoryBusBit: $memoryBusBit, memoryBandwidthGbps: $memoryBandwidthGbps, baseClockMhz: $baseClockMhz, boostClockMhz: $boostClockMhz, tdpW: $tdpW, pcieVersion: $pcieVersion, fp32Tflops: $fp32Tflops, blenderScore: $blenderScore, score: $score, verified: $verified, sourceUrls: $sourceUrls, url: $url)';
  }
}

/// @nodoc
abstract mixin class $GpuCopyWith<$Res> {
  factory $GpuCopyWith(Gpu value, $Res Function(Gpu) _then) = _$GpuCopyWithImpl;
  @useResult
  $Res call(
      {String slug,
      String name,
      int? id,
      Brand? manufacturer,
      String? architecture,
      String? releaseDate,
      int? msrpUsd,
      int? cudaCores,
      int? streamProcessors,
      int? rtCores,
      int? tensorCores,
      double? memoryGb,
      String? memoryType,
      int? memoryBusBit,
      double? memoryBandwidthGbps,
      int? baseClockMhz,
      int? boostClockMhz,
      int? tdpW,
      String? pcieVersion,
      double? fp32Tflops,
      double? blenderScore,
      GpuScore? score,
      bool verified,
      List<String> sourceUrls,
      String? url});

  $BrandCopyWith<$Res>? get manufacturer;
  $GpuScoreCopyWith<$Res>? get score;
}

/// @nodoc
class _$GpuCopyWithImpl<$Res> implements $GpuCopyWith<$Res> {
  _$GpuCopyWithImpl(this._self, this._then);

  final Gpu _self;
  final $Res Function(Gpu) _then;

  /// Create a copy of Gpu
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? id = freezed,
    Object? manufacturer = freezed,
    Object? architecture = freezed,
    Object? releaseDate = freezed,
    Object? msrpUsd = freezed,
    Object? cudaCores = freezed,
    Object? streamProcessors = freezed,
    Object? rtCores = freezed,
    Object? tensorCores = freezed,
    Object? memoryGb = freezed,
    Object? memoryType = freezed,
    Object? memoryBusBit = freezed,
    Object? memoryBandwidthGbps = freezed,
    Object? baseClockMhz = freezed,
    Object? boostClockMhz = freezed,
    Object? tdpW = freezed,
    Object? pcieVersion = freezed,
    Object? fp32Tflops = freezed,
    Object? blenderScore = freezed,
    Object? score = freezed,
    Object? verified = null,
    Object? sourceUrls = null,
    Object? url = freezed,
  }) {
    return _then(_self.copyWith(
      slug: null == slug
          ? _self.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      manufacturer: freezed == manufacturer
          ? _self.manufacturer
          : manufacturer // ignore: cast_nullable_to_non_nullable
              as Brand?,
      architecture: freezed == architecture
          ? _self.architecture
          : architecture // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseDate: freezed == releaseDate
          ? _self.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      msrpUsd: freezed == msrpUsd
          ? _self.msrpUsd
          : msrpUsd // ignore: cast_nullable_to_non_nullable
              as int?,
      cudaCores: freezed == cudaCores
          ? _self.cudaCores
          : cudaCores // ignore: cast_nullable_to_non_nullable
              as int?,
      streamProcessors: freezed == streamProcessors
          ? _self.streamProcessors
          : streamProcessors // ignore: cast_nullable_to_non_nullable
              as int?,
      rtCores: freezed == rtCores
          ? _self.rtCores
          : rtCores // ignore: cast_nullable_to_non_nullable
              as int?,
      tensorCores: freezed == tensorCores
          ? _self.tensorCores
          : tensorCores // ignore: cast_nullable_to_non_nullable
              as int?,
      memoryGb: freezed == memoryGb
          ? _self.memoryGb
          : memoryGb // ignore: cast_nullable_to_non_nullable
              as double?,
      memoryType: freezed == memoryType
          ? _self.memoryType
          : memoryType // ignore: cast_nullable_to_non_nullable
              as String?,
      memoryBusBit: freezed == memoryBusBit
          ? _self.memoryBusBit
          : memoryBusBit // ignore: cast_nullable_to_non_nullable
              as int?,
      memoryBandwidthGbps: freezed == memoryBandwidthGbps
          ? _self.memoryBandwidthGbps
          : memoryBandwidthGbps // ignore: cast_nullable_to_non_nullable
              as double?,
      baseClockMhz: freezed == baseClockMhz
          ? _self.baseClockMhz
          : baseClockMhz // ignore: cast_nullable_to_non_nullable
              as int?,
      boostClockMhz: freezed == boostClockMhz
          ? _self.boostClockMhz
          : boostClockMhz // ignore: cast_nullable_to_non_nullable
              as int?,
      tdpW: freezed == tdpW
          ? _self.tdpW
          : tdpW // ignore: cast_nullable_to_non_nullable
              as int?,
      pcieVersion: freezed == pcieVersion
          ? _self.pcieVersion
          : pcieVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      fp32Tflops: freezed == fp32Tflops
          ? _self.fp32Tflops
          : fp32Tflops // ignore: cast_nullable_to_non_nullable
              as double?,
      blenderScore: freezed == blenderScore
          ? _self.blenderScore
          : blenderScore // ignore: cast_nullable_to_non_nullable
              as double?,
      score: freezed == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as GpuScore?,
      verified: null == verified
          ? _self.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceUrls: null == sourceUrls
          ? _self.sourceUrls
          : sourceUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of Gpu
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
  }

  /// Create a copy of Gpu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GpuScoreCopyWith<$Res>? get score {
    if (_self.score == null) {
      return null;
    }

    return $GpuScoreCopyWith<$Res>(_self.score!, (value) {
      return _then(_self.copyWith(score: value));
    });
  }
}

/// Adds pattern-matching-related methods to [Gpu].
extension GpuPatterns on Gpu {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Gpu value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Gpu() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Gpu value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Gpu():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Gpu value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Gpu() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String slug,
            String name,
            int? id,
            Brand? manufacturer,
            String? architecture,
            String? releaseDate,
            int? msrpUsd,
            int? cudaCores,
            int? streamProcessors,
            int? rtCores,
            int? tensorCores,
            double? memoryGb,
            String? memoryType,
            int? memoryBusBit,
            double? memoryBandwidthGbps,
            int? baseClockMhz,
            int? boostClockMhz,
            int? tdpW,
            String? pcieVersion,
            double? fp32Tflops,
            double? blenderScore,
            GpuScore? score,
            bool verified,
            List<String> sourceUrls,
            String? url)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Gpu() when $default != null:
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.manufacturer,
            _that.architecture,
            _that.releaseDate,
            _that.msrpUsd,
            _that.cudaCores,
            _that.streamProcessors,
            _that.rtCores,
            _that.tensorCores,
            _that.memoryGb,
            _that.memoryType,
            _that.memoryBusBit,
            _that.memoryBandwidthGbps,
            _that.baseClockMhz,
            _that.boostClockMhz,
            _that.tdpW,
            _that.pcieVersion,
            _that.fp32Tflops,
            _that.blenderScore,
            _that.score,
            _that.verified,
            _that.sourceUrls,
            _that.url);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String slug,
            String name,
            int? id,
            Brand? manufacturer,
            String? architecture,
            String? releaseDate,
            int? msrpUsd,
            int? cudaCores,
            int? streamProcessors,
            int? rtCores,
            int? tensorCores,
            double? memoryGb,
            String? memoryType,
            int? memoryBusBit,
            double? memoryBandwidthGbps,
            int? baseClockMhz,
            int? boostClockMhz,
            int? tdpW,
            String? pcieVersion,
            double? fp32Tflops,
            double? blenderScore,
            GpuScore? score,
            bool verified,
            List<String> sourceUrls,
            String? url)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Gpu():
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.manufacturer,
            _that.architecture,
            _that.releaseDate,
            _that.msrpUsd,
            _that.cudaCores,
            _that.streamProcessors,
            _that.rtCores,
            _that.tensorCores,
            _that.memoryGb,
            _that.memoryType,
            _that.memoryBusBit,
            _that.memoryBandwidthGbps,
            _that.baseClockMhz,
            _that.boostClockMhz,
            _that.tdpW,
            _that.pcieVersion,
            _that.fp32Tflops,
            _that.blenderScore,
            _that.score,
            _that.verified,
            _that.sourceUrls,
            _that.url);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String slug,
            String name,
            int? id,
            Brand? manufacturer,
            String? architecture,
            String? releaseDate,
            int? msrpUsd,
            int? cudaCores,
            int? streamProcessors,
            int? rtCores,
            int? tensorCores,
            double? memoryGb,
            String? memoryType,
            int? memoryBusBit,
            double? memoryBandwidthGbps,
            int? baseClockMhz,
            int? boostClockMhz,
            int? tdpW,
            String? pcieVersion,
            double? fp32Tflops,
            double? blenderScore,
            GpuScore? score,
            bool verified,
            List<String> sourceUrls,
            String? url)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Gpu() when $default != null:
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.manufacturer,
            _that.architecture,
            _that.releaseDate,
            _that.msrpUsd,
            _that.cudaCores,
            _that.streamProcessors,
            _that.rtCores,
            _that.tensorCores,
            _that.memoryGb,
            _that.memoryType,
            _that.memoryBusBit,
            _that.memoryBandwidthGbps,
            _that.baseClockMhz,
            _that.boostClockMhz,
            _that.tdpW,
            _that.pcieVersion,
            _that.fp32Tflops,
            _that.blenderScore,
            _that.score,
            _that.verified,
            _that.sourceUrls,
            _that.url);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Gpu implements Gpu {
  const _Gpu(
      {required this.slug,
      required this.name,
      this.id,
      this.manufacturer,
      this.architecture,
      this.releaseDate,
      this.msrpUsd,
      this.cudaCores,
      this.streamProcessors,
      this.rtCores,
      this.tensorCores,
      this.memoryGb,
      this.memoryType,
      this.memoryBusBit,
      this.memoryBandwidthGbps,
      this.baseClockMhz,
      this.boostClockMhz,
      this.tdpW,
      this.pcieVersion,
      this.fp32Tflops,
      this.blenderScore,
      this.score,
      this.verified = false,
      final List<String> sourceUrls = const <String>[],
      this.url})
      : _sourceUrls = sourceUrls;
  factory _Gpu.fromJson(Map<String, dynamic> json) => _$GpuFromJson(json);

  @override
  final String slug;
  @override
  final String name;
  @override
  final int? id;
  @override
  final Brand? manufacturer;
  @override
  final String? architecture;
  @override
  final String? releaseDate;
  @override
  final int? msrpUsd;
  @override
  final int? cudaCores;
  @override
  final int? streamProcessors;
  @override
  final int? rtCores;
  @override
  final int? tensorCores;
  @override
  final double? memoryGb;
  @override
  final String? memoryType;
  @override
  final int? memoryBusBit;
  @override
  final double? memoryBandwidthGbps;
  @override
  final int? baseClockMhz;
  @override
  final int? boostClockMhz;
  @override
  final int? tdpW;
  @override
  final String? pcieVersion;
  @override
  final double? fp32Tflops;
  @override
  final double? blenderScore;
  @override
  final GpuScore? score;
  @override
  @JsonKey()
  final bool verified;
  final List<String> _sourceUrls;
  @override
  @JsonKey()
  List<String> get sourceUrls {
    if (_sourceUrls is EqualUnmodifiableListView) return _sourceUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sourceUrls);
  }

  @override
  final String? url;

  /// Create a copy of Gpu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GpuCopyWith<_Gpu> get copyWith =>
      __$GpuCopyWithImpl<_Gpu>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GpuToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Gpu &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.manufacturer, manufacturer) ||
                other.manufacturer == manufacturer) &&
            (identical(other.architecture, architecture) ||
                other.architecture == architecture) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.msrpUsd, msrpUsd) || other.msrpUsd == msrpUsd) &&
            (identical(other.cudaCores, cudaCores) ||
                other.cudaCores == cudaCores) &&
            (identical(other.streamProcessors, streamProcessors) ||
                other.streamProcessors == streamProcessors) &&
            (identical(other.rtCores, rtCores) || other.rtCores == rtCores) &&
            (identical(other.tensorCores, tensorCores) ||
                other.tensorCores == tensorCores) &&
            (identical(other.memoryGb, memoryGb) ||
                other.memoryGb == memoryGb) &&
            (identical(other.memoryType, memoryType) ||
                other.memoryType == memoryType) &&
            (identical(other.memoryBusBit, memoryBusBit) ||
                other.memoryBusBit == memoryBusBit) &&
            (identical(other.memoryBandwidthGbps, memoryBandwidthGbps) ||
                other.memoryBandwidthGbps == memoryBandwidthGbps) &&
            (identical(other.baseClockMhz, baseClockMhz) ||
                other.baseClockMhz == baseClockMhz) &&
            (identical(other.boostClockMhz, boostClockMhz) ||
                other.boostClockMhz == boostClockMhz) &&
            (identical(other.tdpW, tdpW) || other.tdpW == tdpW) &&
            (identical(other.pcieVersion, pcieVersion) ||
                other.pcieVersion == pcieVersion) &&
            (identical(other.fp32Tflops, fp32Tflops) ||
                other.fp32Tflops == fp32Tflops) &&
            (identical(other.blenderScore, blenderScore) ||
                other.blenderScore == blenderScore) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            const DeepCollectionEquality()
                .equals(other._sourceUrls, _sourceUrls) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        slug,
        name,
        id,
        manufacturer,
        architecture,
        releaseDate,
        msrpUsd,
        cudaCores,
        streamProcessors,
        rtCores,
        tensorCores,
        memoryGb,
        memoryType,
        memoryBusBit,
        memoryBandwidthGbps,
        baseClockMhz,
        boostClockMhz,
        tdpW,
        pcieVersion,
        fp32Tflops,
        blenderScore,
        score,
        verified,
        const DeepCollectionEquality().hash(_sourceUrls),
        url
      ]);

  @override
  String toString() {
    return 'Gpu(slug: $slug, name: $name, id: $id, manufacturer: $manufacturer, architecture: $architecture, releaseDate: $releaseDate, msrpUsd: $msrpUsd, cudaCores: $cudaCores, streamProcessors: $streamProcessors, rtCores: $rtCores, tensorCores: $tensorCores, memoryGb: $memoryGb, memoryType: $memoryType, memoryBusBit: $memoryBusBit, memoryBandwidthGbps: $memoryBandwidthGbps, baseClockMhz: $baseClockMhz, boostClockMhz: $boostClockMhz, tdpW: $tdpW, pcieVersion: $pcieVersion, fp32Tflops: $fp32Tflops, blenderScore: $blenderScore, score: $score, verified: $verified, sourceUrls: $sourceUrls, url: $url)';
  }
}

/// @nodoc
abstract mixin class _$GpuCopyWith<$Res> implements $GpuCopyWith<$Res> {
  factory _$GpuCopyWith(_Gpu value, $Res Function(_Gpu) _then) =
      __$GpuCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String slug,
      String name,
      int? id,
      Brand? manufacturer,
      String? architecture,
      String? releaseDate,
      int? msrpUsd,
      int? cudaCores,
      int? streamProcessors,
      int? rtCores,
      int? tensorCores,
      double? memoryGb,
      String? memoryType,
      int? memoryBusBit,
      double? memoryBandwidthGbps,
      int? baseClockMhz,
      int? boostClockMhz,
      int? tdpW,
      String? pcieVersion,
      double? fp32Tflops,
      double? blenderScore,
      GpuScore? score,
      bool verified,
      List<String> sourceUrls,
      String? url});

  @override
  $BrandCopyWith<$Res>? get manufacturer;
  @override
  $GpuScoreCopyWith<$Res>? get score;
}

/// @nodoc
class __$GpuCopyWithImpl<$Res> implements _$GpuCopyWith<$Res> {
  __$GpuCopyWithImpl(this._self, this._then);

  final _Gpu _self;
  final $Res Function(_Gpu) _then;

  /// Create a copy of Gpu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? id = freezed,
    Object? manufacturer = freezed,
    Object? architecture = freezed,
    Object? releaseDate = freezed,
    Object? msrpUsd = freezed,
    Object? cudaCores = freezed,
    Object? streamProcessors = freezed,
    Object? rtCores = freezed,
    Object? tensorCores = freezed,
    Object? memoryGb = freezed,
    Object? memoryType = freezed,
    Object? memoryBusBit = freezed,
    Object? memoryBandwidthGbps = freezed,
    Object? baseClockMhz = freezed,
    Object? boostClockMhz = freezed,
    Object? tdpW = freezed,
    Object? pcieVersion = freezed,
    Object? fp32Tflops = freezed,
    Object? blenderScore = freezed,
    Object? score = freezed,
    Object? verified = null,
    Object? sourceUrls = null,
    Object? url = freezed,
  }) {
    return _then(_Gpu(
      slug: null == slug
          ? _self.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      manufacturer: freezed == manufacturer
          ? _self.manufacturer
          : manufacturer // ignore: cast_nullable_to_non_nullable
              as Brand?,
      architecture: freezed == architecture
          ? _self.architecture
          : architecture // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseDate: freezed == releaseDate
          ? _self.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      msrpUsd: freezed == msrpUsd
          ? _self.msrpUsd
          : msrpUsd // ignore: cast_nullable_to_non_nullable
              as int?,
      cudaCores: freezed == cudaCores
          ? _self.cudaCores
          : cudaCores // ignore: cast_nullable_to_non_nullable
              as int?,
      streamProcessors: freezed == streamProcessors
          ? _self.streamProcessors
          : streamProcessors // ignore: cast_nullable_to_non_nullable
              as int?,
      rtCores: freezed == rtCores
          ? _self.rtCores
          : rtCores // ignore: cast_nullable_to_non_nullable
              as int?,
      tensorCores: freezed == tensorCores
          ? _self.tensorCores
          : tensorCores // ignore: cast_nullable_to_non_nullable
              as int?,
      memoryGb: freezed == memoryGb
          ? _self.memoryGb
          : memoryGb // ignore: cast_nullable_to_non_nullable
              as double?,
      memoryType: freezed == memoryType
          ? _self.memoryType
          : memoryType // ignore: cast_nullable_to_non_nullable
              as String?,
      memoryBusBit: freezed == memoryBusBit
          ? _self.memoryBusBit
          : memoryBusBit // ignore: cast_nullable_to_non_nullable
              as int?,
      memoryBandwidthGbps: freezed == memoryBandwidthGbps
          ? _self.memoryBandwidthGbps
          : memoryBandwidthGbps // ignore: cast_nullable_to_non_nullable
              as double?,
      baseClockMhz: freezed == baseClockMhz
          ? _self.baseClockMhz
          : baseClockMhz // ignore: cast_nullable_to_non_nullable
              as int?,
      boostClockMhz: freezed == boostClockMhz
          ? _self.boostClockMhz
          : boostClockMhz // ignore: cast_nullable_to_non_nullable
              as int?,
      tdpW: freezed == tdpW
          ? _self.tdpW
          : tdpW // ignore: cast_nullable_to_non_nullable
              as int?,
      pcieVersion: freezed == pcieVersion
          ? _self.pcieVersion
          : pcieVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      fp32Tflops: freezed == fp32Tflops
          ? _self.fp32Tflops
          : fp32Tflops // ignore: cast_nullable_to_non_nullable
              as double?,
      blenderScore: freezed == blenderScore
          ? _self.blenderScore
          : blenderScore // ignore: cast_nullable_to_non_nullable
              as double?,
      score: freezed == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as GpuScore?,
      verified: null == verified
          ? _self.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceUrls: null == sourceUrls
          ? _self._sourceUrls
          : sourceUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of Gpu
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
  }

  /// Create a copy of Gpu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $GpuScoreCopyWith<$Res>? get score {
    if (_self.score == null) {
      return null;
    }

    return $GpuScoreCopyWith<$Res>(_self.score!, (value) {
      return _then(_self.copyWith(score: value));
    });
  }
}

// dart format on
