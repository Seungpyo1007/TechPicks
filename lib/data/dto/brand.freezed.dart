// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'brand.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Brand {
  String get slug;
  String get name;
  int? get id;

  /// ISO 3166-1 alpha-2 (예: `KR`).
  String? get country;
  int? get foundedYear;
  String? get logoUrl;
  String? get website;

  /// 설명은 언어별로 따로 온다. `?lang=` 파라미터가 아니라 별도 필드다.
  String? get descriptionEn;
  String? get descriptionKo;

  /// API 내부 상대 경로 (예: `/v1/brands/samsung`).
  String? get url;
  List<String> get sourceUrls;

  /// Create a copy of Brand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BrandCopyWith<Brand> get copyWith =>
      _$BrandCopyWithImpl<Brand>(this as Brand, _$identity);

  /// Serializes this Brand to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Brand &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.foundedYear, foundedYear) ||
                other.foundedYear == foundedYear) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.descriptionEn, descriptionEn) ||
                other.descriptionEn == descriptionEn) &&
            (identical(other.descriptionKo, descriptionKo) ||
                other.descriptionKo == descriptionKo) &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality()
                .equals(other.sourceUrls, sourceUrls));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      slug,
      name,
      id,
      country,
      foundedYear,
      logoUrl,
      website,
      descriptionEn,
      descriptionKo,
      url,
      const DeepCollectionEquality().hash(sourceUrls));

  @override
  String toString() {
    return 'Brand(slug: $slug, name: $name, id: $id, country: $country, foundedYear: $foundedYear, logoUrl: $logoUrl, website: $website, descriptionEn: $descriptionEn, descriptionKo: $descriptionKo, url: $url, sourceUrls: $sourceUrls)';
  }
}

/// @nodoc
abstract mixin class $BrandCopyWith<$Res> {
  factory $BrandCopyWith(Brand value, $Res Function(Brand) _then) =
      _$BrandCopyWithImpl;
  @useResult
  $Res call(
      {String slug,
      String name,
      int? id,
      String? country,
      int? foundedYear,
      String? logoUrl,
      String? website,
      String? descriptionEn,
      String? descriptionKo,
      String? url,
      List<String> sourceUrls});
}

/// @nodoc
class _$BrandCopyWithImpl<$Res> implements $BrandCopyWith<$Res> {
  _$BrandCopyWithImpl(this._self, this._then);

  final Brand _self;
  final $Res Function(Brand) _then;

  /// Create a copy of Brand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? id = freezed,
    Object? country = freezed,
    Object? foundedYear = freezed,
    Object? logoUrl = freezed,
    Object? website = freezed,
    Object? descriptionEn = freezed,
    Object? descriptionKo = freezed,
    Object? url = freezed,
    Object? sourceUrls = null,
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
      country: freezed == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      foundedYear: freezed == foundedYear
          ? _self.foundedYear
          : foundedYear // ignore: cast_nullable_to_non_nullable
              as int?,
      logoUrl: freezed == logoUrl
          ? _self.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      website: freezed == website
          ? _self.website
          : website // ignore: cast_nullable_to_non_nullable
              as String?,
      descriptionEn: freezed == descriptionEn
          ? _self.descriptionEn
          : descriptionEn // ignore: cast_nullable_to_non_nullable
              as String?,
      descriptionKo: freezed == descriptionKo
          ? _self.descriptionKo
          : descriptionKo // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceUrls: null == sourceUrls
          ? _self.sourceUrls
          : sourceUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [Brand].
extension BrandPatterns on Brand {
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
    TResult Function(_Brand value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Brand() when $default != null:
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
    TResult Function(_Brand value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Brand():
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
    TResult? Function(_Brand value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Brand() when $default != null:
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
            String? country,
            int? foundedYear,
            String? logoUrl,
            String? website,
            String? descriptionEn,
            String? descriptionKo,
            String? url,
            List<String> sourceUrls)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Brand() when $default != null:
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.country,
            _that.foundedYear,
            _that.logoUrl,
            _that.website,
            _that.descriptionEn,
            _that.descriptionKo,
            _that.url,
            _that.sourceUrls);
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
            String? country,
            int? foundedYear,
            String? logoUrl,
            String? website,
            String? descriptionEn,
            String? descriptionKo,
            String? url,
            List<String> sourceUrls)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Brand():
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.country,
            _that.foundedYear,
            _that.logoUrl,
            _that.website,
            _that.descriptionEn,
            _that.descriptionKo,
            _that.url,
            _that.sourceUrls);
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
            String? country,
            int? foundedYear,
            String? logoUrl,
            String? website,
            String? descriptionEn,
            String? descriptionKo,
            String? url,
            List<String> sourceUrls)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Brand() when $default != null:
        return $default(
            _that.slug,
            _that.name,
            _that.id,
            _that.country,
            _that.foundedYear,
            _that.logoUrl,
            _that.website,
            _that.descriptionEn,
            _that.descriptionKo,
            _that.url,
            _that.sourceUrls);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Brand implements Brand {
  const _Brand(
      {required this.slug,
      required this.name,
      this.id,
      this.country,
      this.foundedYear,
      this.logoUrl,
      this.website,
      this.descriptionEn,
      this.descriptionKo,
      this.url,
      final List<String> sourceUrls = const <String>[]})
      : _sourceUrls = sourceUrls;
  factory _Brand.fromJson(Map<String, dynamic> json) => _$BrandFromJson(json);

  @override
  final String slug;
  @override
  final String name;
  @override
  final int? id;

  /// ISO 3166-1 alpha-2 (예: `KR`).
  @override
  final String? country;
  @override
  final int? foundedYear;
  @override
  final String? logoUrl;
  @override
  final String? website;

  /// 설명은 언어별로 따로 온다. `?lang=` 파라미터가 아니라 별도 필드다.
  @override
  final String? descriptionEn;
  @override
  final String? descriptionKo;

  /// API 내부 상대 경로 (예: `/v1/brands/samsung`).
  @override
  final String? url;
  final List<String> _sourceUrls;
  @override
  @JsonKey()
  List<String> get sourceUrls {
    if (_sourceUrls is EqualUnmodifiableListView) return _sourceUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sourceUrls);
  }

  /// Create a copy of Brand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BrandCopyWith<_Brand> get copyWith =>
      __$BrandCopyWithImpl<_Brand>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BrandToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Brand &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.foundedYear, foundedYear) ||
                other.foundedYear == foundedYear) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.descriptionEn, descriptionEn) ||
                other.descriptionEn == descriptionEn) &&
            (identical(other.descriptionKo, descriptionKo) ||
                other.descriptionKo == descriptionKo) &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality()
                .equals(other._sourceUrls, _sourceUrls));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      slug,
      name,
      id,
      country,
      foundedYear,
      logoUrl,
      website,
      descriptionEn,
      descriptionKo,
      url,
      const DeepCollectionEquality().hash(_sourceUrls));

  @override
  String toString() {
    return 'Brand(slug: $slug, name: $name, id: $id, country: $country, foundedYear: $foundedYear, logoUrl: $logoUrl, website: $website, descriptionEn: $descriptionEn, descriptionKo: $descriptionKo, url: $url, sourceUrls: $sourceUrls)';
  }
}

/// @nodoc
abstract mixin class _$BrandCopyWith<$Res> implements $BrandCopyWith<$Res> {
  factory _$BrandCopyWith(_Brand value, $Res Function(_Brand) _then) =
      __$BrandCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String slug,
      String name,
      int? id,
      String? country,
      int? foundedYear,
      String? logoUrl,
      String? website,
      String? descriptionEn,
      String? descriptionKo,
      String? url,
      List<String> sourceUrls});
}

/// @nodoc
class __$BrandCopyWithImpl<$Res> implements _$BrandCopyWith<$Res> {
  __$BrandCopyWithImpl(this._self, this._then);

  final _Brand _self;
  final $Res Function(_Brand) _then;

  /// Create a copy of Brand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? id = freezed,
    Object? country = freezed,
    Object? foundedYear = freezed,
    Object? logoUrl = freezed,
    Object? website = freezed,
    Object? descriptionEn = freezed,
    Object? descriptionKo = freezed,
    Object? url = freezed,
    Object? sourceUrls = null,
  }) {
    return _then(_Brand(
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
      country: freezed == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      foundedYear: freezed == foundedYear
          ? _self.foundedYear
          : foundedYear // ignore: cast_nullable_to_non_nullable
              as int?,
      logoUrl: freezed == logoUrl
          ? _self.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      website: freezed == website
          ? _self.website
          : website // ignore: cast_nullable_to_non_nullable
              as String?,
      descriptionEn: freezed == descriptionEn
          ? _self.descriptionEn
          : descriptionEn // ignore: cast_nullable_to_non_nullable
              as String?,
      descriptionKo: freezed == descriptionKo
          ? _self.descriptionKo
          : descriptionKo // ignore: cast_nullable_to_non_nullable
              as String?,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceUrls: null == sourceUrls
          ? _self._sourceUrls
          : sourceUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
