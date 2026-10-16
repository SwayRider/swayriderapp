import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayriderapp/data/repositories/tiles/tiles_repository_remote.dart';
import 'package:swayriderapp/data/services/api/tiles_api_client.dart';
import 'package:swayriderapp/data/services/tile_cache.dart';
import 'package:swayriderapp/data/services/api/unauthorized_exception.dart';
import 'package:swayriderapp/utils/result.dart';

import '../../../helpers/mocks.dart';

void main() {
  const origin = 'http://127.0.0.1:54321';

  test(
    'getMapStyle routes the api call through authRepository.withAuthRetry',
    () async {
      final mockApiClient = MockTilesApiClient();
      final mockAuthRepository = MockAuthRepository();
      when(
        () => mockApiClient.authHeaderProvider = any(),
      ).thenReturn(() => null);
      when(() => mockAuthRepository.authHeaderProvider).thenReturn(() => null);
      when(
        () => mockApiClient.getStyle(any()),
      ).thenAnswer((_) async => const Result.error(UnauthorizedException()));
      when(
        () => mockAuthRepository.withAuthRetry<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (invocation) =>
            (invocation.positionalArguments.single
                as Future<Result<Map<String, dynamic>>> Function())(),
      );

      final repository = TilesRepositoryRemote(
        tilesApiClient: mockApiClient,
        authRepository: mockAuthRepository,
        tilesBaseUrl: Uri.parse('http://localhost:8080'),
      );

      final result = await repository.getMapStyle(name: 'light');

      expect(result, isA<Error<String>>());
      expect((result as Error<String>).error, isA<UnauthorizedException>());
      verify(
        () => mockAuthRepository.withAuthRetry<Map<String, dynamic>>(any()),
      ).called(1);
    },
  );

  test('rewrites tile source URLs to the local proxy origin', () {
    final style = {
      'sources': {
        'swayrider': {
          'type': 'vector',
          'tiles': [
            'https://api.swayrider-dev.hevanto-it.com/v1/tiles/base/{z}/{x}/{y}',
          ],
        },
      },
    };

    final rewritten = TilesRepositoryRemote.rewriteTileUrls(style, origin);

    expect(
      rewritten['sources']['swayrider']['tiles'][0],
      '$origin/v1/tiles/base/{z}/{x}/{y}',
    );
  });

  test('rewrites a sprite URL under /v1/tiles/', () {
    final style = {
      'sprite':
          'https://api.swayrider-dev.hevanto-it.com/v1/tiles/sprites/light',
    };

    final rewritten = TilesRepositoryRemote.rewriteTileUrls(style, origin);

    expect(rewritten['sprite'], '$origin/v1/tiles/sprites/light');
  });

  test('leaves URLs without /v1/tiles/ untouched', () {
    final style = {
      'glyphs': 'https://fonts.openmaptiles.org/{fontstack}/{range}.pbf',
    };

    final rewritten = TilesRepositoryRemote.rewriteTileUrls(style, origin);

    expect(rewritten['glyphs'], style['glyphs']);
  });

  test('leaves non-string values untouched', () {
    final style = {'version': 8, 'enabled': true, 'meta': null};

    final rewritten = TilesRepositoryRemote.rewriteTileUrls(style, origin);

    expect(rewritten, style);
  });

  test('rewrites the glyph and sprite URLs of a planet style', () {
    final style = {
      'glyphs':
          'https://api.swayrider-dev.hevanto-it.com:443/v1/tiles/fonts/{fontstack}/{range}.pbf',
      'sprite':
          'https://api.swayrider-dev.hevanto-it.com:443/v1/tiles/sprites/light',
      'sources': {
        'p': {
          'tiles': [
            'https://api.swayrider-dev.hevanto-it.com:443/v1/tiles/planet/{z}/{x}/{y}',
          ],
        },
      },
    };

    final rewritten = TilesRepositoryRemote.rewriteTileUrls(style, origin);

    expect(
      rewritten['glyphs'],
      '$origin/v1/tiles/fonts/{fontstack}/{range}.pbf',
    );
    expect(rewritten['sprite'], '$origin/v1/tiles/sprites/light');
    expect(
      rewritten['sources']['p']['tiles'][0],
      '$origin/v1/tiles/planet/{z}/{x}/{y}',
    );
  });

  group('loopback proxy', () {
    late _FakeBackend backend;
    late TilesRepositoryRemote repository;
    late String proxy;

    setUp(() async {
      HttpOverrides.global =
          null; // flutter_test would answer 400 to real sockets
      backend = await _FakeBackend.start();
      final mockApiClient = MockTilesApiClient();
      final mockAuthRepository = MockAuthRepository();
      when(
        () => mockApiClient.authHeaderProvider = any(),
      ).thenReturn(() => null);
      when(
        () => mockAuthRepository.authHeaderProvider,
      ).thenReturn(() => 'Bearer test-token');
      when(() => mockApiClient.getStyle(any())).thenAnswer(
        (_) async => const Result.ok({
          'sprite': 'https://api.example.com/v1/tiles/sprites/light',
        }),
      );
      when(
        () => mockAuthRepository.withAuthRetry<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (invocation) =>
            (invocation.positionalArguments.single
                as Future<Result<Map<String, dynamic>>> Function())(),
      );
      repository = TilesRepositoryRemote(
        tilesApiClient: mockApiClient,
        authRepository: mockAuthRepository,
        tilesBaseUrl: Uri(
          scheme: 'http',
          host: '127.0.0.1',
          port: backend.port,
        ),
      );
      final result = await repository.getMapStyle(name: 'swayrider/light');
      final sprite =
          (jsonDecode((result as Ok<String>).value) as Map)['sprite'] as String;
      proxy = sprite.substring(0, sprite.indexOf('/v1/tiles/'));
    });

    tearDown(() async {
      await repository.close();
      await backend.close();
    });

    Future<({int status, List<int> body, HttpHeaders headers})> request(
      String path, {
      String method = 'GET',
    }) async {
      final client = HttpClient();
      try {
        final req = await client.openUrl(method, Uri.parse('$proxy$path'));
        final res = await req.close();
        final body = await res.fold<List<int>>([], (a, b) => a..addAll(b));
        return (status: res.statusCode, body: body, headers: res.headers);
      } finally {
        client.close(force: true);
      }
    }

    test(
      'forwards a tile with the bearer token and decodes its gzip',
      () async {
        final res = await request('/v1/tiles/planet/1/0/0');

        expect(res.status, 200);
        expect(utf8.decode(res.body), 'tile-bytes');
        // the body is already decoded, so the header must not claim gzip
        expect(res.headers.value(HttpHeaders.contentEncodingHeader), isNull);
        expect(backend.requests.single.auth, 'Bearer test-token');
        expect(backend.requests.single.path, '/v1/tiles/planet/1/0/0');
      },
    );

    test('passes 204, 304 and 404 through', () async {
      expect((await request('/v1/tiles/planet/2/0/0')).status, 204);
      expect((await request('/v1/tiles/planet/3/0/0')).status, 304);
      expect((await request('/v1/tiles/planet/4/0/0')).status, 404);
    });

    test('only a 200 tile is cached', () async {
      final puts = <String>[];
      final mockAuth = MockAuthRepository();
      when(() => mockAuth.authHeaderProvider).thenReturn(() => 'Bearer t');
      final cache = _RecordingCache(puts);
      final cached = TilesRepositoryRemote(
        tilesApiClient: _styleClient(),
        authRepository: mockAuth,
        tilesBaseUrl: Uri(
          scheme: 'http',
          host: '127.0.0.1',
          port: backend.port,
        ),
        tileCache: cache,
      );
      addTearDown(cached.close);
      when(
        () => mockAuth.withAuthRetry<Map<String, dynamic>>(any()),
      ).thenAnswer(
        (i) =>
            (i.positionalArguments.single
                as Future<Result<Map<String, dynamic>>> Function())(),
      );
      final style = await cached.getMapStyle(name: 'x');
      final sprite =
          (jsonDecode((style as Ok<String>).value) as Map)['sprite'] as String;
      final base = sprite.substring(0, sprite.indexOf('/v1/tiles/'));

      for (final path in [
        '/v1/tiles/planet/2/0/0', // 204
        '/v1/tiles/planet/3/0/0', // 304
        '/v1/tiles/planet/4/0/0', // 404
        '/v1/tiles/planet/1/0/0', // 200
      ]) {
        final client = HttpClient();
        final res = await (await client.getUrl(
          Uri.parse('$base$path'),
        )).close();
        await res.drain<void>();
        client.close(force: true);
      }

      expect(puts, ['planet/1/0/0=tile-bytes']);
    });

    test('forwards glyph ranges and sprite sheets with the token', () async {
      final glyphs = await request(
        '/v1/tiles/fonts/Noto%20Sans%20Regular/0-255.pbf',
      );
      expect(glyphs.status, 200);
      expect(utf8.decode(glyphs.body), 'glyph-bytes');

      final sprite = await request('/v1/tiles/sprites/light@2x.json');
      expect(sprite.status, 200);
      expect(utf8.decode(sprite.body), '{"sprite":true}');

      expect(
        backend.requests.map((r) => r.auth),
        everyElement('Bearer test-token'),
      );
    });

    test('refuses everything else without reaching the backend', () async {
      for (final path in [
        '/v1/tiles/styles/swayrider/light',
        '/v1/tiles/ready',
        '/api/v1/auth/me',
        '/v1/tiles/fonts/../0-255.pbf',
        '/v1/tiles/fonts/Noto%20Sans/manifest.pbf',
        '/v1/tiles/sprites/../x.json',
        '/v1/tiles/sprites/light.svg',
        '/v1/tiles/planet/1/0',
        '/v1/tiles/pla.net/1/0/0',
        '/',
      ]) {
        expect((await request(path)).status, 404, reason: path);
      }
      expect(backend.requests, isEmpty);
    });

    test('refuses methods other than GET and HEAD', () async {
      expect(
        (await request('/v1/tiles/planet/1/0/0', method: 'POST')).status,
        405,
      );
      expect(
        (await request('/v1/tiles/planet/1/0/0', method: 'DELETE')).status,
        405,
      );
      expect(backend.requests, isEmpty);
    });
  });
}

TilesApiClient _styleClient() {
  final client = MockTilesApiClient();
  when(() => client.authHeaderProvider = any()).thenReturn(() => null);
  when(() => client.getStyle(any())).thenAnswer(
    (_) async => const Result.ok({
      'sprite': 'https://api.example.com/v1/tiles/sprites/light',
    }),
  );
  return client;
}

class _RecordingCache implements TileCache {
  _RecordingCache(this.puts);

  final List<String> puts;

  @override
  Future<Uint8List?> get(String tileset, int z, int x, int y) async => null;

  @override
  Future<void> put(String tileset, int z, int x, int y, Uint8List bytes) async {
    puts.add('$tileset/$z/$x/$y=${utf8.decode(bytes)}');
  }
}

typedef _Seen = ({String method, String path, String? auth});

/// A stand-in for the tiles backend: gzip tiles, empty/not-modified/missing
/// tiles, a glyph range and a sprite. Any other path answers 200 "LEAK", so a
/// request that should have been refused by the proxy shows up in [requests].
class _FakeBackend {
  _FakeBackend._(this._server) {
    _server.listen((request) async {
      final path = request.uri.path;
      requests.add((
        method: request.method,
        path: path,
        auth: request.headers.value(HttpHeaders.authorizationHeader),
      ));
      final res = request.response;
      switch (path) {
        case '/v1/tiles/planet/1/0/0':
          res.headers
            ..set(
              HttpHeaders.contentTypeHeader,
              'application/vnd.mapbox-vector-tile',
            )
            ..set(HttpHeaders.contentEncodingHeader, 'gzip');
          res.add(gzip.encode(utf8.encode('tile-bytes')));
        case '/v1/tiles/planet/2/0/0':
          res.statusCode = HttpStatus.noContent;
        case '/v1/tiles/planet/3/0/0':
          res.statusCode = HttpStatus.notModified;
        case '/v1/tiles/planet/4/0/0':
          res.statusCode = HttpStatus.notFound;
        case '/v1/tiles/fonts/Noto%20Sans%20Regular/0-255.pbf':
          res.add(utf8.encode('glyph-bytes'));
        case '/v1/tiles/sprites/light@2x.json':
          res.add(utf8.encode('{"sprite":true}'));
        default:
          res.add(utf8.encode('LEAK'));
      }
      await res.close();
    });
  }

  static Future<_FakeBackend> start() async =>
      _FakeBackend._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _server;
  final requests = <_Seen>[];

  int get port => _server.port;

  Future<void> close() => _server.close(force: true);
}
