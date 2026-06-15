import 'dart:convert';
import 'dart:io';

import 'auth_header_provider.dart';
import '../../../utils/result.dart';

class TilesApiClient {
  TilesApiClient({
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

  Uri _uri(String path) => Uri(
    scheme: _scheme,
    host: _host,
    port: _port,
    path: '$_pathPrefix$path',
  );

  Future<Result<Map<String, dynamic>>> getStyle(String name) async {
    final client = _clientFactory();
    try {
      final request = await client.getUrl(_uri('/styles/$name'));
      await _authHeader(request.headers);
      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        return Result.ok(jsonDecode(stringData) as Map<String, dynamic>);
      } else {
        return const Result.error(HttpException("Get style error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }
}
