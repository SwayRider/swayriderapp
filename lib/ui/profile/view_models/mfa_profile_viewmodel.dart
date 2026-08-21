import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class MfaProfileViewModel extends ChangeNotifier {
  MfaProfileViewModel({required AuthRepository authRepository})
    // ignore: prefer_initializing_formals
    : _authRepository = authRepository {
    load = Command0<void>(_load);
    disable = Command1<void, String>(_disable);
  }

  final AuthRepository _authRepository;
  final _log = Logger('MfaProfileViewModel');

  /// Loads the current MFA status; call on screen load and after
  /// enabling/disabling.
  late final Command0<void> load;

  /// Disables MFA using the account [password].
  late final Command1<void, String> disable;

  bool? _enabled;
  bool? get enabled => _enabled;

  bool get loading => load.running;
  bool get error => load.error;

  Future<Result<void>> _load() async {
    final result = await _authRepository.getMfaStatus();
    switch (result) {
      case Ok(:final value):
        _enabled = value;
        return const Result.ok(null);
      case Error(:final error):
        _log.warning('MFA status load failed! $error');
        return Result.error(error);
    }
  }

  Future<Result<void>> _disable(String password) async {
    final result = await _authRepository.disableMfa(password: password);
    if (result is Error<void>) {
      _log.warning('MFA disable failed! ${result.error}');
    }
    return result;
  }
}
