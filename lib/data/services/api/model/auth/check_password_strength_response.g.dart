// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_password_strength_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckPasswordStrengthResponse _$CheckPasswordStrengthResponseFromJson(
  Map<String, dynamic> json,
) => _CheckPasswordStrengthResponse(
  isStrong: json['isStrong'] as bool,
  message: json['message'] as String,
);

Map<String, dynamic> _$CheckPasswordStrengthResponseToJson(
  _CheckPasswordStrengthResponse instance,
) => <String, dynamic>{
  'isStrong': instance.isStrong,
  'message': instance.message,
};
