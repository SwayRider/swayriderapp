import 'package:freezed_annotation/freezed_annotation.dart';

part 'reset_password_request.freezed.dart';
part 'reset_password_request.g.dart';

@freezed
sealed class ResetPasswordRequest with _$ResetPasswordRequest {
  const factory ResetPasswordRequest({
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'token') required String token,
    @JsonKey(name: 'new_password') required String newPassword,
  }) = _ResetPasswordRequest;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
}