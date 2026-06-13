import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required AuthRepository authRepository})
  // ignore: prefer_initializing_formals
  : _authRepository = authRepository {
    logout = Command0<void>(_logout);
  }

  final AuthRepository _authRepository;
  final _log = Logger('HomeViewModel');

  late Command0 logout;

  Future<Result<void>> _logout() async {
    final result = await _authRepository.logout();
    if (result is Error<void>) {
      _log.warning('Logout failed! ${result.error}');
    }
    return result;
  }
}
