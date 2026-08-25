// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mfa_reset_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MfaResetRequest {

@JsonKey(name: 'email') String get email;@JsonKey(name: 'password') String get password;@JsonKey(name: 'backup_code') String get backupCode;@JsonKey(name: 'mfa_reset_url') String get mfaResetUrl;
/// Create a copy of MfaResetRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MfaResetRequestCopyWith<MfaResetRequest> get copyWith => _$MfaResetRequestCopyWithImpl<MfaResetRequest>(this as MfaResetRequest, _$identity);

  /// Serializes this MfaResetRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MfaResetRequest&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.backupCode, backupCode) || other.backupCode == backupCode)&&(identical(other.mfaResetUrl, mfaResetUrl) || other.mfaResetUrl == mfaResetUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,backupCode,mfaResetUrl);

@override
String toString() {
  return 'MfaResetRequest(email: $email, password: $password, backupCode: $backupCode, mfaResetUrl: $mfaResetUrl)';
}


}

/// @nodoc
abstract mixin class $MfaResetRequestCopyWith<$Res>  {
  factory $MfaResetRequestCopyWith(MfaResetRequest value, $Res Function(MfaResetRequest) _then) = _$MfaResetRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'email') String email,@JsonKey(name: 'password') String password,@JsonKey(name: 'backup_code') String backupCode,@JsonKey(name: 'mfa_reset_url') String mfaResetUrl
});




}
/// @nodoc
class _$MfaResetRequestCopyWithImpl<$Res>
    implements $MfaResetRequestCopyWith<$Res> {
  _$MfaResetRequestCopyWithImpl(this._self, this._then);

  final MfaResetRequest _self;
  final $Res Function(MfaResetRequest) _then;

/// Create a copy of MfaResetRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,Object? password = null,Object? backupCode = null,Object? mfaResetUrl = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,backupCode: null == backupCode ? _self.backupCode : backupCode // ignore: cast_nullable_to_non_nullable
as String,mfaResetUrl: null == mfaResetUrl ? _self.mfaResetUrl : mfaResetUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MfaResetRequest].
extension MfaResetRequestPatterns on MfaResetRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MfaResetRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MfaResetRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MfaResetRequest value)  $default,){
final _that = this;
switch (_that) {
case _MfaResetRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MfaResetRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MfaResetRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'email')  String email, @JsonKey(name: 'password')  String password, @JsonKey(name: 'backup_code')  String backupCode, @JsonKey(name: 'mfa_reset_url')  String mfaResetUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MfaResetRequest() when $default != null:
return $default(_that.email,_that.password,_that.backupCode,_that.mfaResetUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'email')  String email, @JsonKey(name: 'password')  String password, @JsonKey(name: 'backup_code')  String backupCode, @JsonKey(name: 'mfa_reset_url')  String mfaResetUrl)  $default,) {final _that = this;
switch (_that) {
case _MfaResetRequest():
return $default(_that.email,_that.password,_that.backupCode,_that.mfaResetUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'email')  String email, @JsonKey(name: 'password')  String password, @JsonKey(name: 'backup_code')  String backupCode, @JsonKey(name: 'mfa_reset_url')  String mfaResetUrl)?  $default,) {final _that = this;
switch (_that) {
case _MfaResetRequest() when $default != null:
return $default(_that.email,_that.password,_that.backupCode,_that.mfaResetUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MfaResetRequest implements MfaResetRequest {
  const _MfaResetRequest({@JsonKey(name: 'email') required this.email, @JsonKey(name: 'password') required this.password, @JsonKey(name: 'backup_code') required this.backupCode, @JsonKey(name: 'mfa_reset_url') required this.mfaResetUrl});
  factory _MfaResetRequest.fromJson(Map<String, dynamic> json) => _$MfaResetRequestFromJson(json);

@override@JsonKey(name: 'email') final  String email;
@override@JsonKey(name: 'password') final  String password;
@override@JsonKey(name: 'backup_code') final  String backupCode;
@override@JsonKey(name: 'mfa_reset_url') final  String mfaResetUrl;

/// Create a copy of MfaResetRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MfaResetRequestCopyWith<_MfaResetRequest> get copyWith => __$MfaResetRequestCopyWithImpl<_MfaResetRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MfaResetRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MfaResetRequest&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.backupCode, backupCode) || other.backupCode == backupCode)&&(identical(other.mfaResetUrl, mfaResetUrl) || other.mfaResetUrl == mfaResetUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,email,password,backupCode,mfaResetUrl);

@override
String toString() {
  return 'MfaResetRequest(email: $email, password: $password, backupCode: $backupCode, mfaResetUrl: $mfaResetUrl)';
}


}

/// @nodoc
abstract mixin class _$MfaResetRequestCopyWith<$Res> implements $MfaResetRequestCopyWith<$Res> {
  factory _$MfaResetRequestCopyWith(_MfaResetRequest value, $Res Function(_MfaResetRequest) _then) = __$MfaResetRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'email') String email,@JsonKey(name: 'password') String password,@JsonKey(name: 'backup_code') String backupCode,@JsonKey(name: 'mfa_reset_url') String mfaResetUrl
});




}
/// @nodoc
class __$MfaResetRequestCopyWithImpl<$Res>
    implements _$MfaResetRequestCopyWith<$Res> {
  __$MfaResetRequestCopyWithImpl(this._self, this._then);

  final _MfaResetRequest _self;
  final $Res Function(_MfaResetRequest) _then;

/// Create a copy of MfaResetRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,Object? password = null,Object? backupCode = null,Object? mfaResetUrl = null,}) {
  return _then(_MfaResetRequest(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,backupCode: null == backupCode ? _self.backupCode : backupCode // ignore: cast_nullable_to_non_nullable
as String,mfaResetUrl: null == mfaResetUrl ? _self.mfaResetUrl : mfaResetUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
