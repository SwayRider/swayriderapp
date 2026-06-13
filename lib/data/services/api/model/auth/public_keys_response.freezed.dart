// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_keys_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PublicKeysResponse {

@JsonKey(name: 'keys') List<String> get keys;
/// Create a copy of PublicKeysResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicKeysResponseCopyWith<PublicKeysResponse> get copyWith => _$PublicKeysResponseCopyWithImpl<PublicKeysResponse>(this as PublicKeysResponse, _$identity);

  /// Serializes this PublicKeysResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicKeysResponse&&const DeepCollectionEquality().equals(other.keys, keys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(keys));

@override
String toString() {
  return 'PublicKeysResponse(keys: $keys)';
}


}

/// @nodoc
abstract mixin class $PublicKeysResponseCopyWith<$Res>  {
  factory $PublicKeysResponseCopyWith(PublicKeysResponse value, $Res Function(PublicKeysResponse) _then) = _$PublicKeysResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'keys') List<String> keys
});




}
/// @nodoc
class _$PublicKeysResponseCopyWithImpl<$Res>
    implements $PublicKeysResponseCopyWith<$Res> {
  _$PublicKeysResponseCopyWithImpl(this._self, this._then);

  final PublicKeysResponse _self;
  final $Res Function(PublicKeysResponse) _then;

/// Create a copy of PublicKeysResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keys = null,}) {
  return _then(_self.copyWith(
keys: null == keys ? _self.keys : keys // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PublicKeysResponse].
extension PublicKeysResponsePatterns on PublicKeysResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicKeysResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicKeysResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicKeysResponse value)  $default,){
final _that = this;
switch (_that) {
case _PublicKeysResponse():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicKeysResponse value)?  $default,){
final _that = this;
switch (_that) {
case _PublicKeysResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'keys')  List<String> keys)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicKeysResponse() when $default != null:
return $default(_that.keys);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'keys')  List<String> keys)  $default,) {final _that = this;
switch (_that) {
case _PublicKeysResponse():
return $default(_that.keys);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'keys')  List<String> keys)?  $default,) {final _that = this;
switch (_that) {
case _PublicKeysResponse() when $default != null:
return $default(_that.keys);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PublicKeysResponse implements PublicKeysResponse {
  const _PublicKeysResponse({@JsonKey(name: 'keys') required final  List<String> keys}): _keys = keys;
  factory _PublicKeysResponse.fromJson(Map<String, dynamic> json) => _$PublicKeysResponseFromJson(json);

 final  List<String> _keys;
@override@JsonKey(name: 'keys') List<String> get keys {
  if (_keys is EqualUnmodifiableListView) return _keys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keys);
}


/// Create a copy of PublicKeysResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicKeysResponseCopyWith<_PublicKeysResponse> get copyWith => __$PublicKeysResponseCopyWithImpl<_PublicKeysResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicKeysResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicKeysResponse&&const DeepCollectionEquality().equals(other._keys, _keys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_keys));

@override
String toString() {
  return 'PublicKeysResponse(keys: $keys)';
}


}

/// @nodoc
abstract mixin class _$PublicKeysResponseCopyWith<$Res> implements $PublicKeysResponseCopyWith<$Res> {
  factory _$PublicKeysResponseCopyWith(_PublicKeysResponse value, $Res Function(_PublicKeysResponse) _then) = __$PublicKeysResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'keys') List<String> keys
});




}
/// @nodoc
class __$PublicKeysResponseCopyWithImpl<$Res>
    implements _$PublicKeysResponseCopyWith<$Res> {
  __$PublicKeysResponseCopyWithImpl(this._self, this._then);

  final _PublicKeysResponse _self;
  final $Res Function(_PublicKeysResponse) _then;

/// Create a copy of PublicKeysResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keys = null,}) {
  return _then(_PublicKeysResponse(
keys: null == keys ? _self._keys : keys // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
