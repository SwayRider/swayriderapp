// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enable_mfa_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EnableMFAResponse {

@JsonKey(name: 'backup_codes') List<String> get backupCodes;
/// Create a copy of EnableMFAResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnableMFAResponseCopyWith<EnableMFAResponse> get copyWith => _$EnableMFAResponseCopyWithImpl<EnableMFAResponse>(this as EnableMFAResponse, _$identity);

  /// Serializes this EnableMFAResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnableMFAResponse&&const DeepCollectionEquality().equals(other.backupCodes, backupCodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(backupCodes));

@override
String toString() {
  return 'EnableMFAResponse(backupCodes: $backupCodes)';
}


}

/// @nodoc
abstract mixin class $EnableMFAResponseCopyWith<$Res>  {
  factory $EnableMFAResponseCopyWith(EnableMFAResponse value, $Res Function(EnableMFAResponse) _then) = _$EnableMFAResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'backup_codes') List<String> backupCodes
});




}
/// @nodoc
class _$EnableMFAResponseCopyWithImpl<$Res>
    implements $EnableMFAResponseCopyWith<$Res> {
  _$EnableMFAResponseCopyWithImpl(this._self, this._then);

  final EnableMFAResponse _self;
  final $Res Function(EnableMFAResponse) _then;

/// Create a copy of EnableMFAResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? backupCodes = null,}) {
  return _then(_self.copyWith(
backupCodes: null == backupCodes ? _self.backupCodes : backupCodes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [EnableMFAResponse].
extension EnableMFAResponsePatterns on EnableMFAResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnableMFAResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnableMFAResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnableMFAResponse value)  $default,){
final _that = this;
switch (_that) {
case _EnableMFAResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnableMFAResponse value)?  $default,){
final _that = this;
switch (_that) {
case _EnableMFAResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'backup_codes')  List<String> backupCodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnableMFAResponse() when $default != null:
return $default(_that.backupCodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'backup_codes')  List<String> backupCodes)  $default,) {final _that = this;
switch (_that) {
case _EnableMFAResponse():
return $default(_that.backupCodes);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'backup_codes')  List<String> backupCodes)?  $default,) {final _that = this;
switch (_that) {
case _EnableMFAResponse() when $default != null:
return $default(_that.backupCodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnableMFAResponse implements EnableMFAResponse {
  const _EnableMFAResponse({@JsonKey(name: 'backup_codes') required final  List<String> backupCodes}): _backupCodes = backupCodes;
  factory _EnableMFAResponse.fromJson(Map<String, dynamic> json) => _$EnableMFAResponseFromJson(json);

 final  List<String> _backupCodes;
@override@JsonKey(name: 'backup_codes') List<String> get backupCodes {
  if (_backupCodes is EqualUnmodifiableListView) return _backupCodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_backupCodes);
}


/// Create a copy of EnableMFAResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnableMFAResponseCopyWith<_EnableMFAResponse> get copyWith => __$EnableMFAResponseCopyWithImpl<_EnableMFAResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnableMFAResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnableMFAResponse&&const DeepCollectionEquality().equals(other._backupCodes, _backupCodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_backupCodes));

@override
String toString() {
  return 'EnableMFAResponse(backupCodes: $backupCodes)';
}


}

/// @nodoc
abstract mixin class _$EnableMFAResponseCopyWith<$Res> implements $EnableMFAResponseCopyWith<$Res> {
  factory _$EnableMFAResponseCopyWith(_EnableMFAResponse value, $Res Function(_EnableMFAResponse) _then) = __$EnableMFAResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'backup_codes') List<String> backupCodes
});




}
/// @nodoc
class __$EnableMFAResponseCopyWithImpl<$Res>
    implements _$EnableMFAResponseCopyWith<$Res> {
  __$EnableMFAResponseCopyWithImpl(this._self, this._then);

  final _EnableMFAResponse _self;
  final $Res Function(_EnableMFAResponse) _then;

/// Create a copy of EnableMFAResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? backupCodes = null,}) {
  return _then(_EnableMFAResponse(
backupCodes: null == backupCodes ? _self._backupCodes : backupCodes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
