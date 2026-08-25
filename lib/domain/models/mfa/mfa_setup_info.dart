/// Enrollment data shown during the two-factor authentication setup flow.
class MfaSetupInfo {
  const MfaSetupInfo({
    required this.secret,
    required this.otpauthUrl,
    required this.qrPngBase64,
  });

  /// Base32 secret key, grouped for display in the UI.
  final String secret;

  /// `otpauth://` URL for QR-code enrollment.
  final String otpauthUrl;

  /// Server-rendered QR code PNG, base64-encoded (decoded with `Image.memory`).
  final String qrPngBase64;
}
