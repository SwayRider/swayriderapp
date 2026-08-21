// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_mfa_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerifyMFAResponse _$VerifyMFAResponseFromJson(Map<String, dynamic> json) =>
    _VerifyMFAResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$VerifyMFAResponseToJson(_VerifyMFAResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };
