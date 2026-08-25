import 'package:logging/logging.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class LoginViewModel {
  LoginViewModel({required AuthRepository authRepository})
    // ignore: prefer_initializing_formals
    : _authRepository = authRepository {
    login = Command1<LoginOutcome, (String email, String password)>(_login);
    verifyMfa = Command1<void, (String mfaToken, String code)>(_verifyMfa);
  }

  final AuthRepository _authRepository;
  final _log = Logger('LoginViewModel');

  late Command1<LoginOutcome, (String email, String password)> login;

  /// Second-factor completion (the verify screen drives this).
  late final Command1<void, (String mfaToken, String code)> verifyMfa;

  LoginOutcome? get loginOutcome {
    final result = login.result;
    if (result case Ok(:final value)) return value;
    return null;
  }

  bool get mfaRequired => loginOutcome is LoginMfaRequired;

  String? get mfaToken {
    final outcome = loginOutcome;
    if (outcome case LoginMfaRequired(:final mfaToken)) return mfaToken;
    return null;
  }

  Future<Result<LoginOutcome>> _login((String, String) credentials) async {
    final (email, password) = credentials;
    final result = await _authRepository.login(
      email: email,
      password: password,
    );
    if (result is Error<LoginOutcome>) {
      _log.warning('Login failed! ${result.error}');
    }
    return result;
  }

  Future<Result<void>> _verifyMfa((String, String) args) async {
    final (mfaToken, code) = args;
    final result = await _authRepository.verifyMfa(
      mfaToken: mfaToken,
      code: code,
    );
    if (result is Error<void>) {
      _log.warning('MFA verification failed! ${result.error}');
    }
    return result;
  }
}
