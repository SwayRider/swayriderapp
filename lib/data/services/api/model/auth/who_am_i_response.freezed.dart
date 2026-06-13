// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'who_am_i_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WhoAmIResponse {

@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'email') String get email;@JsonKey(name: 'is_verified') bool get isVerified;@JsonKey(name: 'is_admin') bool get isAdmin;@JsonKey(name: 'account_type') String get accountType;
/// Create a copy of WhoAmIResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WhoAmIResponseCopyWith<WhoAmIResponse> get copyWith => _$WhoAmIResponseCopyWithImpl<WhoAmIResponse>(this as WhoAmIResponse, _$identity);

  /// Serializes this WhoAmIResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WhoAmIResponse&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.email, email) || other.email == email)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.accountType, accountType) || other.accountType == accountType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,email,isVerified,isAdmin,accountType);

@override
String toString() {
  return 'WhoAmIResponse(userId: $userId, email: $email, isVerified: $isVerified, isAdmin: $isAdmin, accountType: $accountType)';
}


}

/// @nodoc
abstract mixin class $WhoAmIResponseCopyWith<$Res>  {
  factory $WhoAmIResponseCopyWith(WhoAmIResponse value, $Res Function(WhoAmIResponse) _then) = _$WhoAmIResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'email') String email,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'account_type') String accountType
});




}
/// @nodoc
class _$WhoAmIResponseCopyWithImpl<$Res>
    implements $WhoAmIResponseCopyWith<$Res> {
  _$WhoAmIResponseCopyWithImpl(this._self, this._then);

  final WhoAmIResponse _self;
  final $Res Function(WhoAmIResponse) _then;

/// Create a copy of WhoAmIResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? email = null,Object? isVerified = null,Object? isAdmin = null,Object? accountType = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WhoAmIResponse].
extension WhoAmIResponsePatterns on WhoAmIResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WhoAmIResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WhoAmIResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WhoAmIResponse value)  $default,){
final _that = this;
switch (_that) {
case _WhoAmIResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WhoAmIResponse value)?  $default,){
final _that = this;
switch (_that) {
case _WhoAmIResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'email')  String email, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'account_type')  String accountType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WhoAmIResponse() when $default != null:
return $default(_that.userId,_that.email,_that.isVerified,_that.isAdmin,_that.accountType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'email')  String email, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'account_type')  String accountType)  $default,) {final _that = this;
switch (_that) {
case _WhoAmIResponse():
return $default(_that.userId,_that.email,_that.isVerified,_that.isAdmin,_that.accountType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'email')  String email, @JsonKey(name: 'is_verified')  bool isVerified, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'account_type')  String accountType)?  $default,) {final _that = this;
switch (_that) {
case _WhoAmIResponse() when $default != null:
return $default(_that.userId,_that.email,_that.isVerified,_that.isAdmin,_that.accountType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WhoAmIResponse implements WhoAmIResponse {
  const _WhoAmIResponse({@JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'email') required this.email, @JsonKey(name: 'is_verified') required this.isVerified, @JsonKey(name: 'is_admin') required this.isAdmin, @JsonKey(name: 'account_type') required this.accountType});
  factory _WhoAmIResponse.fromJson(Map<String, dynamic> json) => _$WhoAmIResponseFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'email') final  String email;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey(name: 'is_admin') final  bool isAdmin;
@override@JsonKey(name: 'account_type') final  String accountType;

/// Create a copy of WhoAmIResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WhoAmIResponseCopyWith<_WhoAmIResponse> get copyWith => __$WhoAmIResponseCopyWithImpl<_WhoAmIResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WhoAmIResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WhoAmIResponse&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.email, email) || other.email == email)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.accountType, accountType) || other.accountType == accountType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,email,isVerified,isAdmin,accountType);

@override
String toString() {
  return 'WhoAmIResponse(userId: $userId, email: $email, isVerified: $isVerified, isAdmin: $isAdmin, accountType: $accountType)';
}


}

/// @nodoc
abstract mixin class _$WhoAmIResponseCopyWith<$Res> implements $WhoAmIResponseCopyWith<$Res> {
  factory _$WhoAmIResponseCopyWith(_WhoAmIResponse value, $Res Function(_WhoAmIResponse) _then) = __$WhoAmIResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'email') String email,@JsonKey(name: 'is_verified') bool isVerified,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'account_type') String accountType
});




}
/// @nodoc
class __$WhoAmIResponseCopyWithImpl<$Res>
    implements _$WhoAmIResponseCopyWith<$Res> {
  __$WhoAmIResponseCopyWithImpl(this._self, this._then);

  final _WhoAmIResponse _self;
  final $Res Function(_WhoAmIResponse) _then;

/// Create a copy of WhoAmIResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? email = null,Object? isVerified = null,Object? isAdmin = null,Object? accountType = null,}) {
  return _then(_WhoAmIResponse(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
