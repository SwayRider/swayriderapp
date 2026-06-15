import 'package:logging/logging.dart';

import '../../../config/app_config.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class VerifyEmailViewModel {
  VerifyEmailViewModel({required AuthRepository authRepository, String? email})
  // ignore: prefer_initializing_formals
  : _authRepository = authRepository,
    // ignore: prefer_initializing_formals
    _email = email {
    resendVerification = Command0<void>(_resendVerification);
    logout = Command0<void>(_logout);
  }

  final AuthRepository _authRepository;
  final _log = Logger('VerifyEmailViewModel');

  String? _email;

  late Command0<void> resendVerification;
  late Command0<void> logout;

  Future<Result<void>> _resendVerification() async {
    var email = _email;
    if (email == null) {
      final result = await _authRepository.me();
      switch (result) {
        case Ok(:final value):
          email = value.email;
          _email = email;
        case Error(:final error):
          _log.warning('Failed to fetch current user email! $error');
          return Result.error(error);
      }
    }

    final result = await _authRepository.verifyEmail(
      email: email,
      verificationUrl: AppConfig.verificationRedirectUrl,
    );
    if (result is Error<void>) {
      _log.warning('Resend verification email failed! ${result.error}');
    }
    return result;
  }

  Future<Result<void>> _logout() async {
    final result = await _authRepository.logout();
    if (result is Error<void>) {
      _log.warning('Logout failed! ${result.error}');
    }
    return result;
  }
}
