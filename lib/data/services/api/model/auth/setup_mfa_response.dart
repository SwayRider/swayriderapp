import 'package:freezed_annotation/freezed_annotation.dart';

part 'setup_mfa_response.freezed.dart';
part 'setup_mfa_response.g.dart';

@freezed
sealed class SetupMFAResponse with _$SetupMFAResponse {
  const factory SetupMFAResponse({
    @JsonKey(name: 'secret') required String secret,
    @JsonKey(name: 'otpauth_url') required String otpauthUrl,
    @JsonKey(name: 'qr_png_base64') required String qrPngBase64,
  }) = _SetupMFAResponse;

  factory SetupMFAResponse.fromJson(Map<String, dynamic> json) =>
      _$SetupMFAResponseFromJson(json);
}
