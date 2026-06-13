import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/data/repositories/auth/auth_repository_remote.dart';
import 'package:swayriderapp/data/services/api/auth_header_provider.dart';
import 'package:swayriderapp/data/services/api/model/auth/auth.dart';
import 'package:swayriderapp/domain/models/user/user.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthApiClient mockApiClient;
  late MockSharedPreferencesService mockPrefs;
  late AuthRepositoryRemote repository;

  setUpAll(registerFallbacks);

  setUp(() {
    mockApiClient = MockAuthApiClient();
    mockPrefs = MockSharedPreferencesService();
    when(() => mockApiClient.authHeaderProvider = any<AuthHeaderProvider>())
        .thenReturn(() => null);
    when(() => mockPrefs.saveAccessToken(any()))
        .thenAnswer((_) async => const Result.ok(null));
    when(() => mockPrefs.saveRefreshToken(any()))
        .thenAnswer((_) async => const Result.ok(null));
    repository = AuthRepositoryRemote(
      authApiClient: mockApiClient,
      sharedPreferencesService: mockPrefs,
    );
  });

  test('constructor wires authHeaderProvider on the api client', () {
    verify(() => mockApiClient.authHeaderProvider = any()).called(1);
  });

  group('isAuthenticated', () {
    test('short-circuits prefs once an access token is cached', () async {
      when(() => mockApiClient.login(any())).thenAnswer((_) async =>
          const Result.ok(
              LoginResponse(accessToken: 'access-1', refreshToken: 'refresh-1')));
      await repository.login(email: 'a@b.com', password: 'pw');

      expect(await repository.isAuthenticated, isTrue);
      verifyNever(() => mockPrefs.fetchAccessToken());
    });

    test('fetches from prefs, caches the result, and returns true', () async {
      when(() => mockPrefs.fetchAccessToken())
          .thenAnswer((_) async => const Result.ok('stored-access'));

      expect(await repository.isAuthenticated, isTrue);
      expect(await repository.isAuthenticated, isTrue);
      verify(() => mockPrefs.fetchAccessToken()).called(1);
    });

    test('returns false when prefs has no token', () async {
      when(() => mockPrefs.fetchAccessToken())
          .thenAnswer((_) async => const Result.ok(null));

      expect(await repository.isAuthenticated, isFalse);
    });

    test('returns false when prefs lookup errors', () async {
      when(() => mockPrefs.fetchAccessToken())
          .thenAnswer((_) async => Result.error(Exception('boom')));

      expect(await repository.isAuthenticated, isFalse);
    });
  });

  group('isVerified', () {
    test('Ok(isVerified: true) caches and avoids re-calling me()', () async {
      when(() => mockApiClient.me()).thenAnswer((_) async => Result.ok(
          MeResponse(userId: 'user-1', email: 'a@b.com', emailVerified: true)));

      expect(await repository.isVerified, isTrue);
      expect(await repository.isVerified, isTrue);
      verify(() => mockApiClient.me()).called(1);
    });

    test('Ok(isVerified: false) caches and avoids re-calling me()', () async {
      when(() => mockApiClient.me()).thenAnswer((_) async => Result.ok(
          MeResponse(userId: 'user-1', email: 'a@b.com', emailVerified: false)));

      expect(await repository.isVerified, isFalse);
      expect(await repository.isVerified, isFalse);
      verify(() => mockApiClient.me()).called(1);
    });

    test('Error result returns false and is not cached', () async {
      when(() => mockApiClient.me())
          .thenAnswer((_) async => Result.error(Exception('boom')));

      expect(await repository.isVerified, isFalse);
      expect(await repository.isVerified, isFalse);
      verify(() => mockApiClient.me()).called(2);
    });
  });

  group('isAdmin', () {
    test('Ok(isAdmin: true) caches and avoids re-calling whoAmI()', () async {
      when(() => mockApiClient.whoAmI()).thenAnswer((_) async => const Result.ok(
          WhoAmIResponse(
              userId: 'user-1',
              email: 'a@b.com',
              isVerified: true,
              isAdmin: true,
              accountType: 'premium')));

      expect(await repository.isAdmin, isTrue);
      expect(await repository.isAdmin, isTrue);
      verify(() => mockApiClient.whoAmI()).called(1);
    });

    test('Ok(isAdmin: false) caches and avoids re-calling whoAmI()', () async {
      when(() => mockApiClient.whoAmI()).thenAnswer((_) async => const Result.ok(
          WhoAmIResponse(
              userId: 'user-1',
              email: 'a@b.com',
              isVerified: true,
              isAdmin: false,
              accountType: 'standard')));

      expect(await repository.isAdmin, isFalse);
      expect(await repository.isAdmin, isFalse);
      verify(() => mockApiClient.whoAmI()).called(1);
    });

    test('Error result returns false and is not cached', () async {
      when(() => mockApiClient.whoAmI())
          .thenAnswer((_) async => Result.error(Exception('boom')));

      expect(await repository.isAdmin, isFalse);
      expect(await repository.isAdmin, isFalse);
      verify(() => mockApiClient.whoAmI()).called(2);
    });
  });

  group('login', () {
    test('Ok result saves tokens, notifies, and returns Ok(null)', () async {
      when(() => mockApiClient.login(any())).thenAnswer((_) async =>
          const Result.ok(
              LoginResponse(accessToken: 'access-1', refreshToken: 'refresh-1')));
      var notified = false;
      repository.addListener(() => notified = true);

      final result =
          await repository.login(email: 'a@b.com', password: 'pw');

      expect(result, isA<Ok<void>>());
      expect(notified, isTrue);
      verify(() => mockPrefs.saveAccessToken('access-1')).called(1);
      verify(() => mockPrefs.saveRefreshToken('refresh-1')).called(1);

      final request = verify(() => mockApiClient.login(captureAny()))
          .captured
          .single as LoginRequest;
      expect(request.email, 'a@b.com');
      expect(request.password, 'pw');
      expect(request.rememberMe, isFalse);
    });

    test('after success, isAuthenticated is true without querying prefs', () async {
      when(() => mockApiClient.login(any())).thenAnswer((_) async =>
          const Result.ok(
              LoginResponse(accessToken: 'access-1', refreshToken: 'refresh-1')));

      await repository.login(email: 'a@b.com', password: 'pw');

      expect(await repository.isAuthenticated, isTrue);
      verifyNever(() => mockPrefs.fetchAccessToken());
    });

    test('Error result passes through without persisting tokens', () async {
      final exception = Exception('login failed');
      when(() => mockApiClient.login(any()))
          .thenAnswer((_) async => Result.error(exception));

      final result =
          await repository.login(email: 'a@b.com', password: 'pw');

      expect((result as Error<void>).error, exception);
      verifyNever(() => mockPrefs.saveAccessToken(any()));
      verifyNever(() => mockPrefs.saveRefreshToken(any()));
    });
  });

  group('refresh', () {
    test('uses a cached refresh token without querying prefs', () async {
      when(() => mockApiClient.login(any())).thenAnswer((_) async =>
          const Result.ok(
              LoginResponse(accessToken: 'access-1', refreshToken: 'refresh-1')));
      await repository.login(email: 'a@b.com', password: 'pw');

      when(() => mockApiClient.refresh(any())).thenAnswer((_) async =>
          const Result.ok(RefreshResponse(
              accessToken: 'access-2', refreshToken: 'refresh-2')));

      final result = await repository.refresh();

      expect(result, isA<Ok<void>>());
      verifyNever(() => mockPrefs.fetchRefreshToken());
      final request = verify(() => mockApiClient.refresh(captureAny()))
          .captured
          .single as RefreshRequest;
      expect(request.refreshToken, 'refresh-1');
    });

    test('loads and caches the refresh token from prefs when not cached', () async {
      when(() => mockPrefs.fetchRefreshToken())
          .thenAnswer((_) async => const Result.ok('stored-refresh'));
      when(() => mockApiClient.refresh(any())).thenAnswer((_) async =>
          const Result.ok(RefreshResponse(
              accessToken: 'access-2', refreshToken: 'refresh-2')));

      final first = await repository.refresh();
      expect(first, isA<Ok<void>>());
      final request = verify(() => mockApiClient.refresh(captureAny()))
          .captured
          .single as RefreshRequest;
      expect(request.refreshToken, 'stored-refresh');

      await repository.refresh();
      verify(() => mockPrefs.fetchRefreshToken()).called(1);
    });

    test('returns an error without calling the API when prefs has no token', () async {
      when(() => mockPrefs.fetchRefreshToken())
          .thenAnswer((_) async => const Result.ok(null));

      final result = await repository.refresh();

      final error = (result as Error<void>).error;
      expect(error.toString(), contains('No refresh token available'));
      verifyNever(() => mockApiClient.refresh(any()));
    });

    test('returns an error without calling the API when prefs lookup errors', () async {
      when(() => mockPrefs.fetchRefreshToken())
          .thenAnswer((_) async => Result.error(Exception('boom')));

      final result = await repository.refresh();

      final error = (result as Error<void>).error;
      expect(error.toString(), contains('No refresh token available'));
      verifyNever(() => mockApiClient.refresh(any()));
    });

    test('Ok result saves the new tokens', () async {
      when(() => mockPrefs.fetchRefreshToken())
          .thenAnswer((_) async => const Result.ok('stored-refresh'));
      when(() => mockApiClient.refresh(any())).thenAnswer((_) async =>
          const Result.ok(RefreshResponse(
              accessToken: 'access-2', refreshToken: 'refresh-2')));

      await repository.refresh();

      verify(() => mockPrefs.saveAccessToken('access-2')).called(1);
      verify(() => mockPrefs.saveRefreshToken('refresh-2')).called(1);
    });

    test('Error result passes through without saving tokens', () async {
      when(() => mockPrefs.fetchRefreshToken())
          .thenAnswer((_) async => const Result.ok('stored-refresh'));
      final exception = Exception('refresh failed');
      when(() => mockApiClient.refresh(any()))
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.refresh();

      expect((result as Error<void>).error, exception);
      verifyNever(() => mockPrefs.saveAccessToken(any()));
    });
  });

  group('logout', () {
    test('sends the cached refresh token and clears tokens on Ok', () async {
      when(() => mockApiClient.login(any())).thenAnswer((_) async =>
          const Result.ok(
              LoginResponse(accessToken: 'access-1', refreshToken: 'refresh-1')));
      await repository.login(email: 'a@b.com', password: 'pw');

      when(() => mockApiClient.logout(any()))
          .thenAnswer((_) async => const Result.ok(null));

      final result = await repository.logout();

      expect(result, isA<Ok<void>>());
      final request = verify(() => mockApiClient.logout(captureAny()))
          .captured
          .single as LogoutRequest;
      expect(request.refreshToken, 'refresh-1');
      verify(() => mockPrefs.saveAccessToken(null)).called(1);
      verify(() => mockPrefs.saveRefreshToken(null)).called(1);

      when(() => mockPrefs.fetchAccessToken())
          .thenAnswer((_) async => const Result.ok(null));
      expect(await repository.isAuthenticated, isFalse);
    });

    test('sends a null refresh token when none is cached', () async {
      when(() => mockApiClient.logout(any()))
          .thenAnswer((_) async => const Result.ok(null));

      await repository.logout();

      final request = verify(() => mockApiClient.logout(captureAny()))
          .captured
          .single as LogoutRequest;
      expect(request.refreshToken, isNull);
    });

    test('clears tokens and resets isVerified cache even on API error', () async {
      when(() => mockApiClient.me()).thenAnswer((_) async => Result.ok(
          MeResponse(userId: 'user-1', email: 'a@b.com', emailVerified: true)));
      await repository.isVerified;

      final exception = Exception('logout failed');
      when(() => mockApiClient.logout(any()))
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.logout();

      expect((result as Error<void>).error, exception);
      verify(() => mockPrefs.saveAccessToken(null)).called(1);
      verify(() => mockPrefs.saveRefreshToken(null)).called(1);

      await repository.isVerified;
      verify(() => mockApiClient.me()).called(2);
    });

    test('notifies listeners', () async {
      when(() => mockApiClient.logout(any()))
          .thenAnswer((_) async => const Result.ok(null));
      var notified = false;
      repository.addListener(() => notified = true);

      await repository.logout();

      expect(notified, isTrue);
    });
  });

  group('register', () {
    test('Ok result returns Ok(null) with mapped request fields', () async {
      when(() => mockApiClient.register(any())).thenAnswer((_) async =>
          const Result.ok(RegisterResponse(userId: 'user-1', message: 'ok')));

      final result = await repository.register(
        email: 'a@b.com',
        password: 'pw',
        verificationUrl: 'https://app/verify',
      );

      expect(result, isA<Ok<void>>());
      final request = verify(() => mockApiClient.register(captureAny()))
          .captured
          .single as RegisterRequest;
      expect(request.email, 'a@b.com');
      expect(request.password, 'pw');
      expect(request.verificationUrl, 'https://app/verify');
    });

    test('Error result passes through', () async {
      final exception = Exception('register failed');
      when(() => mockApiClient.register(any()))
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.register(
        email: 'a@b.com',
        password: 'pw',
        verificationUrl: 'https://app/verify',
      );

      expect((result as Error<void>).error, exception);
    });
  });

  group('requestPasswordReset', () {
    test('maps verificationUrl to resetUrl and returns Ok(null)', () async {
      when(() => mockApiClient.requestPasswordReset(any()))
          .thenAnswer((_) async => const Result.ok(null));

      final result = await repository.requestPasswordReset(
        email: 'a@b.com',
        verificationUrl: 'https://app/reset',
      );

      expect(result, isA<Ok<void>>());
      final request =
          verify(() => mockApiClient.requestPasswordReset(captureAny()))
              .captured
              .single as PasswordResetRequest;
      expect(request.email, 'a@b.com');
      expect(request.resetUrl, 'https://app/reset');
    });

    test('Error result passes through', () async {
      final exception = Exception('password reset failed');
      when(() => mockApiClient.requestPasswordReset(any()))
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.requestPasswordReset(
        email: 'a@b.com',
        verificationUrl: 'https://app/reset',
      );

      expect((result as Error<void>).error, exception);
    });
  });

  group('resetPassword', () {
    test('Ok result returns Ok(null) with mapped request fields', () async {
      when(() => mockApiClient.resetPassword(any())).thenAnswer((_) async =>
          const Result.ok(ResetPasswordResponse(message: 'done')));

      final result = await repository.resetPassword(
        userId: 'user-1',
        token: 'reset-token',
        newPassword: 'newpw',
      );

      expect(result, isA<Ok<void>>());
      final request = verify(() => mockApiClient.resetPassword(captureAny()))
          .captured
          .single as ResetPasswordRequest;
      expect(request.userId, 'user-1');
      expect(request.token, 'reset-token');
      expect(request.newPassword, 'newpw');
    });

    test('Error result passes through', () async {
      final exception = Exception('reset password failed');
      when(() => mockApiClient.resetPassword(any()))
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.resetPassword(
        userId: 'user-1',
        token: 'reset-token',
        newPassword: 'newpw',
      );

      expect((result as Error<void>).error, exception);
    });
  });

  group('verifyEmail', () {
    test('Ok result returns Ok(null) with mapped request fields', () async {
      when(() => mockApiClient.verifyEmail(any()))
          .thenAnswer((_) async => const Result.ok(null));

      final result = await repository.verifyEmail(
        email: 'a@b.com',
        verificationUrl: 'https://app/verify',
      );

      expect(result, isA<Ok<void>>());
      final request = verify(() => mockApiClient.verifyEmail(captureAny()))
          .captured
          .single as VerifyEmailRequest;
      expect(request.email, 'a@b.com');
      expect(request.verificationUrl, 'https://app/verify');
    });

    test('Error result passes through', () async {
      final exception = Exception('verify email failed');
      when(() => mockApiClient.verifyEmail(any()))
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.verifyEmail(
        email: 'a@b.com',
        verificationUrl: 'https://app/verify',
      );

      expect((result as Error<void>).error, exception);
    });
  });

  group('changePassword', () {
    test('discards the response and returns Ok(null) on success', () async {
      when(() => mockApiClient.changePassword(any())).thenAnswer((_) async =>
          const Result.ok(ChangePasswordResponse(message: 'changed')));

      final result = await repository.changePassword(
        oldPassword: 'old',
        newPassword: 'new',
      );

      expect(result, isA<Ok<void>>());
      final request = verify(() => mockApiClient.changePassword(captureAny()))
          .captured
          .single as ChangePasswordRequest;
      expect(request.oldPassword, 'old');
      expect(request.newPassword, 'new');
    });

    test('Error result passes through', () async {
      final exception = Exception('change password failed');
      when(() => mockApiClient.changePassword(any()))
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.changePassword(
        oldPassword: 'old',
        newPassword: 'new',
      );

      expect((result as Error<void>).error, exception);
    });
  });

  group('checkPasswordStrength', () {
    test('Ok result returns Ok(isStrong)', () async {
      when(() => mockApiClient.checkPasswordStrength(any())).thenAnswer(
          (_) async => const Result.ok(
              CheckPasswordStrengthResponse(isStrong: true, message: 'strong')));

      final result = await repository.checkPasswordStrength(password: 'pw');

      expect((result as Ok<bool>).value, isTrue);
      final request =
          verify(() => mockApiClient.checkPasswordStrength(captureAny()))
              .captured
              .single as CheckPasswordStrengthRequest;
      expect(request.password, 'pw');
    });

    test('Error result passes through', () async {
      final exception = Exception('check password strength failed');
      when(() => mockApiClient.checkPasswordStrength(any()))
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.checkPasswordStrength(password: 'pw');

      expect((result as Error<bool>).error, exception);
    });
  });

  group('me', () {
    test('maps a null email to an empty string', () async {
      when(() => mockApiClient.me()).thenAnswer((_) async => Result.ok(
          MeResponse(userId: 'user-1', email: null, emailVerified: false)));

      final result = await repository.me();

      final user = (result as Ok<User>).value;
      expect(user.id, 'user-1');
      expect(user.email, '');
      expect(user.isVerified, isFalse);
      expect(user.isAdmin, isNull);
      expect(user.accountType, isNull);
    });

    test('maps a non-null email and isVerified through', () async {
      when(() => mockApiClient.me()).thenAnswer((_) async => Result.ok(
          MeResponse(userId: 'user-1', email: 'a@b.com', emailVerified: true)));

      final result = await repository.me();

      final user = (result as Ok<User>).value;
      expect(user.email, 'a@b.com');
      expect(user.isVerified, isTrue);
    });

    test('Error result passes through', () async {
      final exception = Exception('me failed');
      when(() => mockApiClient.me())
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.me();

      expect((result as Error<User>).error, exception);
    });
  });

  group('whoAmI', () {
    test('maps all fields 1:1, including isAdmin and accountType', () async {
      when(() => mockApiClient.whoAmI()).thenAnswer((_) async => const Result.ok(
          WhoAmIResponse(
              userId: 'user-1',
              email: 'a@b.com',
              isVerified: true,
              isAdmin: true,
              accountType: 'premium')));

      final result = await repository.whoAmI();

      final user = (result as Ok<User>).value;
      expect(user.id, 'user-1');
      expect(user.email, 'a@b.com');
      expect(user.isVerified, isTrue);
      expect(user.isAdmin, isTrue);
      expect(user.accountType, 'premium');
    });

    test('Error result passes through', () async {
      final exception = Exception('whoAmI failed');
      when(() => mockApiClient.whoAmI())
          .thenAnswer((_) async => Result.error(exception));

      final result = await repository.whoAmI();

      expect((result as Error<User>).error, exception);
    });
  });
}
