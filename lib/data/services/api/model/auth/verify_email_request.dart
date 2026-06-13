import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_email_request.freezed.dart';
part 'verify_email_request.g.dart';

@freezed
sealed class VerifyEmailRequest with _$VerifyEmailRequest {
  const factory VerifyEmailRequest({
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'verification_url') required String verificationUrl,
  }) = _VerifyEmailRequest;

  factory VerifyEmailRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyEmailRequestFromJson(json);
}