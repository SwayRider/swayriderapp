import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_reset_request.freezed.dart';
part 'password_reset_request.g.dart';

@freezed
sealed class PasswordResetRequest with _$PasswordResetRequest {
  const factory PasswordResetRequest({
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'reset_url') required String resetUrl,
  }) = _PasswordResetRequest;

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetRequestFromJson(json);
}