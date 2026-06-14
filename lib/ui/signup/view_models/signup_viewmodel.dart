import 'package:logging/logging.dart';

import '../../../config/app_config.dart';
import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/services/api/auth_api_client.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class SignupViewModel {
  SignupViewModel({required AuthRepository authRepository})
  // ignore: prefer_initializing_formals
  : _authRepository = authRepository {
    signup = Command1<void, (String email, String password)>(_signup);
  }

  final AuthRepository _authRepository;
  final _log = Logger('SignupViewModel');

  late Command1 signup;

  /// Whether the most recent signup attempt failed because the backend is
  /// invitation-only and the given email has no invitation.
  bool get invitationRequired {
    final result = signup.result;
    return result is Error && result.error is InvitationRequiredException;
  }

  /// Whether the most recent signup attempt failed because the backend
  /// rejected the password as too weak.
  bool get passwordTooWeak {
    final result = signup.result;
    return result is Error && result.error is WeakPasswordException;
  }

  /// Checks the strength of [password] against the backend.
  Future<Result<bool>> checkPasswordStrength(String password) =>
      _authRepository.checkPasswordStrength(password: password);

  Future<Result<void>> _signup((String, String) credentials) async {
    final (email, password) = credentials;
    final result = await _authRepository.register(
      email: email,
      password: password,
      verificationUrl: AppConfig.verificationRedirectUrl,
    );
    if (result is Error<void>) {
      _log.warning('Signup failed! ${result.error}');
    }
    return result;
  }
}
