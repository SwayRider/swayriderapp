import 'package:freezed_annotation/freezed_annotation.dart';

part 'mfa_reset_request.freezed.dart';
part 'mfa_reset_request.g.dart';

@freezed
sealed class MfaResetRequest with _$MfaResetRequest {
  const factory MfaResetRequest({
    @JsonKey(name: 'email') required String email,
    @JsonKey(name: 'password') required String password,
    @JsonKey(name: 'backup_code') required String backupCode,
    @JsonKey(name: 'mfa_reset_url') required String mfaResetUrl,
  }) = _MfaResetRequest;

  factory MfaResetRequest.fromJson(Map<String, dynamic> json) =>
      _$MfaResetRequestFromJson(json);
}
