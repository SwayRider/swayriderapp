import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/result.dart';

class SharedPreferencesService {
  static const _swayriderAccessKey = 'SWAYRIDER_ACCESS';
  static const _swayriderRefreshKey = 'SWAYRIDER_REFRESH';

  final _log = Logger('SharedPreferencesService');

  Future<Result<String?>> fetchAccessToken() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      _log.finer('Got access token from SharedPreferences');
      return Result.ok(sharedPreferences.getString(_swayriderAccessKey));
    } on Exception catch (e) {
      _log.warning('Failed to get access token from SharedPreferences', e);
      return Result.error(e);
    }
  }

  Future<Result<String?>> fetchRefreshToken() async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      _log.finer('Got refresh token from SharedPreferences');
      return Result.ok(sharedPreferences.getString(_swayriderRefreshKey));
    } on Exception catch (e) {
      _log.warning('Failed to get refresh token from SharedPreferences', e);
      return Result.error(e);
    }
  }

  Future<Result<void>> saveAccessToken(String? token) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      if (token == null) {
        _log.finer('Removing access token from SharedPreferences');
        await sharedPreferences.remove(_swayriderAccessKey);
      } else {
        _log.finer('Saving access token to SharedPreferences');
        await sharedPreferences.setString(_swayriderAccessKey, token);
      }
      return Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Failed to save access token to SharedPreferences', e);
      return Result.error(e);
    }
  }

  Future<Result<void>> saveRefreshToken(String? token) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      if (token == null) {
        _log.finer('Removing refresh token from SharedPreferences');
        await sharedPreferences.remove(_swayriderRefreshKey);
      } else {
        _log.finer('Saving refresh token to SharedPreferences');
        await sharedPreferences.setString(_swayriderRefreshKey, token);
      }
      return Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Failed to save refresh token to SharedPreferences', e);
      return Result.error(e);
    }
  }
}