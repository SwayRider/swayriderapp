import 'package:flutter/foundation.dart';

import '../../../domain/models/user/user.dart';
import '../../../utils/result.dart';
import '../../services/api/auth_header_provider.dart';

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

  Future<Result<void>> login({
    required String email,
    required String password,
    bool rememberMe = false,
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

  Future<Result<bool>> checkPasswordStrength({
    required String password,
  });

  Future<Result<User>> me();

  Future<Result<User>> whoAmI();
}