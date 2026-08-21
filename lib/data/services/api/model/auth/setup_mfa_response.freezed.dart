// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'setup_mfa_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SetupMFAResponse {

@JsonKey(name: 'secret') String get secret;@JsonKey(name: 'otpauth_url') String get otpauthUrl;@JsonKey(name: 'qr_png_base64') String get qrPngBase64;
/// Create a copy of SetupMFAResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetupMFAResponseCopyWith<SetupMFAResponse> get copyWith => _$SetupMFAResponseCopyWithImpl<SetupMFAResponse>(this as SetupMFAResponse, _$identity);

  /// Serializes this SetupMFAResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetupMFAResponse&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.otpauthUrl, otpauthUrl) || other.otpauthUrl == otpauthUrl)&&(identical(other.qrPngBase64, qrPngBase64) || other.qrPngBase64 == qrPngBase64));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,secret,otpauthUrl,qrPngBase64);

@override
String toString() {
  return 'SetupMFAResponse(secret: $secret, otpauthUrl: $otpauthUrl, qrPngBase64: $qrPngBase64)';
}


}

/// @nodoc
abstract mixin class $SetupMFAResponseCopyWith<$Res>  {
  factory $SetupMFAResponseCopyWith(SetupMFAResponse value, $Res Function(SetupMFAResponse) _then) = _$SetupMFAResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'secret') String secret,@JsonKey(name: 'otpauth_url') String otpauthUrl,@JsonKey(name: 'qr_png_base64') String qrPngBase64
});




}
/// @nodoc
class _$SetupMFAResponseCopyWithImpl<$Res>
    implements $SetupMFAResponseCopyWith<$Res> {
  _$SetupMFAResponseCopyWithImpl(this._self, this._then);

  final SetupMFAResponse _self;
  final $Res Function(SetupMFAResponse) _then;

/// Create a copy of SetupMFAResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? secret = null,Object? otpauthUrl = null,Object? qrPngBase64 = null,}) {
  return _then(_self.copyWith(
secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,otpauthUrl: null == otpauthUrl ? _self.otpauthUrl : otpauthUrl // ignore: cast_nullable_to_non_nullable
as String,qrPngBase64: null == qrPngBase64 ? _self.qrPngBase64 : qrPngBase64 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SetupMFAResponse].
extension SetupMFAResponsePatterns on SetupMFAResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetupMFAResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetupMFAResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetupMFAResponse value)  $default,){
final _that = this;
switch (_that) {
case _SetupMFAResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetupMFAResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SetupMFAResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'secret')  String secret, @JsonKey(name: 'otpauth_url')  String otpauthUrl, @JsonKey(name: 'qr_png_base64')  String qrPngBase64)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetupMFAResponse() when $default != null:
return $default(_that.secret,_that.otpauthUrl,_that.qrPngBase64);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'secret')  String secret, @JsonKey(name: 'otpauth_url')  String otpauthUrl, @JsonKey(name: 'qr_png_base64')  String qrPngBase64)  $default,) {final _that = this;
switch (_that) {
case _SetupMFAResponse():
return $default(_that.secret,_that.otpauthUrl,_that.qrPngBase64);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'secret')  String secret, @JsonKey(name: 'otpauth_url')  String otpauthUrl, @JsonKey(name: 'qr_png_base64')  String qrPngBase64)?  $default,) {final _that = this;
switch (_that) {
case _SetupMFAResponse() when $default != null:
return $default(_that.secret,_that.otpauthUrl,_that.qrPngBase64);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetupMFAResponse implements SetupMFAResponse {
  const _SetupMFAResponse({@JsonKey(name: 'secret') required this.secret, @JsonKey(name: 'otpauth_url') required this.otpauthUrl, @JsonKey(name: 'qr_png_base64') required this.qrPngBase64});
  factory _SetupMFAResponse.fromJson(Map<String, dynamic> json) => _$SetupMFAResponseFromJson(json);

@override@JsonKey(name: 'secret') final  String secret;
@override@JsonKey(name: 'otpauth_url') final  String otpauthUrl;
@override@JsonKey(name: 'qr_png_base64') final  String qrPngBase64;

/// Create a copy of SetupMFAResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetupMFAResponseCopyWith<_SetupMFAResponse> get copyWith => __$SetupMFAResponseCopyWithImpl<_SetupMFAResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetupMFAResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetupMFAResponse&&(identical(other.secret, secret) || other.secret == secret)&&(identical(other.otpauthUrl, otpauthUrl) || other.otpauthUrl == otpauthUrl)&&(identical(other.qrPngBase64, qrPngBase64) || other.qrPngBase64 == qrPngBase64));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,secret,otpauthUrl,qrPngBase64);

@override
String toString() {
  return 'SetupMFAResponse(secret: $secret, otpauthUrl: $otpauthUrl, qrPngBase64: $qrPngBase64)';
}


}

/// @nodoc
abstract mixin class _$SetupMFAResponseCopyWith<$Res> implements $SetupMFAResponseCopyWith<$Res> {
  factory _$SetupMFAResponseCopyWith(_SetupMFAResponse value, $Res Function(_SetupMFAResponse) _then) = __$SetupMFAResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'secret') String secret,@JsonKey(name: 'otpauth_url') String otpauthUrl,@JsonKey(name: 'qr_png_base64') String qrPngBase64
});




}
/// @nodoc
class __$SetupMFAResponseCopyWithImpl<$Res>
    implements _$SetupMFAResponseCopyWith<$Res> {
  __$SetupMFAResponseCopyWithImpl(this._self, this._then);

  final _SetupMFAResponse _self;
  final $Res Function(_SetupMFAResponse) _then;

/// Create a copy of SetupMFAResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? secret = null,Object? otpauthUrl = null,Object? qrPngBase64 = null,}) {
  return _then(_SetupMFAResponse(
secret: null == secret ? _self.secret : secret // ignore: cast_nullable_to_non_nullable
as String,otpauthUrl: null == otpauthUrl ? _self.otpauthUrl : otpauthUrl // ignore: cast_nullable_to_non_nullable
as String,qrPngBase64: null == qrPngBase64 ? _self.qrPngBase64 : qrPngBase64 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
