// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_password_strength_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckPasswordStrengthResponse _$CheckPasswordStrengthResponseFromJson(
  Map<String, dynamic> json,
) => _CheckPasswordStrengthResponse(
  isStrong: json['is_strong'] as bool,
  message: json['message'] as String,
);

Map<String, dynamic> _$CheckPasswordStrengthResponseToJson(
  _CheckPasswordStrengthResponse instance,
) => <String, dynamic>{
  'is_strong': instance.isStrong,
  'message': instance.message,
};
