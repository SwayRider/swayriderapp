import 'dart:convert';
import 'dart:io';

import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../utils/polyline_codec.dart';
import '../../../utils/result.dart';
import 'auth_header_provider.dart';
import 'unauthorized_exception.dart';

class RouterApiClient {
  RouterApiClient({
    String? scheme,
    String? host,
    int? port,
    String? pathPrefix,
    HttpClient Function()? clientFactory,
  }) : _scheme = scheme ?? 'http',
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

  static const _connectTimeout = Duration(seconds: 10);

  // `POST /api/v1/route` responds over Server-Sent Events: it writes a
  // "queued" frame immediately, then blocks server-side (up to a 30s
  // internal timeout — see swayrider-api's sse.Hub.WaitForResult) waiting
  // on a Redis-queued worker before writing the final "result"/"error"
  // frame and closing the connection. The read timeout has to comfortably
  // exceed that server-side wait.
  static const _routeResponseTimeout = Duration(seconds: 35);

  HttpClient _newClient() =>
      _clientFactory()..connectionTimeout = _connectTimeout;

  Uri _uri(String path) =>
      Uri(scheme: _scheme, host: _host, port: _port, path: '$_pathPrefix$path');

  /// Requests a route through [points] (ordered: first = start, last =
  /// end) and returns the decoded path geometry.
  ///
  /// When [isRoundTrip] is set, the start point is appended again as the
  /// final location so the route closes back into a loop — the gateway's
  /// route DTO has no round-trip flag.
  Future<Result<List<LatLng>>> calculateRoute({
    required List<LatLng> points,
    bool isRoundTrip = false,
  }) async {
    final client = _newClient();
    try {
      final request = await client
          .postUrl(_uri('/route'))
          .timeout(_connectTimeout);
      await _authHeader(request.headers);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(_body(points, isRoundTrip)));
      final response = await request.close().timeout(_routeResponseTimeout);
      final stringData = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_routeResponseTimeout);
      if (response.statusCode == 200) {
        return _parseSse(stringData);
      } else if (response.statusCode == 401) {
        return const Result.error(UnauthorizedException());
      } else {
        return Result.error(
          HttpException("Route error: HTTP ${response.statusCode}"),
        );
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      client.close();
    }
  }

  /// Builds the `POST /api/v1/route` request body — a flattened
  /// `from`/`waypoints`/`to` shape (not the raw router.proto `RouteRequest`;
  /// that message belongs to routerservice's own internal gRPC-gateway,
  /// which swayrider-api doesn't expose directly). Every waypoint is sent
  /// with `type: "through"` (the one string grpcclients/routerclient
  /// special-cases, mapping it to `L_THROUGH`); anything else — including
  /// no type at all — becomes a full `L_BREAK` stop, which *allows* a
  /// U-turn there. Left as a plain stop, a single-waypoint round trip's
  /// return leg is just the shortest path back — the same road, reversed —
  /// so the rider does a U-turn at the waypoint and retraces the outbound
  /// leg. `L_THROUGH` disallows the U-turn, forcing an actual loop.
  ///
  /// Non-round-trip: `from` = start, `waypoints` = the points between,
  /// `to` = the end. Round trip: the same, except the last point becomes
  /// one more entry in `waypoints` and `to` is the start coordinate again,
  /// closing the loop.
  Map<String, dynamic> _body(List<LatLng> points, bool isRoundTrip) {
    final middle = points.length > 2
        ? points.sublist(1, points.length - 1)
        : const <LatLng>[];
    final waypoints = [...middle, if (isRoundTrip) points.last];
    return {
      'from': _coord(points.first),
      'to': _coord(isRoundTrip ? points.first : points.last),
      if (waypoints.isNotEmpty)
        'waypoints': [for (final point in waypoints) _waypoint(point)],
      // Motorcycle-only app; matches the "Standard Motorcycle" vehicle
      // pill shown on the home screen.
      'vehicle': 'motorcycle',
    };
  }

  Map<String, dynamic> _coord(LatLng point) => {
    'lat': point.latitude,
    'lon': point.longitude,
  };

  Map<String, dynamic> _waypoint(LatLng point) => {
    ..._coord(point),
    'type': 'through',
  };

  /// Parses the accumulated SSE response body (`event: name` / `data: json`
  /// frame pairs) and extracts the route from the final `result` frame's
  /// `JobResult` envelope (`{success, data, error}`), or surfaces the
  /// message from a terminal `error` frame (queue-full, timeout, not
  /// found).
  Result<List<LatLng>> _parseSse(String body) {
    Map<String, dynamic>? result;
    Map<String, dynamic>? sseError;
    for (final block in body.split('\n\n')) {
      if (block.trim().isEmpty) continue;
      String? event;
      String? data;
      for (final line in block.split('\n')) {
        if (line.startsWith('event:')) event = line.substring(6).trim();
        if (line.startsWith('data:')) data = line.substring(5).trim();
      }
      if (data == null) continue;
      switch (event) {
        case 'result':
          result = jsonDecode(data) as Map<String, dynamic>;
        case 'error':
          sseError = jsonDecode(data) as Map<String, dynamic>;
      }
    }

    if (result != null) {
      if (result['success'] != true) {
        final message = (result['error'] as Map<String, dynamic>?)?['message'];
        return Result.error(Exception('Route error: ${message ?? 'unknown'}'));
      }
      final trip =
          (result['data'] as Map<String, dynamic>?)?['trip']
              as Map<String, dynamic>?;
      final legs = trip?['legs'] as List<dynamic>? ?? [];
      if (legs.isEmpty) {
        return Result.error(Exception('No route found'));
      }
      final points = <LatLng>[
        for (final leg in legs)
          ...decodePolyline((leg as Map<String, dynamic>)['shape'] as String),
      ];
      return Result.ok(points);
    }

    if (sseError != null) {
      return Result.error(Exception('Route error: ${sseError['message']}'));
    }
    return Result.error(Exception('No route result received'));
  }
}
