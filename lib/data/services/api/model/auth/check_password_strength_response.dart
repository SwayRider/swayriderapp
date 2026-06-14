import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_password_strength_response.freezed.dart';
part 'check_password_strength_response.g.dart';

@freezed
sealed class CheckPasswordStrengthResponse with _$CheckPasswordStrengthResponse {
  const factory CheckPasswordStrengthResponse({
    @JsonKey(name: 'is_strong') required bool isStrong,
    @JsonKey(name: 'message') required String message,
  }) = _CheckPasswordStrengthResponse;
  factory CheckPasswordStrengthResponse.fromJson(Map<String, Object?> json) =>
      _$CheckPasswordStrengthResponseFromJson(json);
}