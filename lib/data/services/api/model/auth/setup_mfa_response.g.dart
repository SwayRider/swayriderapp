// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setup_mfa_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SetupMFAResponse _$SetupMFAResponseFromJson(Map<String, dynamic> json) =>
    _SetupMFAResponse(
      secret: json['secret'] as String,
      otpauthUrl: json['otpauth_url'] as String,
      qrPngBase64: json['qr_png_base64'] as String,
    );

Map<String, dynamic> _$SetupMFAResponseToJson(_SetupMFAResponse instance) =>
    <String, dynamic>{
      'secret': instance.secret,
      'otpauth_url': instance.otpauthUrl,
      'qr_png_base64': instance.qrPngBase64,
    };
