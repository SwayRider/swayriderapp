import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/services/api/model/auth/auth.dart';

void main() {
  group('LoginResponse', () {
    test('fromJson maps snake_case keys to camelCase fields', () {
      final response = LoginResponse.fromJson({
        'access_token': 'access-123',
        'refresh_token': 'refresh-456',
      });

      expect(response.accessToken, 'access-123');
      expect(response.refreshToken, 'refresh-456');
      expect(response.mfaRequired, isFalse);
      expect(response.mfaToken, isNull);
    });

    test('fromJson parses the MFA challenge fields', () {
      final response = LoginResponse.fromJson({
        'access_token': 'access-123',
        'refresh_token': 'refresh-456',
        'mfa_required': true,
        'mfa_token': 'challenge-token-789',
      });

      expect(response.mfaRequired, isTrue);
      expect(response.mfaToken, 'challenge-token-789');
    });

    test('toJson round-trips to snake_case keys', () {
      const response = LoginResponse(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
      );

      expect(response.toJson(), {
        'access_token': 'access-123',
        'refresh_token': 'refresh-456',
        'mfa_required': false,
        'mfa_token': null,
      });
    });

    test('toJson includes the MFA fields when set', () {
      const response = LoginResponse(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        mfaRequired: true,
        mfaToken: 'challenge-token-789',
      );

      expect(response.toJson()['mfa_required'], isTrue);
      expect(response.toJson()['mfa_token'], 'challenge-token-789');
    });

    test('fromJson throws when a required key is missing', () {
      expect(
        () => LoginResponse.fromJson({'access_token': 'access-123'}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
