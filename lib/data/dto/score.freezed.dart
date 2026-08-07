// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'score.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScoreMetric {
  /// 0–100 정규화 지수.
  double? get index;

  /// 같은 세대 안에서의 백분위.
  double? get percentile;

  /// S / A / B / C … 등급.
  String? get tier;

  /// 비교 기준이 된 세대 (예: `2024-2026`).
  String? get era;

  /// 원본 벤치마크 (예: `geekbench`, `timespy_score`).
  String? get source;

  /// Create a copy of ScoreMetric
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<ScoreMetric> get copyWith =>
      _$ScoreMetricCopyWithImpl<ScoreMetric>(this as ScoreMetric, _$identity);

  /// Serializes this ScoreMetric to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScoreMetric &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.percentile, percentile) ||
                other.percentile == percentile) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.era, era) || other.era == era) &&
            (identical(other.source, source) || other.source == source));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, index, percentile, tier, era, source);

  @override
  String toString() {
    return 'ScoreMetric(index: $index, percentile: $percentile, tier: $tier, era: $era, source: $source)';
  }
}

/// @nodoc
abstract mixin class $ScoreMetricCopyWith<$Res> {
  factory $ScoreMetricCopyWith(
          ScoreMetric value, $Res Function(ScoreMetric) _then) =
      _$ScoreMetricCopyWithImpl;
  @useResult
  $Res call(
      {double? index,
      double? percentile,
      String? tier,
      String? era,
      String? source});
}

/// @nodoc
class _$ScoreMetricCopyWithImpl<$Res> implements $ScoreMetricCopyWith<$Res> {
  _$ScoreMetricCopyWithImpl(this._self, this._then);

  final ScoreMetric _self;
  final $Res Function(ScoreMetric) _then;

  /// Create a copy of ScoreMetric
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = freezed,
    Object? percentile = freezed,
    Object? tier = freezed,
    Object? era = freezed,
    Object? source = freezed,
  }) {
    return _then(_self.copyWith(
      index: freezed == index
          ? _self.index
          : index // ignore: cast_nullable_to_non_nullable
              as double?,
      percentile: freezed == percentile
          ? _self.percentile
          : percentile // ignore: cast_nullable_to_non_nullable
              as double?,
      tier: freezed == tier
          ? _self.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String?,
      era: freezed == era
          ? _self.era
          : era // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ScoreMetric].
extension ScoreMetricPatterns on ScoreMetric {
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
    TResult Function(_ScoreMetric value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScoreMetric() when $default != null:
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
    TResult Function(_ScoreMetric value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScoreMetric():
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
    TResult? Function(_ScoreMetric value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScoreMetric() when $default != null:
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
    TResult Function(double? index, double? percentile, String? tier,
            String? era, String? source)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScoreMetric() when $default != null:
        return $default(
            _that.index, _that.percentile, _that.tier, _that.era, _that.source);
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
    TResult Function(double? index, double? percentile, String? tier,
            String? era, String? source)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScoreMetric():
        return $default(
            _that.index, _that.percentile, _that.tier, _that.era, _that.source);
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
    TResult? Function(double? index, double? percentile, String? tier,
            String? era, String? source)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScoreMetric() when $default != null:
        return $default(
            _that.index, _that.percentile, _that.tier, _that.era, _that.source);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ScoreMetric implements ScoreMetric {
  const _ScoreMetric(
      {this.index, this.percentile, this.tier, this.era, this.source});
  factory _ScoreMetric.fromJson(Map<String, dynamic> json) =>
      _$ScoreMetricFromJson(json);

  /// 0–100 정규화 지수.
  @override
  final double? index;

  /// 같은 세대 안에서의 백분위.
  @override
  final double? percentile;

  /// S / A / B / C … 등급.
  @override
  final String? tier;

  /// 비교 기준이 된 세대 (예: `2024-2026`).
  @override
  final String? era;

  /// 원본 벤치마크 (예: `geekbench`, `timespy_score`).
  @override
  final String? source;

  /// Create a copy of ScoreMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScoreMetricCopyWith<_ScoreMetric> get copyWith =>
      __$ScoreMetricCopyWithImpl<_ScoreMetric>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ScoreMetricToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScoreMetric &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.percentile, percentile) ||
                other.percentile == percentile) &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.era, era) || other.era == era) &&
            (identical(other.source, source) || other.source == source));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, index, percentile, tier, era, source);

  @override
  String toString() {
    return 'ScoreMetric(index: $index, percentile: $percentile, tier: $tier, era: $era, source: $source)';
  }
}

/// @nodoc
abstract mixin class _$ScoreMetricCopyWith<$Res>
    implements $ScoreMetricCopyWith<$Res> {
  factory _$ScoreMetricCopyWith(
          _ScoreMetric value, $Res Function(_ScoreMetric) _then) =
      __$ScoreMetricCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double? index,
      double? percentile,
      String? tier,
      String? era,
      String? source});
}

/// @nodoc
class __$ScoreMetricCopyWithImpl<$Res> implements _$ScoreMetricCopyWith<$Res> {
  __$ScoreMetricCopyWithImpl(this._self, this._then);

  final _ScoreMetric _self;
  final $Res Function(_ScoreMetric) _then;

  /// Create a copy of ScoreMetric
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? index = freezed,
    Object? percentile = freezed,
    Object? tier = freezed,
    Object? era = freezed,
    Object? source = freezed,
  }) {
    return _then(_ScoreMetric(
      index: freezed == index
          ? _self.index
          : index // ignore: cast_nullable_to_non_nullable
              as double?,
      percentile: freezed == percentile
          ? _self.percentile
          : percentile // ignore: cast_nullable_to_non_nullable
              as double?,
      tier: freezed == tier
          ? _self.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String?,
      era: freezed == era
          ? _self.era
          : era // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _self.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$SmartphoneScore {
  String? get algorithmVersion;
  double? get overall;
  double? get performance;
  double? get camera;
  double? get battery;
  double? get display;

  /// 가격 대비 가치. `msrp_usd`가 없으면 산출되지 않는다.
  double? get value;

  /// 성능 축의 근거가 된 벤치마크 지표.
  ScoreMetric? get perf;

  /// Create a copy of SmartphoneScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SmartphoneScoreCopyWith<SmartphoneScore> get copyWith =>
      _$SmartphoneScoreCopyWithImpl<SmartphoneScore>(
          this as SmartphoneScore, _$identity);

  /// Serializes this SmartphoneScore to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SmartphoneScore &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.performance, performance) ||
                other.performance == performance) &&
            (identical(other.camera, camera) || other.camera == camera) &&
            (identical(other.battery, battery) || other.battery == battery) &&
            (identical(other.display, display) || other.display == display) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.perf, perf) || other.perf == perf));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, algorithmVersion, overall,
      performance, camera, battery, display, value, perf);

  @override
  String toString() {
    return 'SmartphoneScore(algorithmVersion: $algorithmVersion, overall: $overall, performance: $performance, camera: $camera, battery: $battery, display: $display, value: $value, perf: $perf)';
  }
}

/// @nodoc
abstract mixin class $SmartphoneScoreCopyWith<$Res> {
  factory $SmartphoneScoreCopyWith(
          SmartphoneScore value, $Res Function(SmartphoneScore) _then) =
      _$SmartphoneScoreCopyWithImpl;
  @useResult
  $Res call(
      {String? algorithmVersion,
      double? overall,
      double? performance,
      double? camera,
      double? battery,
      double? display,
      double? value,
      ScoreMetric? perf});

  $ScoreMetricCopyWith<$Res>? get perf;
}

/// @nodoc
class _$SmartphoneScoreCopyWithImpl<$Res>
    implements $SmartphoneScoreCopyWith<$Res> {
  _$SmartphoneScoreCopyWithImpl(this._self, this._then);

  final SmartphoneScore _self;
  final $Res Function(SmartphoneScore) _then;

  /// Create a copy of SmartphoneScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithmVersion = freezed,
    Object? overall = freezed,
    Object? performance = freezed,
    Object? camera = freezed,
    Object? battery = freezed,
    Object? display = freezed,
    Object? value = freezed,
    Object? perf = freezed,
  }) {
    return _then(_self.copyWith(
      algorithmVersion: freezed == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      overall: freezed == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double?,
      performance: freezed == performance
          ? _self.performance
          : performance // ignore: cast_nullable_to_non_nullable
              as double?,
      camera: freezed == camera
          ? _self.camera
          : camera // ignore: cast_nullable_to_non_nullable
              as double?,
      battery: freezed == battery
          ? _self.battery
          : battery // ignore: cast_nullable_to_non_nullable
              as double?,
      display: freezed == display
          ? _self.display
          : display // ignore: cast_nullable_to_non_nullable
              as double?,
      value: freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as double?,
      perf: freezed == perf
          ? _self.perf
          : perf // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
    ));
  }

  /// Create a copy of SmartphoneScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get perf {
    if (_self.perf == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.perf!, (value) {
      return _then(_self.copyWith(perf: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SmartphoneScore].
extension SmartphoneScorePatterns on SmartphoneScore {
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
    TResult Function(_SmartphoneScore value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SmartphoneScore() when $default != null:
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
    TResult Function(_SmartphoneScore value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SmartphoneScore():
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
    TResult? Function(_SmartphoneScore value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SmartphoneScore() when $default != null:
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
            String? algorithmVersion,
            double? overall,
            double? performance,
            double? camera,
            double? battery,
            double? display,
            double? value,
            ScoreMetric? perf)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SmartphoneScore() when $default != null:
        return $default(
            _that.algorithmVersion,
            _that.overall,
            _that.performance,
            _that.camera,
            _that.battery,
            _that.display,
            _that.value,
            _that.perf);
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
            String? algorithmVersion,
            double? overall,
            double? performance,
            double? camera,
            double? battery,
            double? display,
            double? value,
            ScoreMetric? perf)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SmartphoneScore():
        return $default(
            _that.algorithmVersion,
            _that.overall,
            _that.performance,
            _that.camera,
            _that.battery,
            _that.display,
            _that.value,
            _that.perf);
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
            String? algorithmVersion,
            double? overall,
            double? performance,
            double? camera,
            double? battery,
            double? display,
            double? value,
            ScoreMetric? perf)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SmartphoneScore() when $default != null:
        return $default(
            _that.algorithmVersion,
            _that.overall,
            _that.performance,
            _that.camera,
            _that.battery,
            _that.display,
            _that.value,
            _that.perf);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SmartphoneScore implements SmartphoneScore {
  const _SmartphoneScore(
      {this.algorithmVersion,
      this.overall,
      this.performance,
      this.camera,
      this.battery,
      this.display,
      this.value,
      this.perf});
  factory _SmartphoneScore.fromJson(Map<String, dynamic> json) =>
      _$SmartphoneScoreFromJson(json);

  @override
  final String? algorithmVersion;
  @override
  final double? overall;
  @override
  final double? performance;
  @override
  final double? camera;
  @override
  final double? battery;
  @override
  final double? display;

  /// 가격 대비 가치. `msrp_usd`가 없으면 산출되지 않는다.
  @override
  final double? value;

  /// 성능 축의 근거가 된 벤치마크 지표.
  @override
  final ScoreMetric? perf;

  /// Create a copy of SmartphoneScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SmartphoneScoreCopyWith<_SmartphoneScore> get copyWith =>
      __$SmartphoneScoreCopyWithImpl<_SmartphoneScore>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SmartphoneScoreToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SmartphoneScore &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.performance, performance) ||
                other.performance == performance) &&
            (identical(other.camera, camera) || other.camera == camera) &&
            (identical(other.battery, battery) || other.battery == battery) &&
            (identical(other.display, display) || other.display == display) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.perf, perf) || other.perf == perf));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, algorithmVersion, overall,
      performance, camera, battery, display, value, perf);

  @override
  String toString() {
    return 'SmartphoneScore(algorithmVersion: $algorithmVersion, overall: $overall, performance: $performance, camera: $camera, battery: $battery, display: $display, value: $value, perf: $perf)';
  }
}

/// @nodoc
abstract mixin class _$SmartphoneScoreCopyWith<$Res>
    implements $SmartphoneScoreCopyWith<$Res> {
  factory _$SmartphoneScoreCopyWith(
          _SmartphoneScore value, $Res Function(_SmartphoneScore) _then) =
      __$SmartphoneScoreCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? algorithmVersion,
      double? overall,
      double? performance,
      double? camera,
      double? battery,
      double? display,
      double? value,
      ScoreMetric? perf});

  @override
  $ScoreMetricCopyWith<$Res>? get perf;
}

/// @nodoc
class __$SmartphoneScoreCopyWithImpl<$Res>
    implements _$SmartphoneScoreCopyWith<$Res> {
  __$SmartphoneScoreCopyWithImpl(this._self, this._then);

  final _SmartphoneScore _self;
  final $Res Function(_SmartphoneScore) _then;

  /// Create a copy of SmartphoneScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? algorithmVersion = freezed,
    Object? overall = freezed,
    Object? performance = freezed,
    Object? camera = freezed,
    Object? battery = freezed,
    Object? display = freezed,
    Object? value = freezed,
    Object? perf = freezed,
  }) {
    return _then(_SmartphoneScore(
      algorithmVersion: freezed == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      overall: freezed == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double?,
      performance: freezed == performance
          ? _self.performance
          : performance // ignore: cast_nullable_to_non_nullable
              as double?,
      camera: freezed == camera
          ? _self.camera
          : camera // ignore: cast_nullable_to_non_nullable
              as double?,
      battery: freezed == battery
          ? _self.battery
          : battery // ignore: cast_nullable_to_non_nullable
              as double?,
      display: freezed == display
          ? _self.display
          : display // ignore: cast_nullable_to_non_nullable
              as double?,
      value: freezed == value
          ? _self.value
          : value // ignore: cast_nullable_to_non_nullable
              as double?,
      perf: freezed == perf
          ? _self.perf
          : perf // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
    ));
  }

  /// Create a copy of SmartphoneScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get perf {
    if (_self.perf == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.perf!, (value) {
      return _then(_self.copyWith(perf: value));
    });
  }
}

/// @nodoc
mixin _$CpuScore {
  String? get algorithmVersion;
  double? get overall;
  ScoreMetric? get single;
  ScoreMetric? get multi;

  /// Create a copy of CpuScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CpuScoreCopyWith<CpuScore> get copyWith =>
      _$CpuScoreCopyWithImpl<CpuScore>(this as CpuScore, _$identity);

  /// Serializes this CpuScore to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CpuScore &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.single, single) || other.single == single) &&
            (identical(other.multi, multi) || other.multi == multi));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, algorithmVersion, overall, single, multi);

  @override
  String toString() {
    return 'CpuScore(algorithmVersion: $algorithmVersion, overall: $overall, single: $single, multi: $multi)';
  }
}

/// @nodoc
abstract mixin class $CpuScoreCopyWith<$Res> {
  factory $CpuScoreCopyWith(CpuScore value, $Res Function(CpuScore) _then) =
      _$CpuScoreCopyWithImpl;
  @useResult
  $Res call(
      {String? algorithmVersion,
      double? overall,
      ScoreMetric? single,
      ScoreMetric? multi});

  $ScoreMetricCopyWith<$Res>? get single;
  $ScoreMetricCopyWith<$Res>? get multi;
}

/// @nodoc
class _$CpuScoreCopyWithImpl<$Res> implements $CpuScoreCopyWith<$Res> {
  _$CpuScoreCopyWithImpl(this._self, this._then);

  final CpuScore _self;
  final $Res Function(CpuScore) _then;

  /// Create a copy of CpuScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithmVersion = freezed,
    Object? overall = freezed,
    Object? single = freezed,
    Object? multi = freezed,
  }) {
    return _then(_self.copyWith(
      algorithmVersion: freezed == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      overall: freezed == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double?,
      single: freezed == single
          ? _self.single
          : single // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
      multi: freezed == multi
          ? _self.multi
          : multi // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
    ));
  }

  /// Create a copy of CpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get single {
    if (_self.single == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.single!, (value) {
      return _then(_self.copyWith(single: value));
    });
  }

  /// Create a copy of CpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get multi {
    if (_self.multi == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.multi!, (value) {
      return _then(_self.copyWith(multi: value));
    });
  }
}

/// Adds pattern-matching-related methods to [CpuScore].
extension CpuScorePatterns on CpuScore {
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
    TResult Function(_CpuScore value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CpuScore() when $default != null:
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
    TResult Function(_CpuScore value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuScore():
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
    TResult? Function(_CpuScore value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuScore() when $default != null:
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
    TResult Function(String? algorithmVersion, double? overall,
            ScoreMetric? single, ScoreMetric? multi)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CpuScore() when $default != null:
        return $default(
            _that.algorithmVersion, _that.overall, _that.single, _that.multi);
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
    TResult Function(String? algorithmVersion, double? overall,
            ScoreMetric? single, ScoreMetric? multi)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuScore():
        return $default(
            _that.algorithmVersion, _that.overall, _that.single, _that.multi);
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
    TResult? Function(String? algorithmVersion, double? overall,
            ScoreMetric? single, ScoreMetric? multi)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CpuScore() when $default != null:
        return $default(
            _that.algorithmVersion, _that.overall, _that.single, _that.multi);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CpuScore implements CpuScore {
  const _CpuScore(
      {this.algorithmVersion, this.overall, this.single, this.multi});
  factory _CpuScore.fromJson(Map<String, dynamic> json) =>
      _$CpuScoreFromJson(json);

  @override
  final String? algorithmVersion;
  @override
  final double? overall;
  @override
  final ScoreMetric? single;
  @override
  final ScoreMetric? multi;

  /// Create a copy of CpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CpuScoreCopyWith<_CpuScore> get copyWith =>
      __$CpuScoreCopyWithImpl<_CpuScore>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CpuScoreToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CpuScore &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.single, single) || other.single == single) &&
            (identical(other.multi, multi) || other.multi == multi));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, algorithmVersion, overall, single, multi);

  @override
  String toString() {
    return 'CpuScore(algorithmVersion: $algorithmVersion, overall: $overall, single: $single, multi: $multi)';
  }
}

/// @nodoc
abstract mixin class _$CpuScoreCopyWith<$Res>
    implements $CpuScoreCopyWith<$Res> {
  factory _$CpuScoreCopyWith(_CpuScore value, $Res Function(_CpuScore) _then) =
      __$CpuScoreCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? algorithmVersion,
      double? overall,
      ScoreMetric? single,
      ScoreMetric? multi});

  @override
  $ScoreMetricCopyWith<$Res>? get single;
  @override
  $ScoreMetricCopyWith<$Res>? get multi;
}

/// @nodoc
class __$CpuScoreCopyWithImpl<$Res> implements _$CpuScoreCopyWith<$Res> {
  __$CpuScoreCopyWithImpl(this._self, this._then);

  final _CpuScore _self;
  final $Res Function(_CpuScore) _then;

  /// Create a copy of CpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? algorithmVersion = freezed,
    Object? overall = freezed,
    Object? single = freezed,
    Object? multi = freezed,
  }) {
    return _then(_CpuScore(
      algorithmVersion: freezed == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      overall: freezed == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double?,
      single: freezed == single
          ? _self.single
          : single // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
      multi: freezed == multi
          ? _self.multi
          : multi // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
    ));
  }

  /// Create a copy of CpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get single {
    if (_self.single == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.single!, (value) {
      return _then(_self.copyWith(single: value));
    });
  }

  /// Create a copy of CpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get multi {
    if (_self.multi == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.multi!, (value) {
      return _then(_self.copyWith(multi: value));
    });
  }
}

/// @nodoc
mixin _$GpuScore {
  String? get algorithmVersion;
  double? get overall;
  ScoreMetric? get graphics;

  /// Create a copy of GpuScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GpuScoreCopyWith<GpuScore> get copyWith =>
      _$GpuScoreCopyWithImpl<GpuScore>(this as GpuScore, _$identity);

  /// Serializes this GpuScore to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GpuScore &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.graphics, graphics) ||
                other.graphics == graphics));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, algorithmVersion, overall, graphics);

  @override
  String toString() {
    return 'GpuScore(algorithmVersion: $algorithmVersion, overall: $overall, graphics: $graphics)';
  }
}

/// @nodoc
abstract mixin class $GpuScoreCopyWith<$Res> {
  factory $GpuScoreCopyWith(GpuScore value, $Res Function(GpuScore) _then) =
      _$GpuScoreCopyWithImpl;
  @useResult
  $Res call({String? algorithmVersion, double? overall, ScoreMetric? graphics});

  $ScoreMetricCopyWith<$Res>? get graphics;
}

/// @nodoc
class _$GpuScoreCopyWithImpl<$Res> implements $GpuScoreCopyWith<$Res> {
  _$GpuScoreCopyWithImpl(this._self, this._then);

  final GpuScore _self;
  final $Res Function(GpuScore) _then;

  /// Create a copy of GpuScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithmVersion = freezed,
    Object? overall = freezed,
    Object? graphics = freezed,
  }) {
    return _then(_self.copyWith(
      algorithmVersion: freezed == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      overall: freezed == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double?,
      graphics: freezed == graphics
          ? _self.graphics
          : graphics // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
    ));
  }

  /// Create a copy of GpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get graphics {
    if (_self.graphics == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.graphics!, (value) {
      return _then(_self.copyWith(graphics: value));
    });
  }
}

/// Adds pattern-matching-related methods to [GpuScore].
extension GpuScorePatterns on GpuScore {
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
    TResult Function(_GpuScore value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GpuScore() when $default != null:
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
    TResult Function(_GpuScore value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpuScore():
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
    TResult? Function(_GpuScore value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpuScore() when $default != null:
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
            String? algorithmVersion, double? overall, ScoreMetric? graphics)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GpuScore() when $default != null:
        return $default(_that.algorithmVersion, _that.overall, _that.graphics);
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
            String? algorithmVersion, double? overall, ScoreMetric? graphics)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpuScore():
        return $default(_that.algorithmVersion, _that.overall, _that.graphics);
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
            String? algorithmVersion, double? overall, ScoreMetric? graphics)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GpuScore() when $default != null:
        return $default(_that.algorithmVersion, _that.overall, _that.graphics);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GpuScore implements GpuScore {
  const _GpuScore({this.algorithmVersion, this.overall, this.graphics});
  factory _GpuScore.fromJson(Map<String, dynamic> json) =>
      _$GpuScoreFromJson(json);

  @override
  final String? algorithmVersion;
  @override
  final double? overall;
  @override
  final ScoreMetric? graphics;

  /// Create a copy of GpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GpuScoreCopyWith<_GpuScore> get copyWith =>
      __$GpuScoreCopyWithImpl<_GpuScore>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GpuScoreToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GpuScore &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.graphics, graphics) ||
                other.graphics == graphics));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, algorithmVersion, overall, graphics);

  @override
  String toString() {
    return 'GpuScore(algorithmVersion: $algorithmVersion, overall: $overall, graphics: $graphics)';
  }
}

/// @nodoc
abstract mixin class _$GpuScoreCopyWith<$Res>
    implements $GpuScoreCopyWith<$Res> {
  factory _$GpuScoreCopyWith(_GpuScore value, $Res Function(_GpuScore) _then) =
      __$GpuScoreCopyWithImpl;
  @override
  @useResult
  $Res call({String? algorithmVersion, double? overall, ScoreMetric? graphics});

  @override
  $ScoreMetricCopyWith<$Res>? get graphics;
}

/// @nodoc
class __$GpuScoreCopyWithImpl<$Res> implements _$GpuScoreCopyWith<$Res> {
  __$GpuScoreCopyWithImpl(this._self, this._then);

  final _GpuScore _self;
  final $Res Function(_GpuScore) _then;

  /// Create a copy of GpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? algorithmVersion = freezed,
    Object? overall = freezed,
    Object? graphics = freezed,
  }) {
    return _then(_GpuScore(
      algorithmVersion: freezed == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      overall: freezed == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double?,
      graphics: freezed == graphics
          ? _self.graphics
          : graphics // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
    ));
  }

  /// Create a copy of GpuScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get graphics {
    if (_self.graphics == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.graphics!, (value) {
      return _then(_self.copyWith(graphics: value));
    });
  }
}

/// @nodoc
mixin _$SocScore {
  String? get algorithmVersion;
  double? get overall;
  ScoreMetric? get cpu;
  ScoreMetric? get system;

  /// Create a copy of SocScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SocScoreCopyWith<SocScore> get copyWith =>
      _$SocScoreCopyWithImpl<SocScore>(this as SocScore, _$identity);

  /// Serializes this SocScore to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SocScore &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.cpu, cpu) || other.cpu == cpu) &&
            (identical(other.system, system) || other.system == system));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, algorithmVersion, overall, cpu, system);

  @override
  String toString() {
    return 'SocScore(algorithmVersion: $algorithmVersion, overall: $overall, cpu: $cpu, system: $system)';
  }
}

/// @nodoc
abstract mixin class $SocScoreCopyWith<$Res> {
  factory $SocScoreCopyWith(SocScore value, $Res Function(SocScore) _then) =
      _$SocScoreCopyWithImpl;
  @useResult
  $Res call(
      {String? algorithmVersion,
      double? overall,
      ScoreMetric? cpu,
      ScoreMetric? system});

  $ScoreMetricCopyWith<$Res>? get cpu;
  $ScoreMetricCopyWith<$Res>? get system;
}

/// @nodoc
class _$SocScoreCopyWithImpl<$Res> implements $SocScoreCopyWith<$Res> {
  _$SocScoreCopyWithImpl(this._self, this._then);

  final SocScore _self;
  final $Res Function(SocScore) _then;

  /// Create a copy of SocScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? algorithmVersion = freezed,
    Object? overall = freezed,
    Object? cpu = freezed,
    Object? system = freezed,
  }) {
    return _then(_self.copyWith(
      algorithmVersion: freezed == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      overall: freezed == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double?,
      cpu: freezed == cpu
          ? _self.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
      system: freezed == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
    ));
  }

  /// Create a copy of SocScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get cpu {
    if (_self.cpu == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.cpu!, (value) {
      return _then(_self.copyWith(cpu: value));
    });
  }

  /// Create a copy of SocScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get system {
    if (_self.system == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.system!, (value) {
      return _then(_self.copyWith(system: value));
    });
  }
}

/// Adds pattern-matching-related methods to [SocScore].
extension SocScorePatterns on SocScore {
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
    TResult Function(_SocScore value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SocScore() when $default != null:
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
    TResult Function(_SocScore value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocScore():
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
    TResult? Function(_SocScore value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocScore() when $default != null:
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
    TResult Function(String? algorithmVersion, double? overall,
            ScoreMetric? cpu, ScoreMetric? system)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SocScore() when $default != null:
        return $default(
            _that.algorithmVersion, _that.overall, _that.cpu, _that.system);
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
    TResult Function(String? algorithmVersion, double? overall,
            ScoreMetric? cpu, ScoreMetric? system)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocScore():
        return $default(
            _that.algorithmVersion, _that.overall, _that.cpu, _that.system);
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
    TResult? Function(String? algorithmVersion, double? overall,
            ScoreMetric? cpu, ScoreMetric? system)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SocScore() when $default != null:
        return $default(
            _that.algorithmVersion, _that.overall, _that.cpu, _that.system);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SocScore implements SocScore {
  const _SocScore({this.algorithmVersion, this.overall, this.cpu, this.system});
  factory _SocScore.fromJson(Map<String, dynamic> json) =>
      _$SocScoreFromJson(json);

  @override
  final String? algorithmVersion;
  @override
  final double? overall;
  @override
  final ScoreMetric? cpu;
  @override
  final ScoreMetric? system;

  /// Create a copy of SocScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SocScoreCopyWith<_SocScore> get copyWith =>
      __$SocScoreCopyWithImpl<_SocScore>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SocScoreToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SocScore &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.overall, overall) || other.overall == overall) &&
            (identical(other.cpu, cpu) || other.cpu == cpu) &&
            (identical(other.system, system) || other.system == system));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, algorithmVersion, overall, cpu, system);

  @override
  String toString() {
    return 'SocScore(algorithmVersion: $algorithmVersion, overall: $overall, cpu: $cpu, system: $system)';
  }
}

/// @nodoc
abstract mixin class _$SocScoreCopyWith<$Res>
    implements $SocScoreCopyWith<$Res> {
  factory _$SocScoreCopyWith(_SocScore value, $Res Function(_SocScore) _then) =
      __$SocScoreCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? algorithmVersion,
      double? overall,
      ScoreMetric? cpu,
      ScoreMetric? system});

  @override
  $ScoreMetricCopyWith<$Res>? get cpu;
  @override
  $ScoreMetricCopyWith<$Res>? get system;
}

/// @nodoc
class __$SocScoreCopyWithImpl<$Res> implements _$SocScoreCopyWith<$Res> {
  __$SocScoreCopyWithImpl(this._self, this._then);

  final _SocScore _self;
  final $Res Function(_SocScore) _then;

  /// Create a copy of SocScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? algorithmVersion = freezed,
    Object? overall = freezed,
    Object? cpu = freezed,
    Object? system = freezed,
  }) {
    return _then(_SocScore(
      algorithmVersion: freezed == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      overall: freezed == overall
          ? _self.overall
          : overall // ignore: cast_nullable_to_non_nullable
              as double?,
      cpu: freezed == cpu
          ? _self.cpu
          : cpu // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
      system: freezed == system
          ? _self.system
          : system // ignore: cast_nullable_to_non_nullable
              as ScoreMetric?,
    ));
  }

  /// Create a copy of SocScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get cpu {
    if (_self.cpu == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.cpu!, (value) {
      return _then(_self.copyWith(cpu: value));
    });
  }

  /// Create a copy of SocScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ScoreMetricCopyWith<$Res>? get system {
    if (_self.system == null) {
      return null;
    }

    return $ScoreMetricCopyWith<$Res>(_self.system!, (value) {
      return _then(_self.copyWith(system: value));
    });
  }
}

// dart format on
