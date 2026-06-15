import 'dart:convert';
import 'dart:io';

import 'package:swayriderapp/data/services/api/auth_header_provider.dart';

import 'model/auth/auth.dart';
import '../../../utils/result.dart';

/// Thrown when [AuthApiClient.register] fails because the backend is
/// invitation-only and the given email has no invitation (HTTP 403).
class InvitationRequiredException implements Exception {
  const InvitationRequiredException();

  @override
  String toString() => 'An invitation is required to register';
}

/// Thrown when [AuthApiClient.register] fails because the password does not
/// meet the backend's strength requirements (HTTP 400).
class WeakPasswordException implements Exception {
  const WeakPasswordException();

  @override
  String toString() => 'Password is not strong enough';
}

class AuthApiClient {
  AuthApiClient({
    String? scheme,
    String? host,
    int? port,
    String? pathPrefix,
    HttpClient Function()? clientFactory,
  })  : _scheme = scheme ?? 'http',
        _host = host ?? 'localhost',
        _port = port ?? 8080,
        _pathPrefix = pathPrefix ?? '',
        _clientFactory = clientFactory ?? HttpClient.new;

  final String _scheme;
  final String _host;
  final int _port;
  final String _pathPrefix;
  final HttpClient Function() _clientFactory;

  AuthHeaderProvider? _authHeaderProvider;

  set authHeaderProvider(AuthHeaderProvider authHeaderProvider) =>
    _authHeaderProvider = authHeaderProvider;

  Future<void> _authHeader(HttpHeaders headers) async {
    final header = _authHeaderProvider?.call();
    if (header != null) {
      headers.add(HttpHeaders.authorizationHeader, header);
    }
  }

  String _fullPath(String path) => '$_pathPrefix$path';

  Uri _uri(String path) => Uri(
    scheme: _scheme,
    host: _host,
    port: _port,
    path: _fullPath(path),
  );

  Future<Result<LoginResponse>> login(LoginRequest req) async {
    final client = _clientFactory();
    try {
      final request = await client.postUrl(_uri('/login'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(LoginResponse.fromJson(jsonDecode(stringData)));
      } else {
        return const Result.error(HttpException("Login error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<RegisterResponse>> register(RegisterRequest req) async {
    final client = _clientFactory();
    try {
      final request = await client.postUrl(_uri('/register'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(RegisterResponse.fromJson(jsonDecode(stringData)));
      } else if (response.statusCode == 403) {
        return const Result.error(InvitationRequiredException());
      } else {
        final stringData = await response.transform(utf8.decoder).join();
        if (response.statusCode == 400 &&
            stringData.contains('password is too weak')) {
          return const Result.error(WeakPasswordException());
        }
        return const Result.error(HttpException("Register error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<RefreshResponse>> refresh(RefreshRequest req) async {
    final client = _clientFactory();
    try {
      final request = await client.postUrl(_uri('/refresh'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(RefreshResponse.fromJson(jsonDecode(stringData)));
      } else {
        return const Result.error(HttpException("Refresh error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<void>> logout(LogoutRequest req) async {
    final client = _clientFactory();
    try {
      final request = await client.postUrl(_uri('/logout'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await request.close();
      if (response.statusCode == 200) {
        return const Result.ok(null);
      } else {
        return const Result.error(HttpException("Logout error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<void>> requestPasswordReset(PasswordResetRequest req) async {
    final client = _clientFactory();
    try {
      final request = await client.postUrl(_uri('/request-password-reset'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await request.close();
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Result.ok(null);
      } else {
        return const Result.error(HttpException("Password reset error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<ResetPasswordResponse>> resetPassword(ResetPasswordRequest req) async {
    final client = _clientFactory();
    try {
      final request = await client.postUrl(_uri('/reset-password'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(ResetPasswordResponse.fromJson(jsonDecode(stringData)));
      } else {
        return const Result.error(HttpException("Reset password error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<void>> verifyEmail(VerifyEmailRequest req) async {
    final client = _clientFactory();
    try {
      final request = await client.postUrl(_uri('/verify-email'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await request.close();
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Result.ok(null);
      } else {
        return const Result.error(HttpException("Verify email error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<ChangePasswordResponse>> changePassword(ChangePasswordRequest req) async {
    final client = _clientFactory();
    try {
      final request = await client.postUrl(_uri('/change-password'));
      await _authHeader(request.headers);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(ChangePasswordResponse.fromJson(jsonDecode(stringData)));
      } else {
        return const Result.error(HttpException("Change password error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<CheckPasswordStrengthResponse>> checkPasswordStrength(CheckPasswordStrengthRequest req) async {
    final client = _clientFactory();
    try {
      final request = await client.postUrl(_uri('/check-password-strength'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(CheckPasswordStrengthResponse.fromJson(jsonDecode(stringData)));
      } else {
        return const Result.error(HttpException("Check password strength error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<WhoAmIResponse>> whoAmI() async {
    final client = _clientFactory();
    try {
      final request = await client.getUrl(_uri('/whoami'));
      await _authHeader(request.headers);
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(WhoAmIResponse.fromJson(jsonDecode(stringData)));
      } else {
        return const Result.error(HttpException("Who am I error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<MeResponse>> me() async {
    final client = _clientFactory();
    try {
      final request = await client.getUrl(_uri('/me'));
      await _authHeader(request.headers);
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(MeResponse.fromJson(jsonDecode(stringData)));
      } else {
        return const Result.error(HttpException("Me error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  Future<Result<PublicKeysResponse>> publicKeys() async {
    final client = _clientFactory();
    try {
      final request = await client.getUrl(_uri('/public-keys'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(PublicKeysResponse.fromJson(jsonDecode(stringData)));
      } else {
        return const Result.error(HttpException("Public keys error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }
}