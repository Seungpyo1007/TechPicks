// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'smartphone.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Display {
  double? get sizeInch;

  /// `2340x1080` 형태의 문자열. 숫자로 파싱하지 않는다.
  String? get resolution;
  int? get refreshHz;

  /// 패널 종류 (예: `Dynamic AMOLED 2X`).
  String? get type;
  int? get ppi;
  int? get brightnessNits;

  /// Create a copy of Display
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DisplayCopyWith<Display> get copyWith =>
      _$DisplayCopyWithImpl<Display>(this as Display, _$identity);

  /// Serializes this Display to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Display &&
            (identical(other.sizeInch, sizeInch) ||
                other.sizeInch == sizeInch) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution) &&
            (identical(other.refreshHz, refreshHz) ||
                other.refreshHz == refreshHz) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.ppi, ppi) || other.ppi == ppi) &&
            (identical(other.brightnessNits, brightnessNits) ||
                other.brightnessNits == brightnessNits));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, sizeInch, resolution, refreshHz, type, ppi, brightnessNits);

  @override
  String toString() {
    return 'Display(sizeInch: $sizeInch, resolution: $resolution, refreshHz: $refreshHz, type: $type, ppi: $ppi, brightnessNits: $brightnessNits)';
  }
}

/// @nodoc
abstract mixin class $DisplayCopyWith<$Res> {
  factory $DisplayCopyWith(Display value, $Res Function(Display) _then) =
      _$DisplayCopyWithImpl;
  @useResult
  $Res call(
      {double? sizeInch,
      String? resolution,
      int? refreshHz,
      String? type,
      int? ppi,
      int? brightnessNits});
}

/// @nodoc
class _$DisplayCopyWithImpl<$Res> implements $DisplayCopyWith<$Res> {
  _$DisplayCopyWithImpl(this._self, this._then);

  final Display _self;
  final $Res Function(Display) _then;

  /// Create a copy of Display
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sizeInch = freezed,
    Object? resolution = freezed,
    Object? refreshHz = freezed,
    Object? type = freezed,
    Object? ppi = freezed,
    Object? brightnessNits = freezed,
  }) {
    return _then(_self.copyWith(
      sizeInch: freezed == sizeInch
          ? _self.sizeInch
          : sizeInch // ignore: cast_nullable_to_non_nullable
              as double?,
      resolution: freezed == resolution
          ? _self.resolution
          : resolution // ignore: cast_nullable_to_non_nullable
              as String?,
      refreshHz: freezed == refreshHz
          ? _self.refreshHz
          : refreshHz // ignore: cast_nullable_to_non_nullable
              as int?,
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      ppi: freezed == ppi
          ? _self.ppi
          : ppi // ignore: cast_nullable_to_non_nullable
              as int?,
      brightnessNits: freezed == brightnessNits
          ? _self.brightnessNits
          : brightnessNits // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Display].
extension DisplayPatterns on Display {
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
    TResult Function(_Display value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Display() when $default != null:
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
    TResult Function(_Display value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Display():
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
    TResult? Function(_Display value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Display() when $default != null:
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
    TResult Function(double? sizeInch, String? resolution, int? refreshHz,
            String? type, int? ppi, int? brightnessNits)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Display() when $default != null:
        return $default(_that.sizeInch, _that.resolution, _that.refreshHz,
            _that.type, _that.ppi, _that.brightnessNits);
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
    TResult Function(double? sizeInch, String? resolution, int? refreshHz,
            String? type, int? ppi, int? brightnessNits)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Display():
        return $default(_that.sizeInch, _that.resolution, _that.refreshHz,
            _that.type, _that.ppi, _that.brightnessNits);
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
    TResult? Function(double? sizeInch, String? resolution, int? refreshHz,
            String? type, int? ppi, int? brightnessNits)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Display() when $default != null:
        return $default(_that.sizeInch, _that.resolution, _that.refreshHz,
            _that.type, _that.ppi, _that.brightnessNits);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Display implements Display {
  const _Display(
      {this.sizeInch,
      this.resolution,
      this.refreshHz,
      this.type,
      this.ppi,
      this.brightnessNits});
  factory _Display.fromJson(Map<String, dynamic> json) =>
      _$DisplayFromJson(json);

  @override
  final double? sizeInch;

  /// `2340x1080` 형태의 문자열. 숫자로 파싱하지 않는다.
  @override
  final String? resolution;
  @override
  final int? refreshHz;

  /// 패널 종류 (예: `Dynamic AMOLED 2X`).
  @override
  final String? type;
  @override
  final int? ppi;
  @override
  final int? brightnessNits;

  /// Create a copy of Display
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DisplayCopyWith<_Display> get copyWith =>
      __$DisplayCopyWithImpl<_Display>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DisplayToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Display &&
            (identical(other.sizeInch, sizeInch) ||
                other.sizeInch == sizeInch) &&
            (identical(other.resolution, resolution) ||
                other.resolution == resolution) &&
            (identical(other.refreshHz, refreshHz) ||
                other.refreshHz == refreshHz) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.ppi, ppi) || other.ppi == ppi) &&
            (identical(other.brightnessNits, brightnessNits) ||
                other.brightnessNits == brightnessNits));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, sizeInch, resolution, refreshHz, type, ppi, brightnessNits);

  @override
  String toString() {
    return 'Display(sizeInch: $sizeInch, resolution: $resolution, refreshHz: $refreshHz, type: $type, ppi: $ppi, brightnessNits: $brightnessNits)';
  }
}

/// @nodoc
abstract mixin class _$DisplayCopyWith<$Res> implements $DisplayCopyWith<$Res> {
  factory _$DisplayCopyWith(_Display value, $Res Function(_Display) _then) =
      __$DisplayCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double? sizeInch,
      String? resolution,
      int? refreshHz,
      String? type,
      int? ppi,
      int? brightnessNits});
}

/// @nodoc
class __$DisplayCopyWithImpl<$Res> implements _$DisplayCopyWith<$Res> {
  __$DisplayCopyWithImpl(this._self, this._then);

  final _Display _self;
  final $Res Function(_Display) _then;

  /// Create a copy of Display
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sizeInch = freezed,
    Object? resolution = freezed,
    Object? refreshHz = freezed,
    Object? type = freezed,
    Object? ppi = freezed,
    Object? brightnessNits = freezed,
  }) {
    return _then(_Display(
      sizeInch: freezed == sizeInch
          ? _self.sizeInch
          : sizeInch // ignore: cast_nullable_to_non_nullable
              as double?,
      resolution: freezed == resolution
          ? _self.resolution
          : resolution // ignore: cast_nullable_to_non_nullable
              as String?,
      refreshHz: freezed == refreshHz
          ? _self.refreshHz
          : refreshHz // ignore: cast_nullable_to_non_nullable
              as int?,
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      ppi: freezed == ppi
          ? _self.ppi
          : ppi // ignore: cast_nullable_to_non_nullable
              as int?,
      brightnessNits: freezed == brightnessNits
          ? _self.brightnessNits
          : brightnessNits // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
mixin _$Camera {
  String? get type;

  /// 화소 (메가픽셀).
  double? get mp;
  double? get aperture;

  /// 광학식 손떨림 보정.
  bool? get ois;
  String? get sensor;
  double? get opticalZoom;

  /// Create a copy of Camera
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CameraCopyWith<Camera> get copyWith =>
      _$CameraCopyWithImpl<Camera>(this as Camera, _$identity);

  /// Serializes this Camera to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Camera &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.mp, mp) || other.mp == mp) &&
            (identical(other.aperture, aperture) ||
                other.aperture == aperture) &&
            (identical(other.ois, ois) || other.ois == ois) &&
            (identical(other.sensor, sensor) || other.sensor == sensor) &&
            (identical(other.opticalZoom, opticalZoom) ||
                other.opticalZoom == opticalZoom));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, mp, aperture, ois, sensor, opticalZoom);

  @override
  String toString() {
    return 'Camera(type: $type, mp: $mp, aperture: $aperture, ois: $ois, sensor: $sensor, opticalZoom: $opticalZoom)';
  }
}

/// @nodoc
abstract mixin class $CameraCopyWith<$Res> {
  factory $CameraCopyWith(Camera value, $Res Function(Camera) _then) =
      _$CameraCopyWithImpl;
  @useResult
  $Res call(
      {String? type,
      double? mp,
      double? aperture,
      bool? ois,
      String? sensor,
      double? opticalZoom});
}

/// @nodoc
class _$CameraCopyWithImpl<$Res> implements $CameraCopyWith<$Res> {
  _$CameraCopyWithImpl(this._self, this._then);

  final Camera _self;
  final $Res Function(Camera) _then;

  /// Create a copy of Camera
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = freezed,
    Object? mp = freezed,
    Object? aperture = freezed,
    Object? ois = freezed,
    Object? sensor = freezed,
    Object? opticalZoom = freezed,
  }) {
    return _then(_self.copyWith(
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      mp: freezed == mp
          ? _self.mp
          : mp // ignore: cast_nullable_to_non_nullable
              as double?,
      aperture: freezed == aperture
          ? _self.aperture
          : aperture // ignore: cast_nullable_to_non_nullable
              as double?,
      ois: freezed == ois
          ? _self.ois
          : ois // ignore: cast_nullable_to_non_nullable
              as bool?,
      sensor: freezed == sensor
          ? _self.sensor
          : sensor // ignore: cast_nullable_to_non_nullable
              as String?,
      opticalZoom: freezed == opticalZoom
          ? _self.opticalZoom
          : opticalZoom // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Camera].
extension CameraPatterns on Camera {
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
    TResult Function(_Camera value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Camera() when $default != null:
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
    TResult Function(_Camera value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Camera():
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
    TResult? Function(_Camera value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Camera() when $default != null:
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
    TResult Function(String? type, double? mp, double? aperture, bool? ois,
            String? sensor, double? opticalZoom)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Camera() when $default != null:
        return $default(_that.type, _that.mp, _that.aperture, _that.ois,
            _that.sensor, _that.opticalZoom);
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
    TResult Function(String? type, double? mp, double? aperture, bool? ois,
            String? sensor, double? opticalZoom)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Camera():
        return $default(_that.type, _that.mp, _that.aperture, _that.ois,
            _that.sensor, _that.opticalZoom);
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
    TResult? Function(String? type, double? mp, double? aperture, bool? ois,
            String? sensor, double? opticalZoom)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Camera() when $default != null:
        return $default(_that.type, _that.mp, _that.aperture, _that.ois,
            _that.sensor, _that.opticalZoom);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Camera implements Camera {
  const _Camera(
      {this.type,
      this.mp,
      this.aperture,
      this.ois,
      this.sensor,
      this.opticalZoom});
  factory _Camera.fromJson(Map<String, dynamic> json) => _$CameraFromJson(json);

  @override
  final String? type;

  /// 화소 (메가픽셀).
  @override
  final double? mp;
  @override
  final double? aperture;

  /// 광학식 손떨림 보정.
  @override
  final bool? ois;
  @override
  final String? sensor;
  @override
  final double? opticalZoom;

  /// Create a copy of Camera
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CameraCopyWith<_Camera> get copyWith =>
      __$CameraCopyWithImpl<_Camera>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CameraToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Camera &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.mp, mp) || other.mp == mp) &&
            (identical(other.aperture, aperture) ||
                other.aperture == aperture) &&
            (identical(other.ois, ois) || other.ois == ois) &&
            (identical(other.sensor, sensor) || other.sensor == sensor) &&
            (identical(other.opticalZoom, opticalZoom) ||
                other.opticalZoom == opticalZoom));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, mp, aperture, ois, sensor, opticalZoom);

  @override
  String toString() {
    return 'Camera(type: $type, mp: $mp, aperture: $aperture, ois: $ois, sensor: $sensor, opticalZoom: $opticalZoom)';
  }
}

/// @nodoc
abstract mixin class _$CameraCopyWith<$Res> implements $CameraCopyWith<$Res> {
  factory _$CameraCopyWith(_Camera value, $Res Function(_Camera) _then) =
      __$CameraCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? type,
      double? mp,
      double? aperture,
      bool? ois,
      String? sensor,
      double? opticalZoom});
}

/// @nodoc
class __$CameraCopyWithImpl<$Res> implements _$CameraCopyWith<$Res> {
  __$CameraCopyWithImpl(this._self, this._then);

  final _Camera _self;
  final $Res Function(_Camera) _then;

  /// Create a copy of Camera
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = freezed,
    Object? mp = freezed,
    Object? aperture = freezed,
    Object? ois = freezed,
    Object? sensor = freezed,
    Object? opticalZoom = freezed,
  }) {
    return _then(_Camera(
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      mp: freezed == mp
          ? _self.mp
          : mp // ignore: cast_nullable_to_non_nullable
              as double?,
      aperture: freezed == aperture
          ? _self.aperture
          : aperture // ignore: cast_nullable_to_non_nullable
              as double?,
      ois: freezed == ois
          ? _self.ois
          : ois // ignore: cast_nullable_to_non_nullable
              as bool?,
      sensor: freezed == sensor
          ? _self.sensor
          : sensor // ignore: cast_nullable_to_non_nullable
              as String?,
      opticalZoom: freezed == opticalZoom
          ? _self.opticalZoom
          : opticalZoom // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
mixin _$Dimensions {
  double? get heightMm;
  double? get widthMm;
  double? get depthMm;

  /// Create a copy of Dimensions
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DimensionsCopyWith<Dimensions> get copyWith =>
      _$DimensionsCopyWithImpl<Dimensions>(this as Dimensions, _$identity);

  /// Serializes this Dimensions to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Dimensions &&
            (identical(other.heightMm, heightMm) ||
                other.heightMm == heightMm) &&
            (identical(other.widthMm, widthMm) || other.widthMm == widthMm) &&
            (identical(other.depthMm, depthMm) || other.depthMm == depthMm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, heightMm, widthMm, depthMm);

  @override
  String toString() {
    return 'Dimensions(heightMm: $heightMm, widthMm: $widthMm, depthMm: $depthMm)';
  }
}

/// @nodoc
abstract mixin class $DimensionsCopyWith<$Res> {
  factory $DimensionsCopyWith(
          Dimensions value, $Res Function(Dimensions) _then) =
      _$DimensionsCopyWithImpl;
  @useResult
  $Res call({double? heightMm, double? widthMm, double? depthMm});
}

/// @nodoc
class _$DimensionsCopyWithImpl<$Res> implements $DimensionsCopyWith<$Res> {
  _$DimensionsCopyWithImpl(this._self, this._then);

  final Dimensions _self;
  final $Res Function(Dimensions) _then;

  /// Create a copy of Dimensions
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? heightMm = freezed,
    Object? widthMm = freezed,
    Object? depthMm = freezed,
  }) {
    return _then(_self.copyWith(
      heightMm: freezed == heightMm
          ? _self.heightMm
          : heightMm // ignore: cast_nullable_to_non_nullable
              as double?,
      widthMm: freezed == widthMm
          ? _self.widthMm
          : widthMm // ignore: cast_nullable_to_non_nullable
              as double?,
      depthMm: freezed == depthMm
          ? _self.depthMm
          : depthMm // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Dimensions].
extension DimensionsPatterns on Dimensions {
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
    TResult Function(_Dimensions value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Dimensions() when $default != null:
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
    TResult Function(_Dimensions value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Dimensions():
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
    TResult? Function(_Dimensions value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Dimensions() when $default != null:
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
    TResult Function(double? heightMm, double? widthMm, double? depthMm)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Dimensions() when $default != null:
        return $default(_that.heightMm, _that.widthMm, _that.depthMm);
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
    TResult Function(double? heightMm, double? widthMm, double? depthMm)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Dimensions():
        return $default(_that.heightMm, _that.widthMm, _that.depthMm);
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
    TResult? Function(double? heightMm, double? widthMm, double? depthMm)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Dimensions() when $default != null:
        return $default(_that.heightMm, _that.widthMm, _that.depthMm);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Dimensions implements Dimensions {
  const _Dimensions({this.heightMm, this.widthMm, this.depthMm});
  factory _Dimensions.fromJson(Map<String, dynamic> json) =>
      _$DimensionsFromJson(json);

  @override
  final double? heightMm;
  @override
  final double? widthMm;
  @override
  final double? depthMm;

  /// Create a copy of Dimensions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DimensionsCopyWith<_Dimensions> get copyWith =>
      __$DimensionsCopyWithImpl<_Dimensions>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DimensionsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Dimensions &&
            (identical(other.heightMm, heightMm) ||
                other.heightMm == heightMm) &&
            (identical(other.widthMm, widthMm) || other.widthMm == widthMm) &&
            (identical(other.depthMm, depthMm) || other.depthMm == depthMm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, heightMm, widthMm, depthMm);

  @override
  String toString() {
    return 'Dimensions(heightMm: $heightMm, widthMm: $widthMm, depthMm: $depthMm)';
  }
}

/// @nodoc
abstract mixin class _$DimensionsCopyWith<$Res>
    implements $DimensionsCopyWith<$Res> {
  factory _$DimensionsCopyWith(
          _Dimensions value, $Res Function(_Dimensions) _then) =
      __$DimensionsCopyWithImpl;
  @override
  @useResult
  $Res call({double? heightMm, double? widthMm, double? depthMm});
}

/// @nodoc
class __$DimensionsCopyWithImpl<$Res> implements _$DimensionsCopyWith<$Res> {
  __$DimensionsCopyWithImpl(this._self, this._then);

  final _Dimensions _self;
  final $Res Function(_Dimensions) _then;

  /// Create a copy of Dimensions
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? heightMm = freezed,
    Object? widthMm = freezed,
    Object? depthMm = freezed,
  }) {
    return _then(_Dimensions(
      heightMm: freezed == heightMm
          ? _self.heightMm
          : heightMm // ignore: cast_nullable_to_non_nullable
              as double?,
      widthMm: freezed == widthMm
          ? _self.widthMm
          : widthMm // ignore: cast_nullable_to_non_nullable
              as double?,
      depthMm: freezed == depthMm
          ? _self.depthMm
          : depthMm // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
mixin _$Connectivity {
  String? get wifi;
  String? get bluetooth;
  bool? get nfc;
  String? get usb;

  /// Create a copy of Connectivity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ConnectivityCopyWith<Connectivity> get copyWith =>
      _$ConnectivityCopyWithImpl<Connectivity>(
          this as Connectivity, _$identity);

  /// Serializes this Connectivity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Connectivity &&
            (identical(other.wifi, wifi) || other.wifi == wifi) &&
            (identical(other.bluetooth, bluetooth) ||
                other.bluetooth == bluetooth) &&
            (identical(other.nfc, nfc) || other.nfc == nfc) &&
            (identical(other.usb, usb) || other.usb == usb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, wifi, bluetooth, nfc, usb);

  @override
  String toString() {
    return 'Connectivity(wifi: $wifi, bluetooth: $bluetooth, nfc: $nfc, usb: $usb)';
  }
}

/// @nodoc
abstract mixin class $ConnectivityCopyWith<$Res> {
  factory $ConnectivityCopyWith(
          Connectivity value, $Res Function(Connectivity) _then) =
      _$ConnectivityCopyWithImpl;
  @useResult
  $Res call({String? wifi, String? bluetooth, bool? nfc, String? usb});
}

/// @nodoc
class _$ConnectivityCopyWithImpl<$Res> implements $ConnectivityCopyWith<$Res> {
  _$ConnectivityCopyWithImpl(this._self, this._then);

  final Connectivity _self;
  final $Res Function(Connectivity) _then;

  /// Create a copy of Connectivity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? wifi = freezed,
    Object? bluetooth = freezed,
    Object? nfc = freezed,
    Object? usb = freezed,
  }) {
    return _then(_self.copyWith(
      wifi: freezed == wifi
          ? _self.wifi
          : wifi // ignore: cast_nullable_to_non_nullable
              as String?,
      bluetooth: freezed == bluetooth
          ? _self.bluetooth
          : bluetooth // ignore: cast_nullable_to_non_nullable
              as String?,
      nfc: freezed == nfc
          ? _self.nfc
          : nfc // ignore: cast_nullable_to_non_nullable
              as bool?,
      usb: freezed == usb
          ? _self.usb
          : usb // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [Connectivity].
extension ConnectivityPatterns on Connectivity {
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
    TResult Function(_Connectivity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Connectivity() when $default != null:
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
    TResult Function(_Connectivity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Connectivity():
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
    TResult? Function(_Connectivity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Connectivity() when $default != null:
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
    TResult Function(String? wifi, String? bluetooth, bool? nfc, String? usb)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Connectivity() when $default != null:
        return $default(_that.wifi, _that.bluetooth, _that.nfc, _that.usb);
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
    TResult Function(String? wifi, String? bluetooth, bool? nfc, String? usb)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Connectivity():
        return $default(_that.wifi, _that.bluetooth, _that.nfc, _that.usb);
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
    TResult? Function(String? wifi, String? bluetooth, bool? nfc, String? usb)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Connectivity() when $default != null:
        return $default(_that.wifi, _that.bluetooth, _that.nfc, _that.usb);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Connectivity implements Connectivity {
  const _Connectivity({this.wifi, this.bluetooth, this.nfc, this.usb});
  factory _Connectivity.fromJson(Map<String, dynamic> json) =>
      _$ConnectivityFromJson(json);

  @override
  final String? wifi;
  @override
  final String? bluetooth;
  @override
  final bool? nfc;
  @override
  final String? usb;

  /// Create a copy of Connectivity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ConnectivityCopyWith<_Connectivity> get copyWith =>
      __$ConnectivityCopyWithImpl<_Connectivity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ConnectivityToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Connectivity &&
            (identical(other.wifi, wifi) || other.wifi == wifi) &&
            (identical(other.bluetooth, bluetooth) ||
                other.bluetooth == bluetooth) &&
            (identical(other.nfc, nfc) || other.nfc == nfc) &&
            (identical(other.usb, usb) || other.usb == usb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, wifi, bluetooth, nfc, usb);

  @override
  String toString() {
    return 'Connectivity(wifi: $wifi, bluetooth: $bluetooth, nfc: $nfc, usb: $usb)';
  }
}

/// @nodoc
abstract mixin class _$ConnectivityCopyWith<$Res>
    implements $ConnectivityCopyWith<$Res> {
  factory _$ConnectivityCopyWith(
          _Connectivity value, $Res Function(_Connectivity) _then) =
      __$ConnectivityCopyWithImpl;
  @override
  @useResult
  $Res call({String? wifi, String? bluetooth, bool? nfc, String? usb});
}

/// @nodoc
class __$ConnectivityCopyWithImpl<$Res>
    implements _$ConnectivityCopyWith<$Res> {
  __$ConnectivityCopyWithImpl(this._self, this._then);

  final _Connectivity _self;
  final $Res Function(_Connectivity) _then;

  /// Create a copy of Connectivity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? wifi = freezed,
    Object? bluetooth = freezed,
    Object? nfc = freezed,
    Object? usb = freezed,
  }) {
    return _then(_Connectivity(
      wifi: freezed == wifi
          ? _self.wifi
          : wifi // ignore: cast_nullable_to_non_nullable
              as String?,
      bluetooth: freezed == bluetooth
          ? _self.bluetooth
          : bluetooth // ignore: cast_nullable_to_non_nullable
              as String?,
      nfc: freezed == nfc
          ? _self.nfc
          : nfc // ignore: cast_nullable_to_non_nullable
              as bool?,
      usb: freezed == usb
          ? _self.usb
          : usb // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$Smartphone {
  String get slug;
  String get name;
  int? get id;

  /// 파생 모델일 때 원본 모델의 slug (예: Plus/Ultra 변형).
  String? get baseModelSlug;
  Brand? get brand;
  Soc? get soc;

  /// `YYYY-MM-DD`. 일자가 불확실하면 월초로 채워져 있다.
  String? get releaseDate;
  int? get msrpUsd;
  int? get ramGb;
  List<int> get storageOptionsGb;

  /// 지역·구성별 변형 정보. 스키마가 고정되어 있지 않아 원본 그대로 둔다.
  Map<String, dynamic> get variant;
  Display? get display;
  List<Camera> get cameras;
  int? get batteryMah;
  int? get chargingWiredW;
  int? get chargingWirelessW;
  double? get weightG;
  Dimensions? get dimensions;

  /// 방수·방진 등급 (예: `IP68`).
  String? get ipRating;
  String? get os;
  String? get osVersion;
  Connectivity? get connectivity;
  String? get imageUrl;
  List<String> get images;
  SmartphoneScore? get score;
  bool get verified;

  /// CC-BY-SA 4.0 조건상 UI에 반드시 노출해야 한다.
  List<String> get sourceUrls;
  String? get createdAt;
  String? get updatedAt;

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SmartphoneCopyWith<Smartphone> get copyWith =>
      _$SmartphoneCopyWithImpl<Smartphone>(this as Smartphone, _$identity);

  /// Serializes this Smartphone to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Smartphone &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.baseModelSlug, baseModelSlug) ||
                other.baseModelSlug == baseModelSlug) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.soc, soc) || other.soc == soc) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.msrpUsd, msrpUsd) || other.msrpUsd == msrpUsd) &&
            (identical(other.ramGb, ramGb) || other.ramGb == ramGb) &&
            const DeepCollectionEquality()
                .equals(other.storageOptionsGb, storageOptionsGb) &&
            const DeepCollectionEquality().equals(other.variant, variant) &&
            (identical(other.display, display) || other.display == display) &&
            const DeepCollectionEquality().equals(other.cameras, cameras) &&
            (identical(other.batteryMah, batteryMah) ||
                other.batteryMah == batteryMah) &&
            (identical(other.chargingWiredW, chargingWiredW) ||
                other.chargingWiredW == chargingWiredW) &&
            (identical(other.chargingWirelessW, chargingWirelessW) ||
                other.chargingWirelessW == chargingWirelessW) &&
            (identical(other.weightG, weightG) || other.weightG == weightG) &&
            (identical(other.dimensions, dimensions) ||
                other.dimensions == dimensions) &&
            (identical(other.ipRating, ipRating) ||
                other.ipRating == ipRating) &&
            (identical(other.os, os) || other.os == os) &&
            (identical(other.osVersion, osVersion) ||
                other.osVersion == osVersion) &&
            (identical(other.connectivity, connectivity) ||
                other.connectivity == connectivity) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality().equals(other.images, images) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            const DeepCollectionEquality()
                .equals(other.sourceUrls, sourceUrls) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        slug,
        name,
        id,
        baseModelSlug,
        brand,
        soc,
        releaseDate,
        msrpUsd,
        ramGb,
        const DeepCollectionEquality().hash(storageOptionsGb),
        const DeepCollectionEquality().hash(variant),
        display,
        const DeepCollectionEquality().hash(cameras),
        batteryMah,
        chargingWiredW,
        chargingWirelessW,
        weightG,
        dimensions,
        ipRating,
        os,
        osVersion,
        connectivity,
        imageUrl,
        const DeepCollectionEquality().hash(images),
        score,
        verified,
        const DeepCollectionEquality().hash(sourceUrls),
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'Smartphone(slug: $slug, name: $name, id: $id, baseModelSlug: $baseModelSlug, brand: $brand, soc: $soc, releaseDate: $releaseDate, msrpUsd: $msrpUsd, ramGb: $ramGb, storageOptionsGb: $storageOptionsGb, variant: $variant, display: $display, cameras: $cameras, batteryMah: $batteryMah, chargingWiredW: $chargingWiredW, chargingWirelessW: $chargingWirelessW, weightG: $weightG, dimensions: $dimensions, ipRating: $ipRating, os: $os, osVersion: $osVersion, connectivity: $connectivity, imageUrl: $imageUrl, images: $images, score: $score, verified: $verified, sourceUrls: $sourceUrls, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $SmartphoneCopyWith<$Res> {
  factory $SmartphoneCopyWith(
          Smartphone value, $Res Function(Smartphone) _then) =
      _$SmartphoneCopyWithImpl;
  @useResult
  $Res call(
      {String slug,
      String name,
      int? id,
      String? baseModelSlug,
      Brand? brand,
      Soc? soc,
      String? releaseDate,
      int? msrpUsd,
      int? ramGb,
      List<int> storageOptionsGb,
      Map<String, dynamic> variant,
      Display? display,
      List<Camera> cameras,
      int? batteryMah,
      int? chargingWiredW,
      int? chargingWirelessW,
      double? weightG,
      Dimensions? dimensions,
      String? ipRating,
      String? os,
      String? osVersion,
      Connectivity? connectivity,
      String? imageUrl,
      List<String> images,
      SmartphoneScore? score,
      bool verified,
      List<String> sourceUrls,
      String? createdAt,
      String? updatedAt});

  $BrandCopyWith<$Res>? get brand;
  $SocCopyWith<$Res>? get soc;
  $DisplayCopyWith<$Res>? get display;
  $DimensionsCopyWith<$Res>? get dimensions;
  $ConnectivityCopyWith<$Res>? get connectivity;
  $SmartphoneScoreCopyWith<$Res>? get score;
}

/// @nodoc
class _$SmartphoneCopyWithImpl<$Res> implements $SmartphoneCopyWith<$Res> {
  _$SmartphoneCopyWithImpl(this._self, this._then);

  final Smartphone _self;
  final $Res Function(Smartphone) _then;

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? id = freezed,
    Object? baseModelSlug = freezed,
    Object? brand = freezed,
    Object? soc = freezed,
    Object? releaseDate = freezed,
    Object? msrpUsd = freezed,
    Object? ramGb = freezed,
    Object? storageOptionsGb = null,
    Object? variant = null,
    Object? display = freezed,
    Object? cameras = null,
    Object? batteryMah = freezed,
    Object? chargingWiredW = freezed,
    Object? chargingWirelessW = freezed,
    Object? weightG = freezed,
    Object? dimensions = freezed,
    Object? ipRating = freezed,
    Object? os = freezed,
    Object? osVersion = freezed,
    Object? connectivity = freezed,
    Object? imageUrl = freezed,
    Object? images = null,
    Object? score = freezed,
    Object? verified = null,
    Object? sourceUrls = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
      baseModelSlug: freezed == baseModelSlug
          ? _self.baseModelSlug
          : baseModelSlug // ignore: cast_nullable_to_non_nullable
              as String?,
      brand: freezed == brand
          ? _self.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as Brand?,
      soc: freezed == soc
          ? _self.soc
          : soc // ignore: cast_nullable_to_non_nullable
              as Soc?,
      releaseDate: freezed == releaseDate
          ? _self.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      msrpUsd: freezed == msrpUsd
          ? _self.msrpUsd
          : msrpUsd // ignore: cast_nullable_to_non_nullable
              as int?,
      ramGb: freezed == ramGb
          ? _self.ramGb
          : ramGb // ignore: cast_nullable_to_non_nullable
              as int?,
      storageOptionsGb: null == storageOptionsGb
          ? _self.storageOptionsGb
          : storageOptionsGb // ignore: cast_nullable_to_non_nullable
              as List<int>,
      variant: null == variant
          ? _self.variant
          : variant // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      display: freezed == display
          ? _self.display
          : display // ignore: cast_nullable_to_non_nullable
              as Display?,
      cameras: null == cameras
          ? _self.cameras
          : cameras // ignore: cast_nullable_to_non_nullable
              as List<Camera>,
      batteryMah: freezed == batteryMah
          ? _self.batteryMah
          : batteryMah // ignore: cast_nullable_to_non_nullable
              as int?,
      chargingWiredW: freezed == chargingWiredW
          ? _self.chargingWiredW
          : chargingWiredW // ignore: cast_nullable_to_non_nullable
              as int?,
      chargingWirelessW: freezed == chargingWirelessW
          ? _self.chargingWirelessW
          : chargingWirelessW // ignore: cast_nullable_to_non_nullable
              as int?,
      weightG: freezed == weightG
          ? _self.weightG
          : weightG // ignore: cast_nullable_to_non_nullable
              as double?,
      dimensions: freezed == dimensions
          ? _self.dimensions
          : dimensions // ignore: cast_nullable_to_non_nullable
              as Dimensions?,
      ipRating: freezed == ipRating
          ? _self.ipRating
          : ipRating // ignore: cast_nullable_to_non_nullable
              as String?,
      os: freezed == os
          ? _self.os
          : os // ignore: cast_nullable_to_non_nullable
              as String?,
      osVersion: freezed == osVersion
          ? _self.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      connectivity: freezed == connectivity
          ? _self.connectivity
          : connectivity // ignore: cast_nullable_to_non_nullable
              as Connectivity?,
      imageUrl: freezed == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      images: null == images
          ? _self.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      score: freezed == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as SmartphoneScore?,
      verified: null == verified
          ? _self.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceUrls: null == sourceUrls
          ? _self.sourceUrls
          : sourceUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of Smartphone
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
  }

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SocCopyWith<$Res>? get soc {
    if (_self.soc == null) {
      return null;
    }

    return $SocCopyWith<$Res>(_self.soc!, (value) {
      return _then(_self.copyWith(soc: value));
    });
  }

  /// Create a copy of Smartphone
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

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DimensionsCopyWith<$Res>? get dimensions {
    if (_self.dimensions == null) {
      return null;
    }

    return $DimensionsCopyWith<$Res>(_self.dimensions!, (value) {
      return _then(_self.copyWith(dimensions: value));
    });
  }

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConnectivityCopyWith<$Res>? get connectivity {
    if (_self.connectivity == null) {
      return null;
    }

    return $ConnectivityCopyWith<$Res>(_self.connectivity!, (value) {
      return _then(_self.copyWith(connectivity: value));
    });
  }

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartphoneScoreCopyWith<$Res>? get score {
    if (_self.score == null) {
      return null;
    }

    return $SmartphoneScoreCopyWith<$Res>(_self.score!, (value) {
      return _then(_self.copyWith(score: value));
    });
  }
}

/// Adds pattern-matching-related methods to [Smartphone].
extension SmartphonePatterns on Smartphone {
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
    TResult Function(_Smartphone value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Smartphone() when $default != null:
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
    TResult Function(_Smartphone value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Smartphone():
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
    TResult? Function(_Smartphone value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Smartphone() when $default != null:
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
            String? baseModelSlug,
            Brand? brand,
            Soc? soc,
            String? releaseDate,
            int? msrpUsd,
            int? ramGb,
            List<int> storageOptionsGb,
            Map<String, dynamic> variant,
            Display? display,
            List<Camera> cameras,
            int? batteryMah,
            int? chargingWiredW,
            int? chargingWirelessW,
            double? weightG,
            Dimensions? dimensions,
            String? ipRating,
            String? os,
            String? osVersion,
            Connectivity? connectivity,
            String? imageUrl,
            List<String> images,
            SmartphoneScore? score,
            bool verified,
            List<String> sourceUrls,
            String? createdAt,
            String? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Smartphone() when $default != null:
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.baseModelSlug,
            _that.brand,
            _that.soc,
            _that.releaseDate,
            _that.msrpUsd,
            _that.ramGb,
            _that.storageOptionsGb,
            _that.variant,
            _that.display,
            _that.cameras,
            _that.batteryMah,
            _that.chargingWiredW,
            _that.chargingWirelessW,
            _that.weightG,
            _that.dimensions,
            _that.ipRating,
            _that.os,
            _that.osVersion,
            _that.connectivity,
            _that.imageUrl,
            _that.images,
            _that.score,
            _that.verified,
            _that.sourceUrls,
            _that.createdAt,
            _that.updatedAt);
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
            String? baseModelSlug,
            Brand? brand,
            Soc? soc,
            String? releaseDate,
            int? msrpUsd,
            int? ramGb,
            List<int> storageOptionsGb,
            Map<String, dynamic> variant,
            Display? display,
            List<Camera> cameras,
            int? batteryMah,
            int? chargingWiredW,
            int? chargingWirelessW,
            double? weightG,
            Dimensions? dimensions,
            String? ipRating,
            String? os,
            String? osVersion,
            Connectivity? connectivity,
            String? imageUrl,
            List<String> images,
            SmartphoneScore? score,
            bool verified,
            List<String> sourceUrls,
            String? createdAt,
            String? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Smartphone():
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.baseModelSlug,
            _that.brand,
            _that.soc,
            _that.releaseDate,
            _that.msrpUsd,
            _that.ramGb,
            _that.storageOptionsGb,
            _that.variant,
            _that.display,
            _that.cameras,
            _that.batteryMah,
            _that.chargingWiredW,
            _that.chargingWirelessW,
            _that.weightG,
            _that.dimensions,
            _that.ipRating,
            _that.os,
            _that.osVersion,
            _that.connectivity,
            _that.imageUrl,
            _that.images,
            _that.score,
            _that.verified,
            _that.sourceUrls,
            _that.createdAt,
            _that.updatedAt);
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
            String? baseModelSlug,
            Brand? brand,
            Soc? soc,
            String? releaseDate,
            int? msrpUsd,
            int? ramGb,
            List<int> storageOptionsGb,
            Map<String, dynamic> variant,
            Display? display,
            List<Camera> cameras,
            int? batteryMah,
            int? chargingWiredW,
            int? chargingWirelessW,
            double? weightG,
            Dimensions? dimensions,
            String? ipRating,
            String? os,
            String? osVersion,
            Connectivity? connectivity,
            String? imageUrl,
            List<String> images,
            SmartphoneScore? score,
            bool verified,
            List<String> sourceUrls,
            String? createdAt,
            String? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Smartphone() when $default != null:
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.baseModelSlug,
            _that.brand,
            _that.soc,
            _that.releaseDate,
            _that.msrpUsd,
            _that.ramGb,
            _that.storageOptionsGb,
            _that.variant,
            _that.display,
            _that.cameras,
            _that.batteryMah,
            _that.chargingWiredW,
            _that.chargingWirelessW,
            _that.weightG,
            _that.dimensions,
            _that.ipRating,
            _that.os,
            _that.osVersion,
            _that.connectivity,
            _that.imageUrl,
            _that.images,
            _that.score,
            _that.verified,
            _that.sourceUrls,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Smartphone implements Smartphone {
  const _Smartphone(
      {required this.slug,
      required this.name,
      this.id,
      this.baseModelSlug,
      this.brand,
      this.soc,
      this.releaseDate,
      this.msrpUsd,
      this.ramGb,
      final List<int> storageOptionsGb = const <int>[],
      final Map<String, dynamic> variant = const <String, dynamic>{},
      this.display,
      final List<Camera> cameras = const <Camera>[],
      this.batteryMah,
      this.chargingWiredW,
      this.chargingWirelessW,
      this.weightG,
      this.dimensions,
      this.ipRating,
      this.os,
      this.osVersion,
      this.connectivity,
      this.imageUrl,
      final List<String> images = const <String>[],
      this.score,
      this.verified = false,
      final List<String> sourceUrls = const <String>[],
      this.createdAt,
      this.updatedAt})
      : _storageOptionsGb = storageOptionsGb,
        _variant = variant,
        _cameras = cameras,
        _images = images,
        _sourceUrls = sourceUrls;
  factory _Smartphone.fromJson(Map<String, dynamic> json) =>
      _$SmartphoneFromJson(json);

  @override
  final String slug;
  @override
  final String name;
  @override
  final int? id;

  /// 파생 모델일 때 원본 모델의 slug (예: Plus/Ultra 변형).
  @override
  final String? baseModelSlug;
  @override
  final Brand? brand;
  @override
  final Soc? soc;

  /// `YYYY-MM-DD`. 일자가 불확실하면 월초로 채워져 있다.
  @override
  final String? releaseDate;
  @override
  final int? msrpUsd;
  @override
  final int? ramGb;
  final List<int> _storageOptionsGb;
  @override
  @JsonKey()
  List<int> get storageOptionsGb {
    if (_storageOptionsGb is EqualUnmodifiableListView)
      return _storageOptionsGb;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_storageOptionsGb);
  }

  /// 지역·구성별 변형 정보. 스키마가 고정되어 있지 않아 원본 그대로 둔다.
  final Map<String, dynamic> _variant;

  /// 지역·구성별 변형 정보. 스키마가 고정되어 있지 않아 원본 그대로 둔다.
  @override
  @JsonKey()
  Map<String, dynamic> get variant {
    if (_variant is EqualUnmodifiableMapView) return _variant;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_variant);
  }

  @override
  final Display? display;
  final List<Camera> _cameras;
  @override
  @JsonKey()
  List<Camera> get cameras {
    if (_cameras is EqualUnmodifiableListView) return _cameras;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cameras);
  }

  @override
  final int? batteryMah;
  @override
  final int? chargingWiredW;
  @override
  final int? chargingWirelessW;
  @override
  final double? weightG;
  @override
  final Dimensions? dimensions;

  /// 방수·방진 등급 (예: `IP68`).
  @override
  final String? ipRating;
  @override
  final String? os;
  @override
  final String? osVersion;
  @override
  final Connectivity? connectivity;
  @override
  final String? imageUrl;
  final List<String> _images;
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final SmartphoneScore? score;
  @override
  @JsonKey()
  final bool verified;

  /// CC-BY-SA 4.0 조건상 UI에 반드시 노출해야 한다.
  final List<String> _sourceUrls;

  /// CC-BY-SA 4.0 조건상 UI에 반드시 노출해야 한다.
  @override
  @JsonKey()
  List<String> get sourceUrls {
    if (_sourceUrls is EqualUnmodifiableListView) return _sourceUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sourceUrls);
  }

  @override
  final String? createdAt;
  @override
  final String? updatedAt;

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SmartphoneCopyWith<_Smartphone> get copyWith =>
      __$SmartphoneCopyWithImpl<_Smartphone>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SmartphoneToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Smartphone &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.baseModelSlug, baseModelSlug) ||
                other.baseModelSlug == baseModelSlug) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.soc, soc) || other.soc == soc) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            (identical(other.msrpUsd, msrpUsd) || other.msrpUsd == msrpUsd) &&
            (identical(other.ramGb, ramGb) || other.ramGb == ramGb) &&
            const DeepCollectionEquality()
                .equals(other._storageOptionsGb, _storageOptionsGb) &&
            const DeepCollectionEquality().equals(other._variant, _variant) &&
            (identical(other.display, display) || other.display == display) &&
            const DeepCollectionEquality().equals(other._cameras, _cameras) &&
            (identical(other.batteryMah, batteryMah) ||
                other.batteryMah == batteryMah) &&
            (identical(other.chargingWiredW, chargingWiredW) ||
                other.chargingWiredW == chargingWiredW) &&
            (identical(other.chargingWirelessW, chargingWirelessW) ||
                other.chargingWirelessW == chargingWirelessW) &&
            (identical(other.weightG, weightG) || other.weightG == weightG) &&
            (identical(other.dimensions, dimensions) ||
                other.dimensions == dimensions) &&
            (identical(other.ipRating, ipRating) ||
                other.ipRating == ipRating) &&
            (identical(other.os, os) || other.os == os) &&
            (identical(other.osVersion, osVersion) ||
                other.osVersion == osVersion) &&
            (identical(other.connectivity, connectivity) ||
                other.connectivity == connectivity) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            const DeepCollectionEquality()
                .equals(other._sourceUrls, _sourceUrls) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        slug,
        name,
        id,
        baseModelSlug,
        brand,
        soc,
        releaseDate,
        msrpUsd,
        ramGb,
        const DeepCollectionEquality().hash(_storageOptionsGb),
        const DeepCollectionEquality().hash(_variant),
        display,
        const DeepCollectionEquality().hash(_cameras),
        batteryMah,
        chargingWiredW,
        chargingWirelessW,
        weightG,
        dimensions,
        ipRating,
        os,
        osVersion,
        connectivity,
        imageUrl,
        const DeepCollectionEquality().hash(_images),
        score,
        verified,
        const DeepCollectionEquality().hash(_sourceUrls),
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'Smartphone(slug: $slug, name: $name, id: $id, baseModelSlug: $baseModelSlug, brand: $brand, soc: $soc, releaseDate: $releaseDate, msrpUsd: $msrpUsd, ramGb: $ramGb, storageOptionsGb: $storageOptionsGb, variant: $variant, display: $display, cameras: $cameras, batteryMah: $batteryMah, chargingWiredW: $chargingWiredW, chargingWirelessW: $chargingWirelessW, weightG: $weightG, dimensions: $dimensions, ipRating: $ipRating, os: $os, osVersion: $osVersion, connectivity: $connectivity, imageUrl: $imageUrl, images: $images, score: $score, verified: $verified, sourceUrls: $sourceUrls, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$SmartphoneCopyWith<$Res>
    implements $SmartphoneCopyWith<$Res> {
  factory _$SmartphoneCopyWith(
          _Smartphone value, $Res Function(_Smartphone) _then) =
      __$SmartphoneCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String slug,
      String name,
      int? id,
      String? baseModelSlug,
      Brand? brand,
      Soc? soc,
      String? releaseDate,
      int? msrpUsd,
      int? ramGb,
      List<int> storageOptionsGb,
      Map<String, dynamic> variant,
      Display? display,
      List<Camera> cameras,
      int? batteryMah,
      int? chargingWiredW,
      int? chargingWirelessW,
      double? weightG,
      Dimensions? dimensions,
      String? ipRating,
      String? os,
      String? osVersion,
      Connectivity? connectivity,
      String? imageUrl,
      List<String> images,
      SmartphoneScore? score,
      bool verified,
      List<String> sourceUrls,
      String? createdAt,
      String? updatedAt});

  @override
  $BrandCopyWith<$Res>? get brand;
  @override
  $SocCopyWith<$Res>? get soc;
  @override
  $DisplayCopyWith<$Res>? get display;
  @override
  $DimensionsCopyWith<$Res>? get dimensions;
  @override
  $ConnectivityCopyWith<$Res>? get connectivity;
  @override
  $SmartphoneScoreCopyWith<$Res>? get score;
}

/// @nodoc
class __$SmartphoneCopyWithImpl<$Res> implements _$SmartphoneCopyWith<$Res> {
  __$SmartphoneCopyWithImpl(this._self, this._then);

  final _Smartphone _self;
  final $Res Function(_Smartphone) _then;

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? id = freezed,
    Object? baseModelSlug = freezed,
    Object? brand = freezed,
    Object? soc = freezed,
    Object? releaseDate = freezed,
    Object? msrpUsd = freezed,
    Object? ramGb = freezed,
    Object? storageOptionsGb = null,
    Object? variant = null,
    Object? display = freezed,
    Object? cameras = null,
    Object? batteryMah = freezed,
    Object? chargingWiredW = freezed,
    Object? chargingWirelessW = freezed,
    Object? weightG = freezed,
    Object? dimensions = freezed,
    Object? ipRating = freezed,
    Object? os = freezed,
    Object? osVersion = freezed,
    Object? connectivity = freezed,
    Object? imageUrl = freezed,
    Object? images = null,
    Object? score = freezed,
    Object? verified = null,
    Object? sourceUrls = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_Smartphone(
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
      baseModelSlug: freezed == baseModelSlug
          ? _self.baseModelSlug
          : baseModelSlug // ignore: cast_nullable_to_non_nullable
              as String?,
      brand: freezed == brand
          ? _self.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as Brand?,
      soc: freezed == soc
          ? _self.soc
          : soc // ignore: cast_nullable_to_non_nullable
              as Soc?,
      releaseDate: freezed == releaseDate
          ? _self.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as String?,
      msrpUsd: freezed == msrpUsd
          ? _self.msrpUsd
          : msrpUsd // ignore: cast_nullable_to_non_nullable
              as int?,
      ramGb: freezed == ramGb
          ? _self.ramGb
          : ramGb // ignore: cast_nullable_to_non_nullable
              as int?,
      storageOptionsGb: null == storageOptionsGb
          ? _self._storageOptionsGb
          : storageOptionsGb // ignore: cast_nullable_to_non_nullable
              as List<int>,
      variant: null == variant
          ? _self._variant
          : variant // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      display: freezed == display
          ? _self.display
          : display // ignore: cast_nullable_to_non_nullable
              as Display?,
      cameras: null == cameras
          ? _self._cameras
          : cameras // ignore: cast_nullable_to_non_nullable
              as List<Camera>,
      batteryMah: freezed == batteryMah
          ? _self.batteryMah
          : batteryMah // ignore: cast_nullable_to_non_nullable
              as int?,
      chargingWiredW: freezed == chargingWiredW
          ? _self.chargingWiredW
          : chargingWiredW // ignore: cast_nullable_to_non_nullable
              as int?,
      chargingWirelessW: freezed == chargingWirelessW
          ? _self.chargingWirelessW
          : chargingWirelessW // ignore: cast_nullable_to_non_nullable
              as int?,
      weightG: freezed == weightG
          ? _self.weightG
          : weightG // ignore: cast_nullable_to_non_nullable
              as double?,
      dimensions: freezed == dimensions
          ? _self.dimensions
          : dimensions // ignore: cast_nullable_to_non_nullable
              as Dimensions?,
      ipRating: freezed == ipRating
          ? _self.ipRating
          : ipRating // ignore: cast_nullable_to_non_nullable
              as String?,
      os: freezed == os
          ? _self.os
          : os // ignore: cast_nullable_to_non_nullable
              as String?,
      osVersion: freezed == osVersion
          ? _self.osVersion
          : osVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      connectivity: freezed == connectivity
          ? _self.connectivity
          : connectivity // ignore: cast_nullable_to_non_nullable
              as Connectivity?,
      imageUrl: freezed == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      images: null == images
          ? _self._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      score: freezed == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as SmartphoneScore?,
      verified: null == verified
          ? _self.verified
          : verified // ignore: cast_nullable_to_non_nullable
              as bool,
      sourceUrls: null == sourceUrls
          ? _self._sourceUrls
          : sourceUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }

  /// Create a copy of Smartphone
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
  }

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SocCopyWith<$Res>? get soc {
    if (_self.soc == null) {
      return null;
    }

    return $SocCopyWith<$Res>(_self.soc!, (value) {
      return _then(_self.copyWith(soc: value));
    });
  }

  /// Create a copy of Smartphone
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

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DimensionsCopyWith<$Res>? get dimensions {
    if (_self.dimensions == null) {
      return null;
    }

    return $DimensionsCopyWith<$Res>(_self.dimensions!, (value) {
      return _then(_self.copyWith(dimensions: value));
    });
  }

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ConnectivityCopyWith<$Res>? get connectivity {
    if (_self.connectivity == null) {
      return null;
    }

    return $ConnectivityCopyWith<$Res>(_self.connectivity!, (value) {
      return _then(_self.copyWith(connectivity: value));
    });
  }

  /// Create a copy of Smartphone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SmartphoneScoreCopyWith<$Res>? get score {
    if (_self.score == null) {
      return null;
    }

    return $SmartphoneScoreCopyWith<$Res>(_self.score!, (value) {
      return _then(_self.copyWith(score: value));
    });
  }
}

// dart format on
