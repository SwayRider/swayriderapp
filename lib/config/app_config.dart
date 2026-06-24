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

  /// Tiles API connection settings.
  ///
  /// Defaults match the dev backend. Override at build/run time via
  /// `--dart-define=TILES_API_HOST=...` etc.
  static const tilesApiScheme =
      String.fromEnvironment('TILES_API_SCHEME', defaultValue: 'https');
  static const tilesApiHost = String.fromEnvironment(
    'TILES_API_HOST',
    defaultValue: 'api.swayrider-dev.hevanto-it.com',
  );
  static const tilesApiPort =
      int.fromEnvironment('TILES_API_PORT', defaultValue: 443);
  static const tilesApiPathPrefix = String.fromEnvironment(
    'TILES_API_PATH_PREFIX',
    defaultValue: '/v1/tiles',
  );

  /// Search API connection settings.
  ///
  /// Defaults match the dev backend. Override at build/run time via
  /// `--dart-define=SEARCH_API_HOST=...` etc.
  static const searchApiScheme =
      String.fromEnvironment('SEARCH_API_SCHEME', defaultValue: 'https');
  static const searchApiHost = String.fromEnvironment(
    'SEARCH_API_HOST',
    defaultValue: 'api.swayrider-dev.hevanto-it.com',
  );
  static const searchApiPort =
      int.fromEnvironment('SEARCH_API_PORT', defaultValue: 443);
  static const searchApiPathPrefix = String.fromEnvironment(
    'SEARCH_API_PATH_PREFIX',
    defaultValue: '/api/v1',
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

  /// URL the AuthService should redirect users to after they submit a new
  /// password via the reset-password link sent to their email.
  ///
  /// Empty by default — the AuthService falls back to its own default
  /// reset-password landing page. Override with
  /// `--dart-define=RESET_PASSWORD_REDIRECT_URL=...` at build/run time.
  static const resetPasswordRedirectUrl = String.fromEnvironment(
    'RESET_PASSWORD_REDIRECT_URL',
    defaultValue:
        'https://api.swayrider-dev.hevanto-it.com/web/reset-password',
  );

  /// URL of the SwayRider homepage, shown to users who try to sign up on an
  /// invitation-only backend without an invitation.
  ///
  /// Empty by default — the "Visit Homepage" link is hidden until a value is
  /// supplied. Override with `--dart-define=HOMEPAGE_URL=...` at build/run
  /// time.
  static const homepageUrl = String.fromEnvironment('HOMEPAGE_URL');

  /// When true, the access token loaded from `SharedPreferences` at startup
  /// is corrupted before use, forcing a 401 + refresh on the first
  /// authenticated call. Debug-only, for reproducing the auth-refresh flow
  /// on demand; never set in release builds.
  /// `--dart-define=FORCE_EXPIRED_ACCESS_TOKEN=true`
  static const forceExpiredAccessToken =
      bool.fromEnvironment('FORCE_EXPIRED_ACCESS_TOKEN');

  /// Like [forceExpiredAccessToken], but also corrupts the refresh token
  /// loaded from `SharedPreferences`, so the refresh call itself fails too
  /// (simulating a fully expired session). Debug-only.
  /// `--dart-define=FORCE_EXPIRED_REFRESH_TOKEN=true`
  static const forceExpiredRefreshToken =
      bool.fromEnvironment('FORCE_EXPIRED_REFRESH_TOKEN');
}
