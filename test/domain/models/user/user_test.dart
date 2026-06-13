import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/domain/models/user/user.dart';

void main() {
  group('User', () {
    test('fromJson/toJson round-trip with all fields present', () {
      final json = {
        'id': 'user-1',
        'email': 'a@b.com',
        'isVerified': true,
        'isAdmin': true,
        'accountType': 'premium',
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-1');
      expect(user.email, 'a@b.com');
      expect(user.isVerified, isTrue);
      expect(user.isAdmin, isTrue);
      expect(user.accountType, 'premium');
      expect(user.toJson(), json);
    });

    test('fromJson defaults nullable fields to null when omitted', () {
      final user = User.fromJson({
        'id': 'user-1',
        'email': 'a@b.com',
        'isVerified': false,
      });

      expect(user.isAdmin, isNull);
      expect(user.accountType, isNull);
    });

    test('equality is value-based', () {
      const a = User(id: 'user-1', email: 'a@b.com', isVerified: true);
      const b = User(id: 'user-1', email: 'a@b.com', isVerified: true);

      expect(a, b);
    });

    test('copyWith returns a new instance with updated fields', () {
      const user = User(id: 'user-1', email: 'a@b.com', isVerified: false);

      final verified = user.copyWith(isVerified: true);

      expect(verified.isVerified, isTrue);
      expect(verified.id, user.id);
      expect(verified.email, user.email);
      expect(user.isVerified, isFalse);
    });
  });
}
