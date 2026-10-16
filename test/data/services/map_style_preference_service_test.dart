import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:swayriderapp/data/services/map_style_preference_service.dart';
import 'package:swayriderapp/domain/models/map/map_style_mode.dart';
import 'package:swayriderapp/utils/result.dart';

void main() {
  late MapStylePreferenceService service;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = MapStylePreferenceService(preferences: SharedPreferencesAsync());
  });

  test('defaults to auto when nothing was saved', () async {
    final result = await service.loadMode();
    expect((result as Ok<MapStyleMode>).value, MapStyleMode.auto);
  });

  test('saves and loads each mode', () async {
    for (final mode in MapStyleMode.values) {
      expect(await service.saveMode(mode), isA<Ok<void>>());
      final result = await service.loadMode();
      expect((result as Ok<MapStyleMode>).value, mode);
    }
  });

  test('an unknown saved value falls back to the default', () async {
    await SharedPreferencesAsync().setString('map_style_mode', 'sepia');
    final result = await service.loadMode();
    expect((result as Ok<MapStyleMode>).value, MapStyleMode.auto);
  });

  test('the sensor opt-in defaults to false and is saved', () async {
    expect((await service.loadSensorOptIn() as Ok<bool>).value, isFalse);
    await service.saveSensorOptIn(true);
    expect((await service.loadSensorOptIn() as Ok<bool>).value, isTrue);
  });
}
