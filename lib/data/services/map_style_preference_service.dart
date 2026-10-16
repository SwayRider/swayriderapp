import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/map/map_style_mode.dart';
import '../../utils/result.dart';

/// Persists the user's map style choice on the device.
///
/// Not secret, so plain `shared_preferences` rather than the keychain.
class MapStylePreferenceService {
  MapStylePreferenceService({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _modeKey = 'map_style_mode';
  static const _sensorOptInKey = 'map_style_sensor_opt_in';

  /// Mode used until the user picks one.
  static const defaultMode = MapStyleMode.auto;

  final SharedPreferencesAsync _preferences;
  final _log = Logger('MapStylePreferenceService');

  Future<Result<MapStyleMode>> loadMode() async {
    try {
      final name = await _preferences.getString(_modeKey);
      final mode = MapStyleMode.values.where((m) => m.name == name);
      return Result.ok(mode.isEmpty ? defaultMode : mode.first);
    } on Exception catch (e) {
      _log.warning('Failed to read the map style mode', e);
      return Result.error(e);
    }
  }

  Future<Result<void>> saveMode(MapStyleMode mode) async {
    try {
      await _preferences.setString(_modeKey, mode.name);
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Failed to save the map style mode', e);
      return Result.error(e);
    }
  }

  /// Whether the user has explicitly chosen Auto, which on iOS is what allows
  /// the camera-based ambient light measurement (and its permission prompt).
  Future<Result<bool>> loadSensorOptIn() async {
    try {
      return Result.ok(await _preferences.getBool(_sensorOptInKey) ?? false);
    } on Exception catch (e) {
      _log.warning('Failed to read the ambient light opt-in', e);
      return Result.error(e);
    }
  }

  Future<Result<void>> saveSensorOptIn(bool value) async {
    try {
      await _preferences.setBool(_sensorOptInKey, value);
      return const Result.ok(null);
    } on Exception catch (e) {
      _log.warning('Failed to save the ambient light opt-in', e);
      return Result.error(e);
    }
  }
}
