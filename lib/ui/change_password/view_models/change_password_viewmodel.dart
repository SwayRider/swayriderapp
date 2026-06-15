import 'package:logging/logging.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class ChangePasswordViewModel {
  ChangePasswordViewModel({required AuthRepository authRepository})
  // ignore: prefer_initializing_formals
  : _authRepository = authRepository {
    changePassword = Command1<void, (String, String)>(_changePassword);
  }

  final AuthRepository _authRepository;
  final _log = Logger('ChangePasswordViewModel');

  late Command1<void, (String, String)> changePassword;

  /// Checks the strength of [password] against the backend.
  Future<Result<bool>> checkPasswordStrength(String password) =>
      _authRepository.checkPasswordStrength(password: password);

  Future<Result<void>> _changePassword(
    (String, String) args,
  ) async {
    final (oldPassword, newPassword) = args;
    final result = await _authRepository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    if (result is Error<void>) {
      _log.warning('Change password failed! ${result.error}');
    }
    return result;
  }
}
