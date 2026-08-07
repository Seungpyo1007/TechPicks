// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'collection_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ResourceRef {
  String get slug;
  String get name;
  String? get url;

  /// Create a copy of ResourceRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ResourceRefCopyWith<ResourceRef> get copyWith =>
      _$ResourceRefCopyWithImpl<ResourceRef>(this as ResourceRef, _$identity);

  /// Serializes this ResourceRef to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ResourceRef &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, slug, name, url);

  @override
  String toString() {
    return 'ResourceRef(slug: $slug, name: $name, url: $url)';
  }
}

/// @nodoc
abstract mixin class $ResourceRefCopyWith<$Res> {
  factory $ResourceRefCopyWith(
          ResourceRef value, $Res Function(ResourceRef) _then) =
      _$ResourceRefCopyWithImpl;
  @useResult
  $Res call({String slug, String name, String? url});
}

/// @nodoc
class _$ResourceRefCopyWithImpl<$Res> implements $ResourceRefCopyWith<$Res> {
  _$ResourceRefCopyWithImpl(this._self, this._then);

  final ResourceRef _self;
  final $Res Function(ResourceRef) _then;

  /// Create a copy of ResourceRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? slug = null,
    Object? name = null,
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
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ResourceRef].
extension ResourceRefPatterns on ResourceRef {
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
    TResult Function(_ResourceRef value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ResourceRef() when $default != null:
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
    TResult Function(_ResourceRef value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResourceRef():
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
    TResult? Function(_ResourceRef value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResourceRef() when $default != null:
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
    TResult Function(String slug, String name, String? url)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ResourceRef() when $default != null:
        return $default(_that.slug, _that.name, _that.url);
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
    TResult Function(String slug, String name, String? url) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResourceRef():
        return $default(_that.slug, _that.name, _that.url);
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
    TResult? Function(String slug, String name, String? url)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ResourceRef() when $default != null:
        return $default(_that.slug, _that.name, _that.url);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ResourceRef implements ResourceRef {
  const _ResourceRef({required this.slug, required this.name, this.url});
  factory _ResourceRef.fromJson(Map<String, dynamic> json) =>
      _$ResourceRefFromJson(json);

  @override
  final String slug;
  @override
  final String name;
  @override
  final String? url;

  /// Create a copy of ResourceRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ResourceRefCopyWith<_ResourceRef> get copyWith =>
      __$ResourceRefCopyWithImpl<_ResourceRef>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ResourceRefToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ResourceRef &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, slug, name, url);

  @override
  String toString() {
    return 'ResourceRef(slug: $slug, name: $name, url: $url)';
  }
}

/// @nodoc
abstract mixin class _$ResourceRefCopyWith<$Res>
    implements $ResourceRefCopyWith<$Res> {
  factory _$ResourceRefCopyWith(
          _ResourceRef value, $Res Function(_ResourceRef) _then) =
      __$ResourceRefCopyWithImpl;
  @override
  @useResult
  $Res call({String slug, String name, String? url});
}

/// @nodoc
class __$ResourceRefCopyWithImpl<$Res> implements _$ResourceRefCopyWith<$Res> {
  __$ResourceRefCopyWithImpl(this._self, this._then);

  final _ResourceRef _self;
  final $Res Function(_ResourceRef) _then;

  /// Create a copy of ResourceRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? slug = null,
    Object? name = null,
    Object? url = freezed,
  }) {
    return _then(_ResourceRef(
      slug: null == slug
          ? _self.slug
          : slug // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      url: freezed == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$CollectionPage {
  int get count;
  List<ResourceRef> get results;
  String? get next;
  String? get previous;

  /// Create a copy of CollectionPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CollectionPageCopyWith<CollectionPage> get copyWith =>
      _$CollectionPageCopyWithImpl<CollectionPage>(
          this as CollectionPage, _$identity);

  /// Serializes this CollectionPage to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CollectionPage &&
            (identical(other.count, count) || other.count == count) &&
            const DeepCollectionEquality().equals(other.results, results) &&
            (identical(other.next, next) || other.next == next) &&
            (identical(other.previous, previous) ||
                other.previous == previous));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, count,
      const DeepCollectionEquality().hash(results), next, previous);

  @override
  String toString() {
    return 'CollectionPage(count: $count, results: $results, next: $next, previous: $previous)';
  }
}

/// @nodoc
abstract mixin class $CollectionPageCopyWith<$Res> {
  factory $CollectionPageCopyWith(
          CollectionPage value, $Res Function(CollectionPage) _then) =
      _$CollectionPageCopyWithImpl;
  @useResult
  $Res call(
      {int count, List<ResourceRef> results, String? next, String? previous});
}

/// @nodoc
class _$CollectionPageCopyWithImpl<$Res>
    implements $CollectionPageCopyWith<$Res> {
  _$CollectionPageCopyWithImpl(this._self, this._then);

  final CollectionPage _self;
  final $Res Function(CollectionPage) _then;

  /// Create a copy of CollectionPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? results = null,
    Object? next = freezed,
    Object? previous = freezed,
  }) {
    return _then(_self.copyWith(
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _self.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<ResourceRef>,
      next: freezed == next
          ? _self.next
          : next // ignore: cast_nullable_to_non_nullable
              as String?,
      previous: freezed == previous
          ? _self.previous
          : previous // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [CollectionPage].
extension CollectionPagePatterns on CollectionPage {
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
    TResult Function(_CollectionPage value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CollectionPage() when $default != null:
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
    TResult Function(_CollectionPage value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CollectionPage():
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
    TResult? Function(_CollectionPage value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CollectionPage() when $default != null:
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
    TResult Function(int count, List<ResourceRef> results, String? next,
            String? previous)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CollectionPage() when $default != null:
        return $default(_that.count, _that.results, _that.next, _that.previous);
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
    TResult Function(int count, List<ResourceRef> results, String? next,
            String? previous)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CollectionPage():
        return $default(_that.count, _that.results, _that.next, _that.previous);
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
    TResult? Function(int count, List<ResourceRef> results, String? next,
            String? previous)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CollectionPage() when $default != null:
        return $default(_that.count, _that.results, _that.next, _that.previous);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CollectionPage implements CollectionPage {
  const _CollectionPage(
      {this.count = 0,
      final List<ResourceRef> results = const <ResourceRef>[],
      this.next,
      this.previous})
      : _results = results;
  factory _CollectionPage.fromJson(Map<String, dynamic> json) =>
      _$CollectionPageFromJson(json);

  @override
  @JsonKey()
  final int count;
  final List<ResourceRef> _results;
  @override
  @JsonKey()
  List<ResourceRef> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final String? next;
  @override
  final String? previous;

  /// Create a copy of CollectionPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CollectionPageCopyWith<_CollectionPage> get copyWith =>
      __$CollectionPageCopyWithImpl<_CollectionPage>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CollectionPageToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CollectionPage &&
            (identical(other.count, count) || other.count == count) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.next, next) || other.next == next) &&
            (identical(other.previous, previous) ||
                other.previous == previous));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, count,
      const DeepCollectionEquality().hash(_results), next, previous);

  @override
  String toString() {
    return 'CollectionPage(count: $count, results: $results, next: $next, previous: $previous)';
  }
}

/// @nodoc
abstract mixin class _$CollectionPageCopyWith<$Res>
    implements $CollectionPageCopyWith<$Res> {
  factory _$CollectionPageCopyWith(
          _CollectionPage value, $Res Function(_CollectionPage) _then) =
      __$CollectionPageCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int count, List<ResourceRef> results, String? next, String? previous});
}

/// @nodoc
class __$CollectionPageCopyWithImpl<$Res>
    implements _$CollectionPageCopyWith<$Res> {
  __$CollectionPageCopyWithImpl(this._self, this._then);

  final _CollectionPage _self;
  final $Res Function(_CollectionPage) _then;

  /// Create a copy of CollectionPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? count = null,
    Object? results = null,
    Object? next = freezed,
    Object? previous = freezed,
  }) {
    return _then(_CollectionPage(
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _self._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<ResourceRef>,
      next: freezed == next
          ? _self.next
          : next // ignore: cast_nullable_to_non_nullable
              as String?,
      previous: freezed == previous
          ? _self.previous
          : previous // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
