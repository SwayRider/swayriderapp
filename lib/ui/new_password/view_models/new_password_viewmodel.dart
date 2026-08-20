import 'package:logging/logging.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/services/api/auth_api_client.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class NewPasswordViewModel {
  NewPasswordViewModel({required AuthRepository authRepository})
    // ignore: prefer_initializing_formals
    : _authRepository = authRepository {
    resetPassword = Command1<void, (String, String, String)>(_resetPassword);
  }

  final AuthRepository _authRepository;
  final _log = Logger('NewPasswordViewModel');

  late Command1<void, (String, String, String)> resetPassword;

  /// Whether the most recent attempt failed because the backend rejected the
  /// new password as breached (appeared in a known data breach).
  bool get passwordBreached {
    final result = resetPassword.result;
    return result is Error && result.error is BreachedPasswordException;
  }

  /// Whether the most recent attempt failed because the backend rejected the
  /// new password as a reuse of a recently-used password.
  bool get passwordReused {
    final result = resetPassword.result;
    return result is Error && result.error is PasswordReusedException;
  }

  /// Checks the strength of [password] against the backend.
  Future<Result<bool>> checkPasswordStrength(String password) =>
      _authRepository.checkPasswordStrength(password: password);

  Future<Result<void>> _resetPassword((String, String, String) args) async {
    final (userId, token, newPassword) = args;
    final result = await _authRepository.resetPassword(
      userId: userId,
      token: token,
      newPassword: newPassword,
    );
    if (result is Error<void>) {
      _log.warning('Password reset failed! ${result.error}');
    }
    return result;
  }
}
