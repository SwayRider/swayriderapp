import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/data/services/secure_token_storage_service.dart';
import 'package:swayriderapp/utils/result.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureTokenStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureTokenStorageService(storage: mockStorage);
  });

  group('access token', () {
    test('fetchAccessToken returns Ok(null) when unset', () async {
      when(
        () => mockStorage.read(key: 'SWAYRIDER_ACCESS'),
      ).thenAnswer((_) async => null);

      final result = await service.fetchAccessToken();

      expect(result, isA<Ok<String?>>());
      expect((result as Ok<String?>).value, isNull);
    });

    test('fetchAccessToken returns the stored value', () async {
      when(
        () => mockStorage.read(key: 'SWAYRIDER_ACCESS'),
      ).thenAnswer((_) async => 'access-123');

      final result = await service.fetchAccessToken();

      expect((result as Ok<String?>).value, 'access-123');
    });

    test(
      'fetchAccessToken returns Error when the storage read throws',
      () async {
        when(
          () => mockStorage.read(key: 'SWAYRIDER_ACCESS'),
        ).thenThrow(Exception('platform failure'));

        final result = await service.fetchAccessToken();

        expect(result, isA<Error<String?>>());
      },
    );

    test('saveAccessToken persists the token', () async {
      when(
        () => mockStorage.write(key: 'SWAYRIDER_ACCESS', value: 'access-123'),
      ).thenAnswer((_) async {});

      final result = await service.saveAccessToken('access-123');

      expect(result, isA<Ok<void>>());
      verify(
        () => mockStorage.write(key: 'SWAYRIDER_ACCESS', value: 'access-123'),
      ).called(1);
    });

    test('saveAccessToken(null) removes the stored token', () async {
      when(
        () => mockStorage.delete(key: 'SWAYRIDER_ACCESS'),
      ).thenAnswer((_) async {});

      final result = await service.saveAccessToken(null);

      expect(result, isA<Ok<void>>());
      verify(() => mockStorage.delete(key: 'SWAYRIDER_ACCESS')).called(1);
    });
  });

  group('refresh token', () {
    test('fetchRefreshToken returns Ok(null) when unset', () async {
      when(
        () => mockStorage.read(key: 'SWAYRIDER_REFRESH'),
      ).thenAnswer((_) async => null);

      final result = await service.fetchRefreshToken();

      expect((result as Ok<String?>).value, isNull);
    });

    test('fetchRefreshToken returns the stored value', () async {
      when(
        () => mockStorage.read(key: 'SWAYRIDER_REFRESH'),
      ).thenAnswer((_) async => 'refresh-456');

      final result = await service.fetchRefreshToken();

      expect((result as Ok<String?>).value, 'refresh-456');
    });

    test('saveRefreshToken persists the token', () async {
      when(
        () => mockStorage.write(key: 'SWAYRIDER_REFRESH', value: 'refresh-456'),
      ).thenAnswer((_) async {});

      final result = await service.saveRefreshToken('refresh-456');

      expect(result, isA<Ok<void>>());
      verify(
        () => mockStorage.write(key: 'SWAYRIDER_REFRESH', value: 'refresh-456'),
      ).called(1);
    });

    test('saveRefreshToken(null) removes the stored token', () async {
      when(
        () => mockStorage.delete(key: 'SWAYRIDER_REFRESH'),
      ).thenAnswer((_) async {});

      final result = await service.saveRefreshToken(null);

      expect(result, isA<Ok<void>>());
      verify(() => mockStorage.delete(key: 'SWAYRIDER_REFRESH')).called(1);
    });
  });
}
