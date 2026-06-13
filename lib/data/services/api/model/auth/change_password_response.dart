import 'package:freezed_annotation/freezed_annotation.dart';

part 'change_password_response.freezed.dart';
part 'change_password_response.g.dart';

@freezed
sealed class ChangePasswordResponse with _$ChangePasswordResponse {
  const factory ChangePasswordResponse({
    @JsonKey(name: 'message') required String message,
  }) = _ChangePasswordResponse;

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordResponseFromJson(json);
}