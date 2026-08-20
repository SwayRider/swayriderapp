import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

import '../../utils/result.dart';

class SecureTokenStorageService {
  SecureTokenStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static const _swayriderAccessKey = 'SWAYRIDER_ACCESS';
  static const _swayriderRefreshKey = 'SWAYRIDER_REFRESH';

  final FlutterSecureStorage _storage;
  final _log = Logger('SecureTokenStorageService');

  Future<Result<String?>> fetchAccessToken() async {
    try {
      final value = await _storage.read(key: _swayriderAccessKey);
      _log.finer('Got access token from secure storage');
      return Result.ok(value);
    } on Exception catch (e) {
      _log.warning('Failed to get access token from secure storage', e);
      return Result.error(e);
    }
  }

  Future<Result<String?>> fetchRefreshToken() async {
    try {
      final value = await _storage.read(key: _swayriderRefreshKey);
      _log.finer('Got refresh token from secure storage');
      return Result.ok(value);
    } on Exception catch (e) {
      _log.warning('Failed to get refresh token from secure storage', e);
      return Result.error(e);
    }
  }

  Future<Result<void>> saveAccessToken(String? token) async {
    try {
      if (token == null) {
        _log.finer('Removing access token from secure storage');
        await _storage.delete(key: _swayriderAccessKey);
      } else {
        _log.finer('Saving access token to secure storage');
        await _storage.write(key: _swayriderAccessKey, value: token);
      }
      return Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Failed to save access token to secure storage', e);
      return Result.error(e);
    }
  }

  Future<Result<void>> saveRefreshToken(String? token) async {
    try {
      if (token == null) {
        _log.finer('Removing refresh token from secure storage');
        await _storage.delete(key: _swayriderRefreshKey);
      } else {
        _log.finer('Saving refresh token to secure storage');
        await _storage.write(key: _swayriderRefreshKey, value: token);
      }
      return Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Failed to save refresh token to secure storage', e);
      return Result.error(e);
    }
  }
}
