import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:swayriderapp/data/services/api/auth_api_client.dart';
import 'package:swayriderapp/data/services/api/model/auth/auth.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/fake_http_client.dart';

FakeHttpClient okClient([Map<String, dynamic> body = const {}]) =>
    FakeHttpClient(FakeHttpClientResponse(200, jsonEncode(body)));

FakeHttpClient errorClient([int statusCode = 400]) =>
    FakeHttpClient(FakeHttpClientResponse(statusCode));

void main() {
  group('AuthApiClient', () {
    group('login', () {
      const request = LoginRequest(email: 'a@b.com', password: 'pw');

      test('200 returns Ok(LoginResponse) with mapped fields', () async {
        final client = okClient({
          'access_token': 'access-123',
          'refresh_token': 'refresh-456',
        });
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.login(request);

        final value = (result as Ok<LoginResponse>).value;
        expect(value.accessToken, 'access-123');
        expect(value.refreshToken, 'refresh-456');
      });

      test('sends POST /login with JSON body and content type', () async {
        final client = okClient({
          'access_token': 'access-123',
          'refresh_token': 'refresh-456',
        });
        final api = AuthApiClient(clientFactory: () => client);

        await api.login(request);

        final sent = client.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.uri.path, '/login');
        expect(sent.headers.contentType?.mimeType, 'application/json');
        expect(sent.bodyJson, {
          'email': 'a@b.com',
          'password': 'pw',
          'remember_me': false,
        });
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient(401);
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.login(request);

        expect((result as Error<LoginResponse>).error, isA<HttpException>());
        expect(result.error.toString(), contains('Login error'));
      });

      test('closes the underlying client', () async {
        final client = okClient({
          'access_token': 'access-123',
          'refresh_token': 'refresh-456',
        });
        final api = AuthApiClient(clientFactory: () => client);

        await api.login(request);

        expect(client.closed, isTrue);
      });

      test('exception during request returns Result.error(e)', () async {
        final exception = Exception('network down');
        final client = FakeThrowingHttpClient(exception);
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.login(request);

        expect((result as Error<LoginResponse>).error, exception);
        expect(client.closed, isTrue);
      });

      test('custom scheme/host/port/pathPrefix builds the expected URI', () async {
        final client = okClient({
          'access_token': 'access-123',
          'refresh_token': 'refresh-456',
        });
        final api = AuthApiClient(
          scheme: 'https',
          host: 'api.example.com',
          port: 443,
          pathPrefix: '/api/v1/auth',
          clientFactory: () => client,
        );

        await api.login(request);

        expect(
          client.lastRequest!.uri,
          Uri(
            scheme: 'https',
            host: 'api.example.com',
            port: 443,
            path: '/api/v1/auth/login',
          ),
        );
      });
    });

    group('register', () {
      const request = RegisterRequest(
        email: 'a@b.com',
        password: 'pw',
        verificationUrl: 'https://app/verify',
      );

      test('200 returns Ok(RegisterResponse) with mapped fields', () async {
        final client = okClient({'user_id': 'user-1', 'message': 'ok'});
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.register(request);

        final value = (result as Ok<RegisterResponse>).value;
        expect(value.userId, 'user-1');
        expect(value.message, 'ok');
      });

      test('sends POST /register with mapped body', () async {
        final client = okClient({'user_id': 'user-1', 'message': 'ok'});
        final api = AuthApiClient(clientFactory: () => client);

        await api.register(request);

        final sent = client.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.uri.path, '/register');
        expect(sent.bodyJson, {
          'email': 'a@b.com',
          'password': 'pw',
          'verification_url': 'https://app/verify',
        });
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.register(request);

        expect((result as Error<RegisterResponse>).error.toString(), contains('Register error'));
      });

      test('403 returns Result.error(InvitationRequiredException)', () async {
        final client = errorClient(403);
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.register(request);

        expect((result as Error<RegisterResponse>).error, isA<InvitationRequiredException>());
      });

      test('400 with weak-password body returns Result.error(WeakPasswordException)', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(400, jsonEncode({
          'error': 'rpc error: code = InvalidArgument desc = password is too weak: needs at least 8 characters',
        })));
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.register(request);

        expect((result as Error<RegisterResponse>).error, isA<WeakPasswordException>());
      });
    });

    group('refresh', () {
      final request = RefreshRequest(refreshToken: 'refresh-456');

      test('200 returns Ok(RefreshResponse) with mapped fields', () async {
        // RefreshResponse uses camelCase @JsonKey names ('accessToken'/
        // 'refreshToken'), unlike LoginResponse's snake_case keys.
        final client = okClient({
          'accessToken': 'access-789',
          'refreshToken': 'refresh-101',
        });
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.refresh(request);

        final value = (result as Ok<RefreshResponse>).value;
        expect(value.accessToken, 'access-789');
        expect(value.refreshToken, 'refresh-101');
      });

      test('sends POST /refresh with mapped body', () async {
        final client = okClient({
          'accessToken': 'access-789',
          'refreshToken': 'refresh-101',
        });
        final api = AuthApiClient(clientFactory: () => client);

        await api.refresh(request);

        final sent = client.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.uri.path, '/refresh');
        expect(sent.bodyJson, {
          'refresh_token': 'refresh-456',
          'remember_me': false,
        });
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.refresh(request);

        expect((result as Error<RefreshResponse>).error.toString(), contains('Refresh error'));
      });
    });

    group('logout', () {
      test('200 returns Ok(null)', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(200));
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.logout(const LogoutRequest(refreshToken: 'refresh-456'));

        expect(result, isA<Ok<void>>());
      });

      test('sends POST /logout with the refresh token', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(200));
        final api = AuthApiClient(clientFactory: () => client);

        await api.logout(const LogoutRequest(refreshToken: 'refresh-456'));

        final sent = client.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.uri.path, '/logout');
        expect(sent.bodyJson['refresh_token'], 'refresh-456');
      });

      test('sends null refresh token when logging out without one', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(200));
        final api = AuthApiClient(clientFactory: () => client);

        await api.logout(const LogoutRequest());

        expect(client.lastRequest!.bodyJson['refresh_token'], isNull);
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.logout(const LogoutRequest());

        expect((result as Error<void>).error.toString(), contains('Logout error'));
      });
    });

    group('requestPasswordReset', () {
      const request = PasswordResetRequest(
        email: 'a@b.com',
        resetUrl: 'https://app/reset',
      );

      test('200 returns Ok(null)', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(200));
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.requestPasswordReset(request);

        expect(result, isA<Ok<void>>());
      });

      test('204 returns Ok(null)', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(204));
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.requestPasswordReset(request);

        expect(result, isA<Ok<void>>());
      });

      test('sends POST /request-password-reset with mapped body', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(200));
        final api = AuthApiClient(clientFactory: () => client);

        await api.requestPasswordReset(request);

        final sent = client.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.uri.path, '/request-password-reset');
        expect(sent.bodyJson, {
          'email': 'a@b.com',
          'reset_url': 'https://app/reset',
        });
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.requestPasswordReset(request);

        expect((result as Error<void>).error.toString(), contains('Password reset error'));
      });
    });

    group('resetPassword', () {
      const request = ResetPasswordRequest(
        userId: 'user-1',
        token: 'reset-token',
        newPassword: 'newpw',
      );

      test('200 returns Ok(ResetPasswordResponse) with mapped fields', () async {
        final client = okClient({'message': 'password reset'});
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.resetPassword(request);

        expect((result as Ok<ResetPasswordResponse>).value.message, 'password reset');
      });

      test('sends POST /reset-password with mapped body', () async {
        final client = okClient({'message': 'password reset'});
        final api = AuthApiClient(clientFactory: () => client);

        await api.resetPassword(request);

        final sent = client.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.uri.path, '/reset-password');
        expect(sent.bodyJson, {
          'user_id': 'user-1',
          'token': 'reset-token',
          'new_password': 'newpw',
        });
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.resetPassword(request);

        expect((result as Error<ResetPasswordResponse>).error.toString(), contains('Reset password error'));
      });
    });

    group('verifyEmail', () {
      const request = VerifyEmailRequest(
        email: 'a@b.com',
        verificationUrl: 'https://app/verify',
      );

      test('200 returns Ok(null)', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(200));
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.verifyEmail(request);

        expect(result, isA<Ok<void>>());
      });

      test('204 returns Ok(null)', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(204));
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.verifyEmail(request);

        expect(result, isA<Ok<void>>());
      });

      test('sends POST /verify-email with mapped body', () async {
        final client = FakeHttpClient(FakeHttpClientResponse(200));
        final api = AuthApiClient(clientFactory: () => client);

        await api.verifyEmail(request);

        final sent = client.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.uri.path, '/verify-email');
        expect(sent.bodyJson, {
          'email': 'a@b.com',
          'verification_url': 'https://app/verify',
        });
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.verifyEmail(request);

        expect((result as Error<void>).error.toString(), contains('Verify email error'));
      });
    });

    group('changePassword', () {
      const request = ChangePasswordRequest(
        oldPassword: 'oldpw',
        newPassword: 'newpw',
      );

      test('200 returns Ok(ChangePasswordResponse) with mapped fields', () async {
        final client = okClient({'message': 'password changed'});
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.changePassword(request);

        expect((result as Ok<ChangePasswordResponse>).value.message, 'password changed');
      });

      test('sends POST /change-password with mapped body', () async {
        final client = okClient({'message': 'password changed'});
        final api = AuthApiClient(clientFactory: () => client);

        await api.changePassword(request);

        final sent = client.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.uri.path, '/change-password');
        expect(sent.bodyJson, {
          'old_password': 'oldpw',
          'new_password': 'newpw',
        });
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.changePassword(request);

        expect((result as Error<ChangePasswordResponse>).error.toString(), contains('Change password error'));
      });

      test('sends Authorization header when authHeaderProvider is set', () async {
        final client = okClient({'message': 'password changed'});
        final api = AuthApiClient(clientFactory: () => client);
        api.authHeaderProvider = () => 'Bearer test-token';

        await api.changePassword(request);

        expect(client.lastRequest!.headers.value('Authorization'), 'Bearer test-token');
      });

      test('omits Authorization header when authHeaderProvider returns null', () async {
        final client = okClient({'message': 'password changed'});
        final api = AuthApiClient(clientFactory: () => client);
        api.authHeaderProvider = () => null;

        await api.changePassword(request);

        expect(client.lastRequest!.headers.value('Authorization'), isNull);
      });
    });

    group('checkPasswordStrength', () {
      const request = CheckPasswordStrengthRequest(password: 'pw');

      test('200 returns Ok(CheckPasswordStrengthResponse) with mapped fields', () async {
        final client = okClient({'is_strong': true, 'message': 'strong'});
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.checkPasswordStrength(request);

        final value = (result as Ok<CheckPasswordStrengthResponse>).value;
        expect(value.isStrong, isTrue);
        expect(value.message, 'strong');
      });

      test('sends POST /check-password-strength with mapped body', () async {
        final client = okClient({'is_strong': true, 'message': 'strong'});
        final api = AuthApiClient(clientFactory: () => client);

        await api.checkPasswordStrength(request);

        final sent = client.lastRequest!;
        expect(sent.method, 'POST');
        expect(sent.uri.path, '/check-password-strength');
        expect(sent.bodyJson, {'password': 'pw'});
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.checkPasswordStrength(request);

        expect((result as Error<CheckPasswordStrengthResponse>).error.toString(), contains('Check password strength error'));
      });
    });

    group('whoAmI', () {
      test('200 returns Ok(WhoAmIResponse) with all fields mapped', () async {
        final client = okClient({
          'user_id': 'user-1',
          'email': 'a@b.com',
          'is_verified': true,
          'is_admin': true,
          'account_type': 'premium',
        });
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.whoAmI();

        final value = (result as Ok<WhoAmIResponse>).value;
        expect(value.userId, 'user-1');
        expect(value.email, 'a@b.com');
        expect(value.isVerified, isTrue);
        expect(value.isAdmin, isTrue);
        expect(value.accountType, 'premium');
      });

      test('sends GET /whoami', () async {
        final client = okClient({
          'user_id': 'user-1',
          'email': 'a@b.com',
          'is_verified': true,
          'is_admin': true,
          'account_type': 'premium',
        });
        final api = AuthApiClient(clientFactory: () => client);

        await api.whoAmI();

        final sent = client.lastRequest!;
        expect(sent.method, 'GET');
        expect(sent.uri.path, '/whoami');
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.whoAmI();

        expect((result as Error<WhoAmIResponse>).error.toString(), contains('Who am I error'));
      });

      test('401 returns Result.error(UnauthorizedException)', () async {
        final client = errorClient(401);
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.whoAmI();

        expect((result as Error<WhoAmIResponse>).error, isA<UnauthorizedException>());
      });

      test('sends Authorization header when authHeaderProvider is set', () async {
        final client = okClient({
          'user_id': 'user-1',
          'email': 'a@b.com',
          'is_verified': true,
          'is_admin': true,
          'account_type': 'premium',
        });
        final api = AuthApiClient(clientFactory: () => client);
        api.authHeaderProvider = () => 'Bearer test-token';

        await api.whoAmI();

        expect(client.lastRequest!.headers.value('Authorization'), 'Bearer test-token');
      });

      test('omits Authorization header when authHeaderProvider returns null', () async {
        final client = okClient({
          'user_id': 'user-1',
          'email': 'a@b.com',
          'is_verified': true,
          'is_admin': true,
          'account_type': 'premium',
        });
        final api = AuthApiClient(clientFactory: () => client);
        api.authHeaderProvider = () => null;

        await api.whoAmI();

        expect(client.lastRequest!.headers.value('Authorization'), isNull);
      });
    });

    group('me', () {
      test('200 returns Ok(MeResponse) with non-null email', () async {
        final client = okClient({
          'user_id': 'user-1',
          'email': 'a@b.com',
          'email_verified': true,
        });
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.me();

        final value = (result as Ok<MeResponse>).value;
        expect(value.userId, 'user-1');
        expect(value.email, 'a@b.com');
        expect(value.emailVerified, isTrue);
      });

      test('200 returns Ok(MeResponse) with null email', () async {
        final client = okClient({
          'user_id': 'user-1',
          'email': null,
          'email_verified': false,
        });
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.me();

        final value = (result as Ok<MeResponse>).value;
        expect(value.email, isNull);
        expect(value.emailVerified, isFalse);
      });

      test('sends GET /me', () async {
        final client = okClient({
          'user_id': 'user-1',
          'email': 'a@b.com',
          'email_verified': true,
        });
        final api = AuthApiClient(clientFactory: () => client);

        await api.me();

        final sent = client.lastRequest!;
        expect(sent.method, 'GET');
        expect(sent.uri.path, '/me');
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.me();

        expect((result as Error<MeResponse>).error.toString(), contains('Me error'));
      });

      test('401 returns Result.error(UnauthorizedException)', () async {
        final client = errorClient(401);
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.me();

        expect((result as Error<MeResponse>).error, isA<UnauthorizedException>());
      });

      test('sends Authorization header when authHeaderProvider is set', () async {
        final client = okClient({
          'user_id': 'user-1',
          'email': 'a@b.com',
          'email_verified': true,
        });
        final api = AuthApiClient(clientFactory: () => client);
        api.authHeaderProvider = () => 'Bearer test-token';

        await api.me();

        expect(client.lastRequest!.headers.value('Authorization'), 'Bearer test-token');
      });
    });

    group('publicKeys', () {
      test('200 returns Ok(PublicKeysResponse) with mapped keys', () async {
        final client = okClient({'keys': ['key-1', 'key-2']});
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.publicKeys();

        expect((result as Ok<PublicKeysResponse>).value.keys, ['key-1', 'key-2']);
      });

      test('sends GET /public-keys', () async {
        final client = okClient({'keys': <String>[]});
        final api = AuthApiClient(clientFactory: () => client);

        await api.publicKeys();

        final sent = client.lastRequest!;
        expect(sent.method, 'GET');
        expect(sent.uri.path, '/public-keys');
      });

      test('non-200 returns Result.error(HttpException)', () async {
        final client = errorClient();
        final api = AuthApiClient(clientFactory: () => client);

        final result = await api.publicKeys();

        expect((result as Error<PublicKeysResponse>).error.toString(), contains('Public keys error'));
      });

      test('never sends an Authorization header, even if authHeaderProvider is set', () async {
        final client = okClient({'keys': <String>[]});
        final api = AuthApiClient(clientFactory: () => client);
        api.authHeaderProvider = () => 'Bearer test-token';

        await api.publicKeys();

        expect(client.lastRequest!.headers.value('Authorization'), isNull);
      });
    });
  });
}
