import 'package:logging/logging.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class MfaVerifyViewModel {
  MfaVerifyViewModel({
    required AuthRepository authRepository,
    required String mfaToken,
  }) {
    _authRepository = authRepository;
    _mfaToken = mfaToken;
    verify = Command1<void, String>(_verify);
  }

  late final AuthRepository _authRepository;
  late final String _mfaToken;
  final _log = Logger('MfaVerifyViewModel');

  late final Command1<void, String> verify;

  bool get invalidCode => verify.result is Error;

  Future<Result<void>> _verify(String code) async {
    final result = await _authRepository.verifyMfa(
      mfaToken: _mfaToken,
      code: code,
    );
    if (result is Error<void>) {
      _log.warning('MFA verification failed! ${result.error}');
    }
    return result;
  }
}
