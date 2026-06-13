// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RefreshRequest _$RefreshRequestFromJson(Map<String, dynamic> json) =>
    _RefreshRequest(
      refreshToken: json['refresh_token'] as String,
      rememberMe: json['remember_me'] as bool? ?? false,
    );

Map<String, dynamic> _$RefreshRequestToJson(_RefreshRequest instance) =>
    <String, dynamic>{
      'refresh_token': instance.refreshToken,
      'remember_me': instance.rememberMe,
    };
