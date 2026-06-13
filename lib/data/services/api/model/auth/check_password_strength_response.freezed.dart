// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_password_strength_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CheckPasswordStrengthResponse {

@JsonKey(name: 'isStrong') bool get isStrong;@JsonKey(name: 'message') String get message;
/// Create a copy of CheckPasswordStrengthResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckPasswordStrengthResponseCopyWith<CheckPasswordStrengthResponse> get copyWith => _$CheckPasswordStrengthResponseCopyWithImpl<CheckPasswordStrengthResponse>(this as CheckPasswordStrengthResponse, _$identity);

  /// Serializes this CheckPasswordStrengthResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckPasswordStrengthResponse&&(identical(other.isStrong, isStrong) || other.isStrong == isStrong)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isStrong,message);

@override
String toString() {
  return 'CheckPasswordStrengthResponse(isStrong: $isStrong, message: $message)';
}


}

/// @nodoc
abstract mixin class $CheckPasswordStrengthResponseCopyWith<$Res>  {
  factory $CheckPasswordStrengthResponseCopyWith(CheckPasswordStrengthResponse value, $Res Function(CheckPasswordStrengthResponse) _then) = _$CheckPasswordStrengthResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'isStrong') bool isStrong,@JsonKey(name: 'message') String message
});




}
/// @nodoc
class _$CheckPasswordStrengthResponseCopyWithImpl<$Res>
    implements $CheckPasswordStrengthResponseCopyWith<$Res> {
  _$CheckPasswordStrengthResponseCopyWithImpl(this._self, this._then);

  final CheckPasswordStrengthResponse _self;
  final $Res Function(CheckPasswordStrengthResponse) _then;

/// Create a copy of CheckPasswordStrengthResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isStrong = null,Object? message = null,}) {
  return _then(_self.copyWith(
isStrong: null == isStrong ? _self.isStrong : isStrong // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckPasswordStrengthResponse].
extension CheckPasswordStrengthResponsePatterns on CheckPasswordStrengthResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckPasswordStrengthResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckPasswordStrengthResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckPasswordStrengthResponse value)  $default,){
final _that = this;
switch (_that) {
case _CheckPasswordStrengthResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckPasswordStrengthResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CheckPasswordStrengthResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'isStrong')  bool isStrong, @JsonKey(name: 'message')  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckPasswordStrengthResponse() when $default != null:
return $default(_that.isStrong,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'isStrong')  bool isStrong, @JsonKey(name: 'message')  String message)  $default,) {final _that = this;
switch (_that) {
case _CheckPasswordStrengthResponse():
return $default(_that.isStrong,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'isStrong')  bool isStrong, @JsonKey(name: 'message')  String message)?  $default,) {final _that = this;
switch (_that) {
case _CheckPasswordStrengthResponse() when $default != null:
return $default(_that.isStrong,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckPasswordStrengthResponse implements CheckPasswordStrengthResponse {
  const _CheckPasswordStrengthResponse({@JsonKey(name: 'isStrong') required this.isStrong, @JsonKey(name: 'message') required this.message});
  factory _CheckPasswordStrengthResponse.fromJson(Map<String, dynamic> json) => _$CheckPasswordStrengthResponseFromJson(json);

@override@JsonKey(name: 'isStrong') final  bool isStrong;
@override@JsonKey(name: 'message') final  String message;

/// Create a copy of CheckPasswordStrengthResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckPasswordStrengthResponseCopyWith<_CheckPasswordStrengthResponse> get copyWith => __$CheckPasswordStrengthResponseCopyWithImpl<_CheckPasswordStrengthResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckPasswordStrengthResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckPasswordStrengthResponse&&(identical(other.isStrong, isStrong) || other.isStrong == isStrong)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isStrong,message);

@override
String toString() {
  return 'CheckPasswordStrengthResponse(isStrong: $isStrong, message: $message)';
}


}

/// @nodoc
abstract mixin class _$CheckPasswordStrengthResponseCopyWith<$Res> implements $CheckPasswordStrengthResponseCopyWith<$Res> {
  factory _$CheckPasswordStrengthResponseCopyWith(_CheckPasswordStrengthResponse value, $Res Function(_CheckPasswordStrengthResponse) _then) = __$CheckPasswordStrengthResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'isStrong') bool isStrong,@JsonKey(name: 'message') String message
});




}
/// @nodoc
class __$CheckPasswordStrengthResponseCopyWithImpl<$Res>
    implements _$CheckPasswordStrengthResponseCopyWith<$Res> {
  __$CheckPasswordStrengthResponseCopyWithImpl(this._self, this._then);

  final _CheckPasswordStrengthResponse _self;
  final $Res Function(_CheckPasswordStrengthResponse) _then;

/// Create a copy of CheckPasswordStrengthResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isStrong = null,Object? message = null,}) {
  return _then(_CheckPasswordStrengthResponse(
isStrong: null == isStrong ? _self.isStrong : isStrong // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
