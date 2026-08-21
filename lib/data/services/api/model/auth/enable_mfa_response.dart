import 'package:freezed_annotation/freezed_annotation.dart';

part 'enable_mfa_response.freezed.dart';
part 'enable_mfa_response.g.dart';

@freezed
sealed class EnableMFAResponse with _$EnableMFAResponse {
  const factory EnableMFAResponse({
    @JsonKey(name: 'backup_codes') required List<String> backupCodes,
  }) = _EnableMFAResponse;

  factory EnableMFAResponse.fromJson(Map<String, dynamic> json) =>
      _$EnableMFAResponseFromJson(json);
}
