// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'who_am_i_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WhoAmIResponse _$WhoAmIResponseFromJson(Map<String, dynamic> json) =>
    _WhoAmIResponse(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      isVerified: json['is_verified'] as bool,
      isAdmin: json['is_admin'] as bool,
      accountType: json['account_type'] as String,
    );

Map<String, dynamic> _$WhoAmIResponseToJson(_WhoAmIResponse instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'email': instance.email,
      'is_verified': instance.isVerified,
      'is_admin': instance.isAdmin,
      'account_type': instance.accountType,
    };
