// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cpu.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Cpu {
  String get slug;
  String get name;
  int? get id;
  Brand? get manufacturer;
  String? get releaseDate;

  /// `desktop` / `laptop` / `server` 등.
  String? get segment;
  String? get architecture;
  String? get socket;

  /// 공정. CPU는 `TSMC N4` 같은 문자열이라 SoC의 `processNm`과 타입이 다르다.
  String? get processNode;
  int? get cores;
  int? get threads;

  /// 하이브리드 구조에서만 채워진다.
  int? get pCores;
  int? get eCores;
  double? get baseClockGhz;
  double? get boostClockGhz;
  double? get l3CacheMb;
  int? get tdpW;
  int? get maxTdpW;
  String? get integratedGraphics;
  String? get memorySupport;
  int? get msrpUsd;
  CpuScore? get score;
  bool get verified;
  List<String> get sourceUrls;
  String? get url;

  /// Create a copy of Cpu
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CpuCopyWith<Cpu> get copyWith =>
      _$CpuCopyWithImpl<Cpu>(this as Cpu, _$identity);

  /// Serializes this Cpu to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Cpu &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.manufacturer, manufacturer) ||
                other.manufacturer == manufacturer) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.segment, segment) || other.segment == segment) &&
            (identical(other.architecture, architecture) ||
                other.architecture == architecture) &&
            (identical(other.socket, socket) || other.socket == socket) &&
            (identical(other.processNode, processNode) ||
                other.processNode == processNode) &&
            (identical(other.cores, cores) || other.cores == cores) &&
            (identical(other.threads, threads) || other.threads == threads) &&
            (identical(other.pCores, pCores) || other.pCores == pCores) &&
            (identical(other.eCores, eCores) || other.eCores == eCores) &&
            (identical(other.baseClockGhz, baseClockGhz) ||
                other.baseClockGhz == baseClockGhz) &&
            (identical(other.boostClockGhz, boostClockGhz) ||
                other.boostClockGhz == boostClockGhz) &&
            (identical(other.l3CacheMb, l3CacheMb) ||
                other.l3CacheMb == l3CacheMb) &&
            (identical(other.tdpW, tdpW) || other.tdpW == tdpW) &&
            (identical(other.maxTdpW, maxTdpW) || other.maxTdpW == maxTdpW) &&
            (identical(other.integratedGraphics, integratedGraphics) ||
                other.integratedGraphics == integratedGraphics) &&
            (identical(other.memorySupport, memorySupport) ||
                other.memorySupport == memorySupport) &&
            (identical(other.msrpUsd, msrpUsd) || other.msrpUsd == msrpUsd) &&
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
        releaseDate,
        segment,
        architecture,
        socket,
        processNode,
        cores,
        threads,
        pCores,
        eCores,
        baseClockGhz,
        boostClockGhz,
        l3CacheMb,
        tdpW,
        maxTdpW,
        integratedGraphics,
        memorySupport,
        msrpUsd,
        score,
        verified,
        const DeepCollectionEquality().hash(sourceUrls),
        url
      ]);

  @override
  String toString() {
    return 'Cpu(slug: $slug, name: $name, id: $id, manufacturer: $manufacturer, releaseDate: $releaseDate, segment: $segment, architecture: $architecture, socket: $socket, processNode: $processNode, cores: $cores, threads: $threads, pCores: $pCores, eCores: $eCores, baseClockGhz: $baseClockGhz, boostClockGhz: $boostClockGhz, l3CacheMb: $l3CacheMb, tdpW: $tdpW, maxTdpW: $maxTdpW, integratedGraphics: $integratedGraphics, memorySupport: $memorySupport, msrpUsd: $msrpUsd, score: $score, verified: $verified, sourceUrls: $sourceUrls, url: $url)';
  }
}

/// @nodoc
abstract mixin class $CpuCopyWith<$Res> {
  factory $CpuCopyWith(Cpu value, $Res Function(Cpu) _then) = _$CpuCopyWithImpl;
  @useResult
  $Res call(
      {String slug,
      String name,
      int? id,
      Brand? manufacturer,
      String? releaseDate,
      String? segment,
      String? architecture,
      String? socket,
      String? processNode,
      int? cores,
      int? threads,
      int? pCores,
      int? eCores,
      double? baseClockGhz,
      double? boostClockGhz,
      double? l3CacheMb,
      int? tdpW,
      int? maxTdpW,
      String? integratedGraphics,
      String? memorySupport,
      int? msrpUsd,
      CpuScore? score,
      bool verified,
      List<String> sourceUrls,
      String? url});

  $BrandCopyWith<$Res>? get manufacturer;
  $CpuScoreCopyWith<$Res>? get score;
}

/// @nodoc
class _$CpuCopyWithImpl<$Res> implements $CpuCopyWith<$Res> {
  _$CpuCopyWithImpl(this._self, this._then);

  final Cpu _self;
  final $Res Function(Cpu) _then;

  /// Create a copy of Cpu
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? id = freezed,
    Object? manufacturer = freezed,
    Object? releaseDate = freezed,
    Object? segment = freezed,
    Object? architecture = freezed,
    Object? socket = freezed,
    Object? processNode = freezed,
    Object? cores = freezed,
    Object? threads = freezed,
    Object? pCores = freezed,
    Object? eCores = freezed,
    Object? baseClockGhz = freezed,
    Object? boostClockGhz = freezed,
    Object? l3CacheMb = freezed,
    Object? tdpW = freezed,
    Object? maxTdpW = freezed,
    Object? integratedGraphics = freezed,
    Object? memorySupport = freezed,
    Object? msrpUsd = freezed,
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
      releaseDate: freezed == releaseDate
          ? _self.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      segment: freezed == segment
          ? _self.segment
          : segment // ignore: cast_nullable_to_non_nullable
              as String?,
      architecture: freezed == architecture
          ? _self.architecture
          : architecture // ignore: cast_nullable_to_non_nullable
              as String?,
      socket: freezed == socket
          ? _self.socket
          : socket // ignore: cast_nullable_to_non_nullable
              as String?,
      processNode: freezed == processNode
          ? _self.processNode
          : processNode // ignore: cast_nullable_to_non_nullable
              as String?,
      cores: freezed == cores
          ? _self.cores
          : cores // ignore: cast_nullable_to_non_nullable
              as int?,
      threads: freezed == threads
          ? _self.threads
          : threads // ignore: cast_nullable_to_non_nullable
              as int?,
      pCores: freezed == pCores
          ? _self.pCores
          : pCores // ignore: cast_nullable_to_non_nullable
              as int?,
      eCores: freezed == eCores
          ? _self.eCores
          : eCores // ignore: cast_nullable_to_non_nullable
              as int?,
      baseClockGhz: freezed == baseClockGhz
          ? _self.baseClockGhz
          : baseClockGhz // ignore: cast_nullable_to_non_nullable
              as double?,
      boostClockGhz: freezed == boostClockGhz
          ? _self.boostClockGhz
          : boostClockGhz // ignore: cast_nullable_to_non_nullable
              as double?,
      l3CacheMb: freezed == l3CacheMb
          ? _self.l3CacheMb
          : l3CacheMb // ignore: cast_nullable_to_non_nullable
              as double?,
      tdpW: freezed == tdpW
          ? _self.tdpW
          : tdpW // ignore: cast_nullable_to_non_nullable
              as int?,
      maxTdpW: freezed == maxTdpW
          ? _self.maxTdpW
          : maxTdpW // ignore: cast_nullable_to_non_nullable
              as int?,
      integratedGraphics: freezed == integratedGraphics
          ? _self.integratedGraphics
          : integratedGraphics // ignore: cast_nullable_to_non_nullable
              as String?,
      memorySupport: freezed == memorySupport
          ? _self.memorySupport
          : memorySupport // ignore: cast_nullable_to_non_nullable
              as String?,
      msrpUsd: freezed == msrpUsd
          ? _self.msrpUsd
          : msrpUsd // ignore: cast_nullable_to_non_nullable
              as int?,
      score: freezed == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as CpuScore?,
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

  /// Create a copy of Cpu
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

  /// Create a copy of Cpu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CpuScoreCopyWith<$Res>? get score {
    if (_self.score == null) {
      return null;
    }

    return $CpuScoreCopyWith<$Res>(_self.score!, (value) {
      return _then(_self.copyWith(score: value));
    });
  }
}

/// Adds pattern-matching-related methods to [Cpu].
extension CpuPatterns on Cpu {
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
    TResult Function(_Cpu value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Cpu() when $default != null:
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
    TResult Function(_Cpu value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Cpu():
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
    TResult? Function(_Cpu value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Cpu() when $default != null:
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
            String? releaseDate,
            String? segment,
            String? architecture,
            String? socket,
            String? processNode,
            int? cores,
            int? threads,
            int? pCores,
            int? eCores,
            double? baseClockGhz,
            double? boostClockGhz,
            double? l3CacheMb,
            int? tdpW,
            int? maxTdpW,
            String? integratedGraphics,
            String? memorySupport,
            int? msrpUsd,
            CpuScore? score,
            bool verified,
            List<String> sourceUrls,
            String? url)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Cpu() when $default != null:
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.manufacturer,
            _that.releaseDate,
            _that.segment,
            _that.architecture,
            _that.socket,
            _that.processNode,
            _that.cores,
            _that.threads,
            _that.pCores,
            _that.eCores,
            _that.baseClockGhz,
            _that.boostClockGhz,
            _that.l3CacheMb,
            _that.tdpW,
            _that.maxTdpW,
            _that.integratedGraphics,
            _that.memorySupport,
            _that.msrpUsd,
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
            String? releaseDate,
            String? segment,
            String? architecture,
            String? socket,
            String? processNode,
            int? cores,
            int? threads,
            int? pCores,
            int? eCores,
            double? baseClockGhz,
            double? boostClockGhz,
            double? l3CacheMb,
            int? tdpW,
            int? maxTdpW,
            String? integratedGraphics,
            String? memorySupport,
            int? msrpUsd,
            CpuScore? score,
            bool verified,
            List<String> sourceUrls,
            String? url)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Cpu():
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.manufacturer,
            _that.releaseDate,
            _that.segment,
            _that.architecture,
            _that.socket,
            _that.processNode,
            _that.cores,
            _that.threads,
            _that.pCores,
            _that.eCores,
            _that.baseClockGhz,
            _that.boostClockGhz,
            _that.l3CacheMb,
            _that.tdpW,
            _that.maxTdpW,
            _that.integratedGraphics,
            _that.memorySupport,
            _that.msrpUsd,
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
            String? releaseDate,
            String? segment,
            String? architecture,
            String? socket,
            String? processNode,
            int? cores,
            int? threads,
            int? pCores,
            int? eCores,
            double? baseClockGhz,
            double? boostClockGhz,
            double? l3CacheMb,
            int? tdpW,
            int? maxTdpW,
            String? integratedGraphics,
            String? memorySupport,
            int? msrpUsd,
            CpuScore? score,
            bool verified,
            List<String> sourceUrls,
            String? url)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Cpu() when $default != null:
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.manufacturer,
            _that.releaseDate,
            _that.segment,
            _that.architecture,
            _that.socket,
            _that.processNode,
            _that.cores,
            _that.threads,
            _that.pCores,
            _that.eCores,
            _that.baseClockGhz,
            _that.boostClockGhz,
            _that.l3CacheMb,
            _that.tdpW,
            _that.maxTdpW,
            _that.integratedGraphics,
            _that.memorySupport,
            _that.msrpUsd,
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
class _Cpu implements Cpu {
  const _Cpu(
      {required this.slug,
      required this.name,
      this.id,
      this.manufacturer,
      this.releaseDate,
      this.segment,
      this.architecture,
      this.socket,
      this.processNode,
      this.cores,
      this.threads,
      this.pCores,
      this.eCores,
      this.baseClockGhz,
      this.boostClockGhz,
      this.l3CacheMb,
      this.tdpW,
      this.maxTdpW,
      this.integratedGraphics,
      this.memorySupport,
      this.msrpUsd,
      this.score,
      this.verified = false,
      final List<String> sourceUrls = const <String>[],
      this.url})
      : _sourceUrls = sourceUrls;
  factory _Cpu.fromJson(Map<String, dynamic> json) => _$CpuFromJson(json);

  @override
  final String slug;
  @override
  final String name;
  @override
  final int? id;
  @override
  final Brand? manufacturer;
  @override
  final String? releaseDate;

  /// `desktop` / `laptop` / `server` 등.
  @override
  final String? segment;
  @override
  final String? architecture;
  @override
  final String? socket;

  /// 공정. CPU는 `TSMC N4` 같은 문자열이라 SoC의 `processNm`과 타입이 다르다.
  @override
  final String? processNode;
  @override
  final int? cores;
  @override
  final int? threads;

  /// 하이브리드 구조에서만 채워진다.
  @override
  final int? pCores;
  @override
  final int? eCores;
  @override
  final double? baseClockGhz;
  @override
  final double? boostClockGhz;
  @override
  final double? l3CacheMb;
  @override
  final int? tdpW;
  @override
  final int? maxTdpW;
  @override
  final String? integratedGraphics;
  @override
  final String? memorySupport;
  @override
  final int? msrpUsd;
  @override
  final CpuScore? score;
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

  /// Create a copy of Cpu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CpuCopyWith<_Cpu> get copyWith =>
      __$CpuCopyWithImpl<_Cpu>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CpuToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Cpu &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.manufacturer, manufacturer) ||
                other.manufacturer == manufacturer) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.segment, segment) || other.segment == segment) &&
            (identical(other.architecture, architecture) ||
                other.architecture == architecture) &&
            (identical(other.socket, socket) || other.socket == socket) &&
            (identical(other.processNode, processNode) ||
                other.processNode == processNode) &&
            (identical(other.cores, cores) || other.cores == cores) &&
            (identical(other.threads, threads) || other.threads == threads) &&
            (identical(other.pCores, pCores) || other.pCores == pCores) &&
            (identical(other.eCores, eCores) || other.eCores == eCores) &&
            (identical(other.baseClockGhz, baseClockGhz) ||
                other.baseClockGhz == baseClockGhz) &&
            (identical(other.boostClockGhz, boostClockGhz) ||
                other.boostClockGhz == boostClockGhz) &&
            (identical(other.l3CacheMb, l3CacheMb) ||
                other.l3CacheMb == l3CacheMb) &&
            (identical(other.tdpW, tdpW) || other.tdpW == tdpW) &&
            (identical(other.maxTdpW, maxTdpW) || other.maxTdpW == maxTdpW) &&
            (identical(other.integratedGraphics, integratedGraphics) ||
                other.integratedGraphics == integratedGraphics) &&
            (identical(other.memorySupport, memorySupport) ||
                other.memorySupport == memorySupport) &&
            (identical(other.msrpUsd, msrpUsd) || other.msrpUsd == msrpUsd) &&
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
        releaseDate,
        segment,
        architecture,
        socket,
        processNode,
        cores,
        threads,
        pCores,
        eCores,
        baseClockGhz,
        boostClockGhz,
        l3CacheMb,
        tdpW,
        maxTdpW,
        integratedGraphics,
        memorySupport,
        msrpUsd,
        score,
        verified,
        const DeepCollectionEquality().hash(_sourceUrls),
        url
      ]);

  @override
  String toString() {
    return 'Cpu(slug: $slug, name: $name, id: $id, manufacturer: $manufacturer, releaseDate: $releaseDate, segment: $segment, architecture: $architecture, socket: $socket, processNode: $processNode, cores: $cores, threads: $threads, pCores: $pCores, eCores: $eCores, baseClockGhz: $baseClockGhz, boostClockGhz: $boostClockGhz, l3CacheMb: $l3CacheMb, tdpW: $tdpW, maxTdpW: $maxTdpW, integratedGraphics: $integratedGraphics, memorySupport: $memorySupport, msrpUsd: $msrpUsd, score: $score, verified: $verified, sourceUrls: $sourceUrls, url: $url)';
  }
}

/// @nodoc
abstract mixin class _$CpuCopyWith<$Res> implements $CpuCopyWith<$Res> {
  factory _$CpuCopyWith(_Cpu value, $Res Function(_Cpu) _then) =
      __$CpuCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String slug,
      String name,
      int? id,
      Brand? manufacturer,
      String? releaseDate,
      String? segment,
      String? architecture,
      String? socket,
      String? processNode,
      int? cores,
      int? threads,
      int? pCores,
      int? eCores,
      double? baseClockGhz,
      double? boostClockGhz,
      double? l3CacheMb,
      int? tdpW,
      int? maxTdpW,
      String? integratedGraphics,
      String? memorySupport,
      int? msrpUsd,
      CpuScore? score,
      bool verified,
      List<String> sourceUrls,
      String? url});

  @override
  $BrandCopyWith<$Res>? get manufacturer;
  @override
  $CpuScoreCopyWith<$Res>? get score;
}

/// @nodoc
class __$CpuCopyWithImpl<$Res> implements _$CpuCopyWith<$Res> {
  __$CpuCopyWithImpl(this._self, this._then);

  final _Cpu _self;
  final $Res Function(_Cpu) _then;

  /// Create a copy of Cpu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? id = freezed,
    Object? manufacturer = freezed,
    Object? releaseDate = freezed,
    Object? segment = freezed,
    Object? architecture = freezed,
    Object? socket = freezed,
    Object? processNode = freezed,
    Object? cores = freezed,
    Object? threads = freezed,
    Object? pCores = freezed,
    Object? eCores = freezed,
    Object? baseClockGhz = freezed,
    Object? boostClockGhz = freezed,
    Object? l3CacheMb = freezed,
    Object? tdpW = freezed,
    Object? maxTdpW = freezed,
    Object? integratedGraphics = freezed,
    Object? memorySupport = freezed,
    Object? msrpUsd = freezed,
    Object? score = freezed,
    Object? verified = null,
    Object? sourceUrls = null,
    Object? url = freezed,
  }) {
    return _then(_Cpu(
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
      releaseDate: freezed == releaseDate
          ? _self.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      segment: freezed == segment
          ? _self.segment
          : segment // ignore: cast_nullable_to_non_nullable
              as String?,
      architecture: freezed == architecture
          ? _self.architecture
          : architecture // ignore: cast_nullable_to_non_nullable
              as String?,
      socket: freezed == socket
          ? _self.socket
          : socket // ignore: cast_nullable_to_non_nullable
              as String?,
      processNode: freezed == processNode
          ? _self.processNode
          : processNode // ignore: cast_nullable_to_non_nullable
              as String?,
      cores: freezed == cores
          ? _self.cores
          : cores // ignore: cast_nullable_to_non_nullable
              as int?,
      threads: freezed == threads
          ? _self.threads
          : threads // ignore: cast_nullable_to_non_nullable
              as int?,
      pCores: freezed == pCores
          ? _self.pCores
          : pCores // ignore: cast_nullable_to_non_nullable
              as int?,
      eCores: freezed == eCores
          ? _self.eCores
          : eCores // ignore: cast_nullable_to_non_nullable
              as int?,
      baseClockGhz: freezed == baseClockGhz
          ? _self.baseClockGhz
          : baseClockGhz // ignore: cast_nullable_to_non_nullable
              as double?,
      boostClockGhz: freezed == boostClockGhz
          ? _self.boostClockGhz
          : boostClockGhz // ignore: cast_nullable_to_non_nullable
              as double?,
      l3CacheMb: freezed == l3CacheMb
          ? _self.l3CacheMb
          : l3CacheMb // ignore: cast_nullable_to_non_nullable
              as double?,
      tdpW: freezed == tdpW
          ? _self.tdpW
          : tdpW // ignore: cast_nullable_to_non_nullable
              as int?,
      maxTdpW: freezed == maxTdpW
          ? _self.maxTdpW
          : maxTdpW // ignore: cast_nullable_to_non_nullable
              as int?,
      integratedGraphics: freezed == integratedGraphics
          ? _self.integratedGraphics
          : integratedGraphics // ignore: cast_nullable_to_non_nullable
              as String?,
      memorySupport: freezed == memorySupport
          ? _self.memorySupport
          : memorySupport // ignore: cast_nullable_to_non_nullable
              as String?,
      msrpUsd: freezed == msrpUsd
          ? _self.msrpUsd
          : msrpUsd // ignore: cast_nullable_to_non_nullable
              as int?,
      score: freezed == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as CpuScore?,
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

  /// Create a copy of Cpu
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

  /// Create a copy of Cpu
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CpuScoreCopyWith<$Res>? get score {
    if (_self.score == null) {
      return null;
    }

    return $CpuScoreCopyWith<$Res>(_self.score!, (value) {
      return _then(_self.copyWith(score: value));
    });
  }
}

// dart format on
