import 'package:logging/logging.dart';

import '../../../config/app_config.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class ResetPasswordViewModel {
  ResetPasswordViewModel({required AuthRepository authRepository})
  // ignore: prefer_initializing_formals
  : _authRepository = authRepository {
    requestReset = Command1<void, String>(_requestReset);
  }

  final AuthRepository _authRepository;
  final _log = Logger('ResetPasswordViewModel');

  late Command1<void, String> requestReset;

  Future<Result<void>> _requestReset(String email) async {
    final result = await _authRepository.requestPasswordReset(
      email: email,
      verificationUrl: AppConfig.resetPasswordRedirectUrl,
    );
    if (result is Error<void>) {
      _log.warning('Password reset request failed! ${result.error}');
    }
    return result;
  }
}
