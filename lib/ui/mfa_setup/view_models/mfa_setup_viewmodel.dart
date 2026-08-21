import 'package:logging/logging.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../domain/models/mfa/mfa_setup_info.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class MfaSetupViewModel {
  MfaSetupViewModel({required AuthRepository authRepository})
    // ignore: prefer_initializing_formals
    : _authRepository = authRepository {
    startSetup = Command1<void, void>(_startSetup);
    enable = Command1<void, String>(_enable);
  }

  final AuthRepository _authRepository;
  final _log = Logger('MfaSetupViewModel');

  /// Step 1 — requests the enrollment data (secret, otpauth URL, QR PNG).
  late final Command1<void, void> startSetup;

  /// Step 3 — confirms the TOTP code and enables MFA; stores the one-time
  /// backup codes on success.
  late final Command1<void, String> enable;

  MfaSetupInfo? _setupInfo;
  MfaSetupInfo? get setupInfo => _setupInfo;

  List<String>? _backupCodes;
  List<String>? get backupCodes => _backupCodes;

  bool get invalidCode => enable.result is Error;

  Future<Result<void>> _startSetup(void _) async {
    final result = await _authRepository.setupMfa();
    switch (result) {
      case Ok(:final value):
        _setupInfo = value;
        return const Result.ok(null);
      case Error(:final error):
        _log.warning('MFA setup failed! $error');
        return Result.error(error);
    }
  }

  Future<Result<void>> _enable(String code) async {
    final result = await _authRepository.enableMfa(code: code);
    switch (result) {
      case Ok(:final value):
        _backupCodes = value;
        return const Result.ok(null);
      case Error(:final error):
        _log.warning('MFA enable failed! $error');
        return Result.error(error);
    }
  }
}
