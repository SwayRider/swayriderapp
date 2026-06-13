import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_password_strength_request.freezed.dart';
part 'check_password_strength_request.g.dart';

@freezed
sealed class CheckPasswordStrengthRequest with _$CheckPasswordStrengthRequest {
  const factory CheckPasswordStrengthRequest({
    @JsonKey(name: 'password') required String password,
  }) = _CheckPasswordStrengthRequest;

  factory CheckPasswordStrengthRequest.fromJson(Map<String, dynamic> json) =>
    _$CheckPasswordStrengthRequestFromJson(json);
}