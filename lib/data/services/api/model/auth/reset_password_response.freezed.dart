// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reset_password_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ResetPasswordResponse {

@JsonKey(name: 'message') String get message;
/// Create a copy of ResetPasswordResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPasswordResponseCopyWith<ResetPasswordResponse> get copyWith => _$ResetPasswordResponseCopyWithImpl<ResetPasswordResponse>(this as ResetPasswordResponse, _$identity);

  /// Serializes this ResetPasswordResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordResponse&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ResetPasswordResponse(message: $message)';
}


}

/// @nodoc
abstract mixin class $ResetPasswordResponseCopyWith<$Res>  {
  factory $ResetPasswordResponseCopyWith(ResetPasswordResponse value, $Res Function(ResetPasswordResponse) _then) = _$ResetPasswordResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'message') String message
});




}
/// @nodoc
class _$ResetPasswordResponseCopyWithImpl<$Res>
    implements $ResetPasswordResponseCopyWith<$Res> {
  _$ResetPasswordResponseCopyWithImpl(this._self, this._then);

  final ResetPasswordResponse _self;
  final $Res Function(ResetPasswordResponse) _then;

/// Create a copy of ResetPasswordResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ResetPasswordResponse].
extension ResetPasswordResponsePatterns on ResetPasswordResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResetPasswordResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResetPasswordResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResetPasswordResponse value)  $default,){
final _that = this;
switch (_that) {
case _ResetPasswordResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResetPasswordResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ResetPasswordResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'message')  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResetPasswordResponse() when $default != null:
return $default(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'message')  String message)  $default,) {final _that = this;
switch (_that) {
case _ResetPasswordResponse():
return $default(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'message')  String message)?  $default,) {final _that = this;
switch (_that) {
case _ResetPasswordResponse() when $default != null:
return $default(_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResetPasswordResponse implements ResetPasswordResponse {
  const _ResetPasswordResponse({@JsonKey(name: 'message') required this.message});
  factory _ResetPasswordResponse.fromJson(Map<String, dynamic> json) => _$ResetPasswordResponseFromJson(json);

@override@JsonKey(name: 'message') final  String message;

/// Create a copy of ResetPasswordResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResetPasswordResponseCopyWith<_ResetPasswordResponse> get copyWith => __$ResetPasswordResponseCopyWithImpl<_ResetPasswordResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResetPasswordResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResetPasswordResponse&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ResetPasswordResponse(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ResetPasswordResponseCopyWith<$Res> implements $ResetPasswordResponseCopyWith<$Res> {
  factory _$ResetPasswordResponseCopyWith(_ResetPasswordResponse value, $Res Function(_ResetPasswordResponse) _then) = __$ResetPasswordResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'message') String message
});




}
/// @nodoc
class __$ResetPasswordResponseCopyWithImpl<$Res>
    implements _$ResetPasswordResponseCopyWith<$Res> {
  __$ResetPasswordResponseCopyWithImpl(this._self, this._then);

  final _ResetPasswordResponse _self;
  final $Res Function(_ResetPasswordResponse) _then;

/// Create a copy of ResetPasswordResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_ResetPasswordResponse(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
