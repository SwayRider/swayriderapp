import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_proxy/shelf_proxy.dart' as shelf_proxy;

import '../../../utils/result.dart';
import '../../services/api/tiles_api_client.dart';
import '../../services/tile_cache.dart';
import '../auth/auth_repository.dart';
import 'tiles_repository.dart';

/// [TilesRepository] backed by [TilesApiClient].
///
/// The tiles backend requires a bearer token on *every* request, including
/// individual MVT tile fetches — but MapLibre's native renderer fetches
/// tiles itself and has no hook for custom headers. To bridge this, this
/// repository runs a small local loopback HTTP server: [getMapStyle] fetches
/// the style JSON itself (where the auth header can be attached normally)
/// and rewrites its tile/sprite/glyph URLs to point at that local server,
/// which then forwards each request to the real tiles backend with the
/// user's current bearer token injected. MapLibre only ever talks to
/// `127.0.0.1`.
class TilesRepositoryRemote implements TilesRepository {
  TilesRepositoryRemote({
    required this._tilesApiClient,
    required this._authRepository,
    required this._tilesBaseUrl,
    TileCache? tileCache,
  }) : _tileCache = tileCache ?? NoopTileCache() {
    _tilesApiClient.authHeaderProvider = _authRepository.authHeaderProvider;
    _proxyHandler = shelf_proxy.proxyHandler(_tilesBaseUrl);
  }

  /// Matches `/v1/tiles/{tileset}/{z}/{x}/{y}` requests, with or without a
  /// leading slash.
  static final _tilePathRegExp = RegExp(
    r'^/?v1/tiles/([^/]+)/(\d+)/(\d+)/(\d+)$',
  );

  /// Marks where, in any style JSON string value, the tiles API path begins.
  static const _tilesPathMarker = '/v1/tiles/';

  static const _mvtContentType = 'application/vnd.mapbox-vector-tile';

  final TilesApiClient _tilesApiClient;
  final AuthRepository _authRepository;
  final Uri _tilesBaseUrl;
  final TileCache _tileCache;

  late final shelf.Handler _proxyHandler;
  Future<HttpServer>? _proxyServer;

  Future<HttpServer> _ensureProxyServer() =>
      _proxyServer ??= shelf_io.serve(
        _handleRequest,
        InternetAddress.loopbackIPv4,
        0,
      );

  @override
  Future<Result<String>> getMapStyle({required String name}) async {
    final styleResult = await _tilesApiClient.getStyle(name);
    switch (styleResult) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        final server = await _ensureProxyServer();
        final origin = 'http://127.0.0.1:${server.port}';
        return Result.ok(jsonEncode(rewriteTileUrls(value, origin)));
    }
  }

  /// Stops the local proxy server, if it was started.
  @override
  Future<void> close() async {
    final serverFuture = _proxyServer;
    if (serverFuture == null) return;
    _proxyServer = null;
    await (await serverFuture).close(force: true);
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    final match = _tilePathRegExp.firstMatch(request.url.path);
    if (match == null) {
      return _forward(request);
    }

    final tileset = match.group(1)!;
    final z = int.parse(match.group(2)!);
    final x = int.parse(match.group(3)!);
    final y = int.parse(match.group(4)!);

    final cached = await _tileCache.get(tileset, z, x, y);
    if (cached != null) {
      return shelf.Response.ok(
        cached,
        headers: {HttpHeaders.contentTypeHeader: _mvtContentType},
      );
    }

    final response = await _forward(request);
    if (response.statusCode == 200) {
      final bytes = Uint8List.fromList(
        (await response.read().toList()).expand((chunk) => chunk).toList(),
      );
      await _tileCache.put(tileset, z, x, y, bytes);
      return response.change(body: bytes);
    }
    return response;
  }

  Future<shelf.Response> _forward(shelf.Request request) async {
    final authHeader = _authRepository.authHeaderProvider();
    final forwarded = authHeader == null
        ? request
        : request.change(
            headers: {HttpHeaders.authorizationHeader: authHeader},
          );
    return _proxyHandler(forwarded);
  }

  /// Recursively walks [json], rewriting any string value that contains
  /// [_tilesPathMarker] by replacing everything up to and including that
  /// marker with [origin].
  ///
  /// For example, with `origin = 'http://127.0.0.1:54321'`, the string
  /// `https://api.example.com/v1/tiles/base/{z}/{x}/{y}` becomes
  /// `http://127.0.0.1:54321/v1/tiles/base/{z}/{x}/{y}`. This is path-based
  /// so it works regardless of the configured gateway host/port. Strings
  /// without [_tilesPathMarker] — e.g. the public glyphs CDN URL — are left
  /// untouched.
  static dynamic rewriteTileUrls(dynamic json, String origin) {
    switch (json) {
      case Map<String, dynamic>():
        return json.map(
          (key, value) => MapEntry(key, rewriteTileUrls(value, origin)),
        );
      case List():
        return json.map((value) => rewriteTileUrls(value, origin)).toList();
      case String():
        final index = json.indexOf(_tilesPathMarker);
        if (index == -1) return json;
        return '$origin${json.substring(index)}';
      default:
        return json;
    }
  }
}
