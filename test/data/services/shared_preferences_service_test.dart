import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swayriderapp/data/services/shared_preferences_service.dart';
import 'package:swayriderapp/utils/result.dart';

void main() {
  late SharedPreferencesService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SharedPreferencesService();
  });

  group('access token', () {
    test('fetchAccessToken returns Ok(null) when unset', () async {
      final result = await service.fetchAccessToken();

      expect(result, isA<Ok<String?>>());
      expect((result as Ok<String?>).value, isNull);
    });

    test('fetchAccessToken returns the stored value', () async {
      SharedPreferences.setMockInitialValues({
        'SWAYRIDER_ACCESS': 'access-123',
      });
      service = SharedPreferencesService();

      final result = await service.fetchAccessToken();

      expect((result as Ok<String?>).value, 'access-123');
    });

    test('saveAccessToken persists the token', () async {
      await service.saveAccessToken('access-123');

      final result = await service.fetchAccessToken();

      expect((result as Ok<String?>).value, 'access-123');
    });

    test('saveAccessToken(null) removes the stored token', () async {
      SharedPreferences.setMockInitialValues({
        'SWAYRIDER_ACCESS': 'access-123',
      });
      service = SharedPreferencesService();

      await service.saveAccessToken(null);

      final result = await service.fetchAccessToken();
      expect((result as Ok<String?>).value, isNull);
    });
  });

  group('refresh token', () {
    test('fetchRefreshToken returns Ok(null) when unset', () async {
      final result = await service.fetchRefreshToken();

      expect((result as Ok<String?>).value, isNull);
    });

    test('fetchRefreshToken returns the stored value', () async {
      SharedPreferences.setMockInitialValues({
        'SWAYRIDER_REFRESH': 'refresh-456',
      });
      service = SharedPreferencesService();

      final result = await service.fetchRefreshToken();

      expect((result as Ok<String?>).value, 'refresh-456');
    });

    test('saveRefreshToken persists the token', () async {
      await service.saveRefreshToken('refresh-456');

      final result = await service.fetchRefreshToken();

      expect((result as Ok<String?>).value, 'refresh-456');
    });

    test('saveRefreshToken(null) removes the stored token', () async {
      SharedPreferences.setMockInitialValues({
        'SWAYRIDER_REFRESH': 'refresh-456',
      });
      service = SharedPreferencesService();

      await service.saveRefreshToken(null);

      final result = await service.fetchRefreshToken();
      expect((result as Ok<String?>).value, isNull);
    });
  });
}
