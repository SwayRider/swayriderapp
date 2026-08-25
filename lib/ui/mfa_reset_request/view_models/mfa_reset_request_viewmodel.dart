import 'package:logging/logging.dart';

import '../../../config/app_config.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class MfaResetRequestViewModel {
  MfaResetRequestViewModel({required AuthRepository authRepository})
    // ignore: prefer_initializing_formals
    : _authRepository = authRepository {
    requestReset =
        Command1<void, (String email, String password, String backupCode)>(
          _requestReset,
        );
  }

  final AuthRepository _authRepository;
  final _log = Logger('MfaResetRequestViewModel');

  late final Command1<void, (String email, String password, String backupCode)>
  requestReset;

  Future<Result<void>> _requestReset(
    (String, String, String) credentials,
  ) async {
    final (email, password, backupCode) = credentials;
    final result = await _authRepository.requestMfaReset(
      email: email,
      password: password,
      backupCode: backupCode,
      mfaResetUrl: AppConfig.mfaResetRedirectUrl,
    );
    if (result is Error<void>) {
      _log.warning('MFA reset request failed! ${result.error}');
    }
    return result;
  }
}
