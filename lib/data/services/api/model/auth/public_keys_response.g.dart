// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_keys_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PublicKeysResponse _$PublicKeysResponseFromJson(Map<String, dynamic> json) =>
    _PublicKeysResponse(
      keys: (json['keys'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$PublicKeysResponseToJson(_PublicKeysResponse instance) =>
    <String, dynamic>{'keys': instance.keys};
