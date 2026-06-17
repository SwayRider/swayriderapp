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

/// Thrown when an authenticated request is rejected because the access token
/// is missing, expired, or otherwise invalid (HTTP 401).
class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => 'Not authenticated';
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

  static const _requestTimeout = Duration(seconds: 10);

  HttpClient _newClient() => _clientFactory()
    ..connectionTimeout = _requestTimeout;

  // Covers DNS resolution + TCP connect + response with a single timeout budget.
  Future<HttpClientRequest> _get(HttpClient client, String path) =>
      client.getUrl(_uri(path)).timeout(_requestTimeout);

  Future<HttpClientRequest> _post(HttpClient client, String path) =>
      client.postUrl(_uri(path)).timeout(_requestTimeout);

  Future<HttpClientResponse> _close(HttpClientRequest request) =>
      request.close().timeout(_requestTimeout);

  String _fullPath(String path) => '$_pathPrefix$path';

  Uri _uri(String path) => Uri(
    scheme: _scheme,
    host: _host,
    port: _port,
    path: _fullPath(path),
  );

  Future<Result<LoginResponse>> login(LoginRequest req) async {
    final client = _newClient();
    try {
      final request = await _post(client, '/login');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await _close(request);
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
    final client = _newClient();
    try {
      final request = await _post(client, '/register');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await _close(request);
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
    final client = _newClient();
    try {
      final request = await _post(client, '/refresh');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await _close(request);
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
    final client = _newClient();
    try {
      final request = await _post(client, '/logout');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await _close(request);
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
    final client = _newClient();
    try {
      final request = await _post(client, '/request-password-reset');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await _close(request);
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
    final client = _newClient();
    try {
      final request = await _post(client, '/reset-password');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await _close(request);
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
    final client = _newClient();
    try {
      final request = await _post(client, '/verify-email');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await _close(request);
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
    final client = _newClient();
    try {
      final request = await _post(client, '/change-password');
      await _authHeader(request.headers);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await _close(request);
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
    final client = _newClient();
    try {
      final request = await _post(client, '/check-password-strength');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(req));
      final response = await _close(request);
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
    final client = _newClient();
    try {
      final request = await _get(client, '/whoami');
      await _authHeader(request.headers);
      final response = await _close(request);
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(WhoAmIResponse.fromJson(jsonDecode(stringData)));
      } else if (response.statusCode == 401) {
        return const Result.error(UnauthorizedException());
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
    final client = _newClient();
    try {
      final request = await _get(client, '/me');
      await _authHeader(request.headers);
      final response = await _close(request);
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(MeResponse.fromJson(jsonDecode(stringData)));
      } else if (response.statusCode == 401) {
        return const Result.error(UnauthorizedException());
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
    final client = _newClient();
    try {
      final request = await _get(client, '/public-keys');
      final response = await _close(request);
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
