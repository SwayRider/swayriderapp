import 'package:freezed_annotation/freezed_annotation.dart';

part 'logout_request.freezed.dart';
part 'logout_request.g.dart';

@freezed
sealed class LogoutRequest with _$LogoutRequest {
  const factory LogoutRequest({
    @JsonKey(name: 'refresh_token') String? refreshToken,
  }) = _LogoutRequest;

  factory LogoutRequest.fromJson(Map<String, dynamic> json) =>
      _$LogoutRequestFromJson(json);
}