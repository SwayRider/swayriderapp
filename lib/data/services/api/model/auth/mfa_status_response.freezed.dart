// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mfa_status_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MfaStatusResponse {

@JsonKey(name: 'enabled') bool get enabled;
/// Create a copy of MfaStatusResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MfaStatusResponseCopyWith<MfaStatusResponse> get copyWith => _$MfaStatusResponseCopyWithImpl<MfaStatusResponse>(this as MfaStatusResponse, _$identity);

  /// Serializes this MfaStatusResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MfaStatusResponse&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled);

@override
String toString() {
  return 'MfaStatusResponse(enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $MfaStatusResponseCopyWith<$Res>  {
  factory $MfaStatusResponseCopyWith(MfaStatusResponse value, $Res Function(MfaStatusResponse) _then) = _$MfaStatusResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'enabled') bool enabled
});




}
/// @nodoc
class _$MfaStatusResponseCopyWithImpl<$Res>
    implements $MfaStatusResponseCopyWith<$Res> {
  _$MfaStatusResponseCopyWithImpl(this._self, this._then);

  final MfaStatusResponse _self;
  final $Res Function(MfaStatusResponse) _then;

/// Create a copy of MfaStatusResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MfaStatusResponse].
extension MfaStatusResponsePatterns on MfaStatusResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MfaStatusResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MfaStatusResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MfaStatusResponse value)  $default,){
final _that = this;
switch (_that) {
case _MfaStatusResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MfaStatusResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MfaStatusResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'enabled')  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MfaStatusResponse() when $default != null:
return $default(_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'enabled')  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _MfaStatusResponse():
return $default(_that.enabled);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'enabled')  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _MfaStatusResponse() when $default != null:
return $default(_that.enabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MfaStatusResponse implements MfaStatusResponse {
  const _MfaStatusResponse({@JsonKey(name: 'enabled') required this.enabled});
  factory _MfaStatusResponse.fromJson(Map<String, dynamic> json) => _$MfaStatusResponseFromJson(json);

@override@JsonKey(name: 'enabled') final  bool enabled;

/// Create a copy of MfaStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MfaStatusResponseCopyWith<_MfaStatusResponse> get copyWith => __$MfaStatusResponseCopyWithImpl<_MfaStatusResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MfaStatusResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MfaStatusResponse&&(identical(other.enabled, enabled) || other.enabled == enabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled);

@override
String toString() {
  return 'MfaStatusResponse(enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$MfaStatusResponseCopyWith<$Res> implements $MfaStatusResponseCopyWith<$Res> {
  factory _$MfaStatusResponseCopyWith(_MfaStatusResponse value, $Res Function(_MfaStatusResponse) _then) = __$MfaStatusResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'enabled') bool enabled
});




}
/// @nodoc
class __$MfaStatusResponseCopyWithImpl<$Res>
    implements _$MfaStatusResponseCopyWith<$Res> {
  __$MfaStatusResponseCopyWithImpl(this._self, this._then);

  final _MfaStatusResponse _self;
  final $Res Function(_MfaStatusResponse) _then;

/// Create a copy of MfaStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,}) {
  return _then(_MfaStatusResponse(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
