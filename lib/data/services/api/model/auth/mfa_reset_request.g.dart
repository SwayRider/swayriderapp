// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mfa_reset_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MfaResetRequest _$MfaResetRequestFromJson(Map<String, dynamic> json) =>
    _MfaResetRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      backupCode: json['backup_code'] as String,
      mfaResetUrl: json['mfa_reset_url'] as String,
    );

Map<String, dynamic> _$MfaResetRequestToJson(_MfaResetRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'backup_code': instance.backupCode,
      'mfa_reset_url': instance.mfaResetUrl,
    };
