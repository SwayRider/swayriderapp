import 'dart:convert';
import 'dart:io';

import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import 'auth_header_provider.dart';
import 'model/search/search_result_item.dart';
import '../../../utils/result.dart';

class SearchApiClient {
  SearchApiClient({
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

  HttpClient _newClient() => _clientFactory()..connectionTimeout = _requestTimeout;

  Future<HttpClientRequest> _post(HttpClient client, String path) =>
      client.postUrl(_uri(path)).timeout(_requestTimeout);

  Future<HttpClientResponse> _close(HttpClientRequest request) =>
      request.close().timeout(_requestTimeout);

  Uri _uri(String path) => Uri(
        scheme: _scheme,
        host: _host,
        port: _port,
        path: '$_pathPrefix$path',
      );

  Future<Result<List<SearchResultItem>>> autocomplete({
    required String text,
    required LatLng focusPoint,
    int size = 10,
    String language = 'en',
  }) async {
    final client = _newClient();
    try {
      final request = await _post(client, '/search/autocomplete');
      await _authHeader(request.headers);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'text': text,
        'focusPoint': {'lat': focusPoint.latitude, 'lon': focusPoint.longitude},
        'size': size,
        'language': language,
      }));
      final response = await _close(request);
      final stringData = await response.transform(utf8.decoder).join();
      if (response.statusCode == 200) {
        final items = jsonDecode(stringData) as List<dynamic>;
        return Result.ok(items
            .map((item) => SearchResultItem.fromJson(item as Map<String, dynamic>))
            .toList());
      } else {
        return const Result.error(HttpException("Autocomplete error"));
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }
}
