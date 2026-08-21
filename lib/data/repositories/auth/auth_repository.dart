import 'package:flutter/foundation.dart';

import '../../../domain/models/mfa/mfa_setup_info.dart';
import '../../../domain/models/user/user.dart';
import '../../../utils/result.dart';
import '../../services/api/auth_header_provider.dart';
import '../../services/api/unauthorized_exception.dart';

/// The outcome of a [AuthRepository.login] attempt.
sealed class LoginOutcome {
  const LoginOutcome();
}

/// Login succeeded and the session is fully established (tokens saved).
class LoginSuccess extends LoginOutcome {
  const LoginSuccess();
}

/// Login succeeded past the password check, but a second factor must be
/// completed first. No tokens were saved yet; the pending challenge is
/// identified by [mfaToken].
class LoginMfaRequired extends LoginOutcome {
  const LoginMfaRequired(this.mfaToken);

  final String mfaToken;
}

abstract class AuthRepository extends ChangeNotifier {
  Future<bool> get isAuthenticated;
  Future<bool> get isVerified;
  Future<bool> get isAdmin;

  /// Returns the current `Authorization` header value (e.g.
  /// `'Bearer <token>'`), or `null` if not authenticated.
  ///
  /// Lets other repositories reuse the same bearer-token source without
  /// depending on [AuthRepository] internals.
  AuthHeaderProvider get authHeaderProvider;

  Future<Result<LoginOutcome>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  /// Completes a pending MFA login challenge ([mfaToken] comes from a
  /// [LoginMfaRequired] outcome) with a TOTP or backup code. Saves the
  /// session tokens on success.
  Future<Result<void>> verifyMfa({
    required String mfaToken,
    required String code,
  });

  Future<Result<MfaSetupInfo>> setupMfa();

  /// Enables MFA with the given TOTP [code] and returns the one-time
  /// backup codes.
  Future<Result<List<String>>> enableMfa({required String code});

  Future<Result<void>> disableMfa({required String password});

  Future<Result<bool>> getMfaStatus();

  /// Invalidates the current backup codes and issues fresh ones.
  Future<Result<List<String>>> generateBackupCodes({
    required String password,
  });

  Future<Result<void>> refresh();

  Future<Result<void>> logout();

  Future<Result<void>> register({
    required String email,
    required String password,
    required String verificationUrl,
  });

  Future<Result<void>> requestPasswordReset({
    required String email,
    required String verificationUrl,
  });

  Future<Result<void>> resetPassword({
    required String userId,
    required String token,
    required String newPassword,
  });

  Future<Result<void>> verifyEmail({
    required String email,
    required String verificationUrl,
  });

  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<Result<bool>> checkPasswordStrength({required String password});

  Future<Result<User>> me();

  Future<Result<User>> whoAmI();

  /// Runs [call], and if it fails with [UnauthorizedException] (the access
  /// token is expired or invalid), attempts a token refresh and retries
  /// [call] once.
  ///
  /// Lets other repositories (e.g. tiles, search) reuse the same
  /// expiry-recovery logic as [me]/[whoAmI] for their own authenticated
  /// calls.
  Future<Result<T>> withAuthRetry<T>(Future<Result<T>> Function() call);
}
