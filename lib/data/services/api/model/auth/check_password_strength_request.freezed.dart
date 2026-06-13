// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'check_password_strength_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CheckPasswordStrengthRequest {

@JsonKey(name: 'password') String get password;
/// Create a copy of CheckPasswordStrengthRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckPasswordStrengthRequestCopyWith<CheckPasswordStrengthRequest> get copyWith => _$CheckPasswordStrengthRequestCopyWithImpl<CheckPasswordStrengthRequest>(this as CheckPasswordStrengthRequest, _$identity);

  /// Serializes this CheckPasswordStrengthRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckPasswordStrengthRequest&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,password);

@override
String toString() {
  return 'CheckPasswordStrengthRequest(password: $password)';
}


}

/// @nodoc
abstract mixin class $CheckPasswordStrengthRequestCopyWith<$Res>  {
  factory $CheckPasswordStrengthRequestCopyWith(CheckPasswordStrengthRequest value, $Res Function(CheckPasswordStrengthRequest) _then) = _$CheckPasswordStrengthRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'password') String password
});




}
/// @nodoc
class _$CheckPasswordStrengthRequestCopyWithImpl<$Res>
    implements $CheckPasswordStrengthRequestCopyWith<$Res> {
  _$CheckPasswordStrengthRequestCopyWithImpl(this._self, this._then);

  final CheckPasswordStrengthRequest _self;
  final $Res Function(CheckPasswordStrengthRequest) _then;

/// Create a copy of CheckPasswordStrengthRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? password = null,}) {
  return _then(_self.copyWith(
password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckPasswordStrengthRequest].
extension CheckPasswordStrengthRequestPatterns on CheckPasswordStrengthRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckPasswordStrengthRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckPasswordStrengthRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckPasswordStrengthRequest value)  $default,){
final _that = this;
switch (_that) {
case _CheckPasswordStrengthRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckPasswordStrengthRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CheckPasswordStrengthRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'password')  String password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckPasswordStrengthRequest() when $default != null:
return $default(_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'password')  String password)  $default,) {final _that = this;
switch (_that) {
case _CheckPasswordStrengthRequest():
return $default(_that.password);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'password')  String password)?  $default,) {final _that = this;
switch (_that) {
case _CheckPasswordStrengthRequest() when $default != null:
return $default(_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckPasswordStrengthRequest implements CheckPasswordStrengthRequest {
  const _CheckPasswordStrengthRequest({@JsonKey(name: 'password') required this.password});
  factory _CheckPasswordStrengthRequest.fromJson(Map<String, dynamic> json) => _$CheckPasswordStrengthRequestFromJson(json);

@override@JsonKey(name: 'password') final  String password;

/// Create a copy of CheckPasswordStrengthRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckPasswordStrengthRequestCopyWith<_CheckPasswordStrengthRequest> get copyWith => __$CheckPasswordStrengthRequestCopyWithImpl<_CheckPasswordStrengthRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckPasswordStrengthRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckPasswordStrengthRequest&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,password);

@override
String toString() {
  return 'CheckPasswordStrengthRequest(password: $password)';
}


}

/// @nodoc
abstract mixin class _$CheckPasswordStrengthRequestCopyWith<$Res> implements $CheckPasswordStrengthRequestCopyWith<$Res> {
  factory _$CheckPasswordStrengthRequestCopyWith(_CheckPasswordStrengthRequest value, $Res Function(_CheckPasswordStrengthRequest) _then) = __$CheckPasswordStrengthRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'password') String password
});




}
/// @nodoc
class __$CheckPasswordStrengthRequestCopyWithImpl<$Res>
    implements _$CheckPasswordStrengthRequestCopyWith<$Res> {
  __$CheckPasswordStrengthRequestCopyWithImpl(this._self, this._then);

  final _CheckPasswordStrengthRequest _self;
  final $Res Function(_CheckPasswordStrengthRequest) _then;

/// Create a copy of CheckPasswordStrengthRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? password = null,}) {
  return _then(_CheckPasswordStrengthRequest(
password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
