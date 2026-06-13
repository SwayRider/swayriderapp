import 'package:freezed_annotation/freezed_annotation.dart';

part 'refresh_request.freezed.dart';
part 'refresh_request.g.dart';

@freezed
sealed class RefreshRequest with _$RefreshRequest {
  factory RefreshRequest({
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'remember_me') @Default(false) bool rememberMe
  }) = _RefreshRequest;

  factory RefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestFromJson(json);
}