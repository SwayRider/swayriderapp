import 'package:freezed_annotation/freezed_annotation.dart';

part 'mfa_status_response.freezed.dart';
part 'mfa_status_response.g.dart';

@freezed
sealed class MfaStatusResponse with _$MfaStatusResponse {
  const factory MfaStatusResponse({
    @JsonKey(name: 'enabled') required bool enabled,
  }) = _MfaStatusResponse;

  factory MfaStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$MfaStatusResponseFromJson(json);
}
