import 'package:logging/logging.dart';

import '../../../domain/models/user/user.dart';
import '../../../utils/result.dart';
import '../../services/api/auth_api_client.dart';
import '../../services/api/auth_header_provider.dart';
import '../../services/api/model/auth/auth.dart';
import '../../services/shared_preferences_service.dart';
import 'auth_repository.dart';

class AuthRepositoryRemote extends AuthRepository {
  AuthRepositoryRemote({
    required this._authApiClient,
    required this._sharedPreferencesService,
  }) {
    _authApiClient.authHeaderProvider = _authHeaderProvider;
  }

  final AuthApiClient _authApiClient;
  final SharedPreferencesService _sharedPreferencesService;
  final _log = Logger('AuthRepositoryRemote');

  String? _accessToken;
  String? _refreshToken;
  bool? _cachedIsVerified;
  bool? _cachedIsAdmin;

  @override
  AuthHeaderProvider get authHeaderProvider => _authHeaderProvider;

  @override
  Future<bool> get isAuthenticated async {
    if (_accessToken != null) return true;
    final result = await _sharedPreferencesService.fetchAccessToken();
    if (result case Ok(:final value) when value != null) {
      _accessToken = value;
      return true;
    }
    return false;
  }

  @override
  Future<bool> get isVerified async {
    if (_cachedIsVerified != null) return _cachedIsVerified!;
    final result = await me();
    return switch (result) {
      Ok(:final value) => _cachedIsVerified = value.isVerified,
      Error() => false,
    };
  }

  @override
  Future<bool> get isAdmin async {
    if (_cachedIsAdmin != null) return _cachedIsAdmin!;
    final result = await whoAmI();
    return switch (result) {
      Ok(:final value) => _cachedIsAdmin = value.isAdmin ?? false,
      Error() => false,
    };
  }

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _log.fine('Logging in as $email');
    final result = await _authApiClient.login(LoginRequest(
      email: email,
      password: password,
      rememberMe: rememberMe,
    ));
    if (result case Ok(:final value)) {
      await _saveTokens(value.accessToken, value.refreshToken);
      notifyListeners();
      return const Result.ok(null);
    }
    return Result.error((result as Error<LoginResponse>).error);
  }

  @override
  Future<Result<void>> refresh() async {
    if (_refreshToken == null) {
      final stored = await _sharedPreferencesService.fetchRefreshToken();
      if (stored case Ok(:final value)) {
        _refreshToken = value;
      }
    }
    if (_refreshToken == null) {
      return Result.error(Exception('No refresh token available'));
    }
    _log.fine('Refreshing tokens');
    final result = await _authApiClient
        .refresh(RefreshRequest(refreshToken: _refreshToken!));
    return switch (result) {
      Ok(:final value) => _saveTokens(value.accessToken, value.refreshToken),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> logout() async {
    _log.fine('Logging out');
    final result =
        await _authApiClient.logout(LogoutRequest(refreshToken: _refreshToken));
    await _clearTokens();
    notifyListeners();
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> register({
    required String email,
    required String password,
    required String verificationUrl,
  }) async {
    _log.fine('Registering $email');
    final result = await _authApiClient.register(RegisterRequest(
      email: email,
      password: password,
      verificationUrl: verificationUrl,
    ));
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> requestPasswordReset({
    required String email,
    required String verificationUrl,
  }) async {
    _log.fine('Requesting password reset for $email');
    final result = await _authApiClient.requestPasswordReset(
        PasswordResetRequest(email: email, resetUrl: verificationUrl));
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> resetPassword({
    required String userId,
    required String token,
    required String newPassword,
  }) async {
    _log.fine('Resetting password for user $userId');
    final result = await _authApiClient.resetPassword(ResetPasswordRequest(
      userId: userId,
      token: token,
      newPassword: newPassword,
    ));
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> verifyEmail({
    required String email,
    required String verificationUrl,
  }) async {
    _log.fine('Verifying email for $email');
    final result = await _authApiClient.verifyEmail(
        VerifyEmailRequest(email: email, verificationUrl: verificationUrl));
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _log.fine('Changing password');
    final result = await _authApiClient.changePassword(
        ChangePasswordRequest(oldPassword: oldPassword, newPassword: newPassword));
    return switch (result) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<bool>> checkPasswordStrength({required String password}) async {
    final result = await _authApiClient
        .checkPasswordStrength(CheckPasswordStrengthRequest(password: password));
    return switch (result) {
      Ok(:final value) => Result.ok(value.isStrong),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<User>> me() => _withAuthRetry(_meOnce);

  Future<Result<User>> _meOnce() async {
    final result = await _authApiClient.me();
    return switch (result) {
      Ok(:final value) => Result.ok(User(
          id: value.userId,
          email: value.email ?? '',
          isVerified: value.emailVerified,
        )),
      Error(:final error) => Result.error(error),
    };
  }

  @override
  Future<Result<User>> whoAmI() => _withAuthRetry(_whoAmIOnce);

  Future<Result<User>> _whoAmIOnce() async {
    final result = await _authApiClient.whoAmI();
    return switch (result) {
      Ok(:final value) => Result.ok(User(
          id: value.userId,
          email: value.email,
          isVerified: value.isVerified,
          isAdmin: value.isAdmin,
          accountType: value.accountType,
        )),
      Error(:final error) => Result.error(error),
    };
  }

  /// Runs [call], and if it fails with [UnauthorizedException] (the access
  /// token is expired or invalid), attempts [refresh] and retries [call]
  /// once. If the refresh itself fails, the stored tokens are cleared so
  /// [isAuthenticated] becomes false and the router redirects to login
  /// instead of getting stuck on the verify-email screen.
  Future<Result<T>> _withAuthRetry<T>(
    Future<Result<T>> Function() call,
  ) async {
    final result = await call();
    if (result case Error(error: UnauthorizedException())) {
      _log.fine('Access token rejected, attempting refresh');
      final refreshResult = await refresh();
      if (refreshResult is Error<void>) {
        await _clearTokens();
        return result;
      }
      return call();
    }
    return result;
  }

  Future<Result<void>> _saveTokens(
      String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _sharedPreferencesService.saveAccessToken(accessToken);
    await _sharedPreferencesService.saveRefreshToken(refreshToken);
    return const Result.ok(null);
  }

  Future<void> _clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _cachedIsVerified = null;
    _cachedIsAdmin = null;
    await _sharedPreferencesService.saveAccessToken(null);
    await _sharedPreferencesService.saveRefreshToken(null);
  }

  String? _authHeaderProvider() =>
    _accessToken != null ? 'Bearer $_accessToken' : null;
}
