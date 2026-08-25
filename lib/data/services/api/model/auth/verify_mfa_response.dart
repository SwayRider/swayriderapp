import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_mfa_response.freezed.dart';
part 'verify_mfa_response.g.dart';

@freezed
sealed class VerifyMFAResponse with _$VerifyMFAResponse {
  const factory VerifyMFAResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _VerifyMFAResponse;

  factory VerifyMFAResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyMFAResponseFromJson(json);
}
