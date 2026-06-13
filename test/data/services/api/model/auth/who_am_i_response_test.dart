import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/services/api/model/auth/auth.dart';

void main() {
  group('WhoAmIResponse', () {
    test('fromJson maps all snake_case keys to camelCase fields', () {
      final response = WhoAmIResponse.fromJson({
        'user_id': 'user-1',
        'email': 'a@b.com',
        'is_verified': true,
        'is_admin': false,
        'account_type': 'standard',
      });

      expect(response.userId, 'user-1');
      expect(response.email, 'a@b.com');
      expect(response.isVerified, isTrue);
      expect(response.isAdmin, isFalse);
      expect(response.accountType, 'standard');
    });

    test('toJson round-trips to snake_case keys', () {
      const response = WhoAmIResponse(
        userId: 'user-1',
        email: 'a@b.com',
        isVerified: true,
        isAdmin: false,
        accountType: 'standard',
      );

      expect(response.toJson(), {
        'user_id': 'user-1',
        'email': 'a@b.com',
        'is_verified': true,
        'is_admin': false,
        'account_type': 'standard',
      });
    });

    test('fromJson throws when a required key is missing', () {
      expect(
        () => WhoAmIResponse.fromJson({
          'user_id': 'user-1',
          'email': 'a@b.com',
          'is_verified': true,
          'is_admin': false,
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
