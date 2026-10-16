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
    r'^/?v1/tiles/([A-Za-z0-9_-]+)/(\d+)/(\d+)/(\d+)$',
  );

  /// Matches glyph ranges, `/v1/tiles/fonts/{fontstack}/{start}-{end}.pbf`.
  /// The font stack stays percent-encoded in the path (`Noto%20Sans%20Regular`).
  static final _glyphPathRegExp = RegExp(
    r'^/?v1/tiles/fonts/[A-Za-z0-9%_,()+-]+/\d+-\d+\.pbf$',
  );

  /// Matches sprite sheets, `/v1/tiles/sprites/{name}[@2x].{json,png}`.
  static final _spritePathRegExp = RegExp(
    r'^/?v1/tiles/sprites/[A-Za-z0-9_-]+(@2x)?\.(json|png)$',
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

  Future<HttpServer> _ensureProxyServer() => _proxyServer ??= shelf_io.serve(
    _handleRequest,
    InternetAddress.loopbackIPv4,
    0,
  );

  @override
  Future<Result<String>> getMapStyle({required String name}) async {
    final styleResult = await _authRepository.withAuthRetry(
      () => _tilesApiClient.getStyle(name),
    );
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

  /// Serves only what MapLibre fetches by itself: tiles, glyph ranges and
  /// sprites, with GET/HEAD. The style is fetched by [getMapStyle], never
  /// through here. Anything else is refused, so other apps on the device
  /// cannot use this loopback server to make authenticated requests for
  /// arbitrary backend paths.
  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    if (request.method != 'GET' && request.method != 'HEAD') {
      return shelf.Response(HttpStatus.methodNotAllowed);
    }
    final path = request.url.path;
    final match = _tilePathRegExp.firstMatch(path);
    if (match == null) {
      if (_glyphPathRegExp.hasMatch(path) || _spritePathRegExp.hasMatch(path)) {
        return _forward(request);
      }
      return shelf.Response.notFound('Not found');
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

    // shelf_proxy hands back decoded bytes (it gunzips the backend's
    // `Content-Encoding: gzip` tiles and drops that header), so the bytes
    // cached below match the plain MVT served on a cache hit.
    // Only a 200 is cached: 204 (no tile, MapLibre over-zooms) and 304 pass
    // through untouched.
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

  /// Forwards [request] to the backend with the current bearer token. When the
  /// backend answers 401 the access token has expired (the proxy is the only
  /// thing talking to the server during a long ride, so nothing else would
  /// refresh it): refresh it once and retry.
  Future<shelf.Response> _forward(shelf.Request request) async {
    final usedAuth = _authRepository.authHeaderProvider();
    final response = await _proxyHandler(_withAuth(request, usedAuth));
    if (response.statusCode != HttpStatus.unauthorized) return response;

    if (!await _refreshAccessToken(usedAuth)) return response;
    await response.read().drain<void>();
    return _proxyHandler(
      _withAuth(request, _authRepository.authHeaderProvider()),
    );
  }

  /// A fresh copy of [request] carrying [authHeader]: a shelf request body
  /// can only be read once, so each attempt needs its own request. Only
  /// body-less GET/HEAD requests get here.
  shelf.Request _withAuth(shelf.Request request, String? authHeader) =>
      shelf.Request(
        request.method,
        request.requestedUri,
        protocolVersion: request.protocolVersion,
        headers: {
          ...request.headers,
          HttpHeaders.authorizationHeader: ?authHeader,
        },
        handlerPath: request.handlerPath,
        url: request.url,
        context: request.context,
      );

  /// A refresh that finished less than this long ago is not repeated: if the
  /// backend still answers 401 with a fresh token, refreshing again won't help
  /// (e.g. the token lacks access), and each refresh rotates the single-use
  /// refresh token.
  static const _refreshCooldown = Duration(seconds: 30);

  Future<bool>? _refreshInFlight;
  DateTime? _lastRefreshAt;

  /// Returns whether a retry is worthwhile: the token was just refreshed,
  /// either by this call, by another tile request that got there first, or by
  /// anything else since [rejectedAuth] was sent. All concurrent tile
  /// requests share one refresh, because MapLibre fetches dozens of tiles at
  /// once and refresh tokens are single-use.
  ///
  /// A failed refresh (e.g. an invalid refresh token) is left to the normal
  /// API calls, whose `withAuthRetry` signs the user out.
  Future<bool> _refreshAccessToken(String? rejectedAuth) {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    if (_authRepository.authHeaderProvider() != rejectedAuth) {
      return Future.value(true); // already refreshed since the request left
    }
    final last = _lastRefreshAt;
    if (last != null && DateTime.now().difference(last) < _refreshCooldown) {
      return Future.value(false);
    }
    return _refreshInFlight = _authRepository
        .refresh()
        .then((result) {
          _lastRefreshAt = DateTime.now();
          return result is Ok<void>;
        })
        .onError<Object>((_, _) => false)
        .whenComplete(() => _refreshInFlight = null);
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
