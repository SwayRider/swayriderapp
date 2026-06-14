/// Build-time application configuration.
///
/// Values are provided via `--dart-define=KEY=VALUE` at build/run time.
abstract final class AppConfig {
  /// Auth API connection settings.
  ///
  /// Defaults match the dev backend. Override at build/run time via
  /// `--dart-define=AUTH_API_HOST=...` etc.
  static const authApiScheme =
      String.fromEnvironment('AUTH_API_SCHEME', defaultValue: 'https');
  static const authApiHost = String.fromEnvironment(
    'AUTH_API_HOST',
    defaultValue: 'api.swayrider-dev.hevanto-it.com',
  );
  static const authApiPort =
      int.fromEnvironment('AUTH_API_PORT', defaultValue: 443);
  static const authApiPathPrefix = String.fromEnvironment(
    'AUTH_API_PATH_PREFIX',
    defaultValue: '/api/v1/auth',
  );

  /// URL the AuthService should redirect users to after they confirm their
  /// email address via the verification link sent during signup.
  ///
  /// Empty by default — the AuthService falls back to its own default
  /// verification landing page. Override with
  /// `--dart-define=VERIFICATION_REDIRECT_URL=...` at build/run time.
  static const verificationRedirectUrl = String.fromEnvironment(
    'VERIFICATION_REDIRECT_URL',
    defaultValue: 'https://api.swayrider-dev.hevanto-it.com/web/verify-user',
  );

  /// URL of the SwayRider homepage, shown to users who try to sign up on an
  /// invitation-only backend without an invitation.
  ///
  /// Empty by default — the "Visit Homepage" link is hidden until a value is
  /// supplied. Override with `--dart-define=HOMEPAGE_URL=...` at build/run
  /// time.
  static const homepageUrl = String.fromEnvironment('HOMEPAGE_URL');
}
