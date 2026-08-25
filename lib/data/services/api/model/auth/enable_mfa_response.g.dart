// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enable_mfa_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EnableMFAResponse _$EnableMFAResponseFromJson(Map<String, dynamic> json) =>
    _EnableMFAResponse(
      backupCodes: (json['backup_codes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$EnableMFAResponseToJson(_EnableMFAResponse instance) =>
    <String, dynamic>{'backup_codes': instance.backupCodes};
