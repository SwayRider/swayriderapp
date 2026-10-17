import 'dart:convert';
import 'dart:io';

import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../domain/models/route/route_lane.dart';
import '../../../domain/models/route/route_maneuver.dart';
import '../../../domain/models/route/route_plan.dart';
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
  /// end) and returns the decoded path geometry together with its
  /// turn-by-turn maneuvers.
  ///
  /// [language] is the Valhalla language tag the verbal instructions are
  /// requested in (see [routeLanguageFor]).
  ///
  /// When [isRoundTrip] is set, the start point is appended again as the
  /// final location so the route closes back into a loop — the gateway's
  /// route DTO has no round-trip flag.
  Future<Result<RoutePlan>> calculateRoute({
    required List<LatLng> points,
    bool isRoundTrip = false,
    String language = 'en-US',
  }) async {
    final client = _newClient();
    try {
      final request = await client
          .postUrl(_uri('/route'))
          .timeout(_connectTimeout);
      await _authHeader(request.headers);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(_body(points, isRoundTrip, language)));
      final response = await request.close().timeout(_routeResponseTimeout);
      final stringData = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_routeResponseTimeout);
      if (response.statusCode == 200) {
        return _parseSse(stringData, language);
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
  Map<String, dynamic> _body(
    List<LatLng> points,
    bool isRoundTrip,
    String language,
  ) {
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
      'unit': 'km',
      'language': language,
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
  Result<RoutePlan> _parseSse(String body, String requestedLanguage) {
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
      return Result.ok(_planFromTrip(trip!, legs, requestedLanguage));
    }

    if (sseError != null) {
      return Result.error(Exception('Route error: ${sseError['message']}'));
    }
    return Result.error(Exception('No route result received'));
  }

  /// Merges the trip's legs into one [RoutePlan]. Each leg has its own
  /// shape, so a leg's maneuver shape indices are shifted by the number of
  /// points already accumulated; the first point of every later leg repeats
  /// the previous leg's last point and is dropped.
  RoutePlan _planFromTrip(
    Map<String, dynamic> trip,
    List<dynamic> legs,
    String requestedLanguage,
  ) {
    final path = <LatLng>[];
    final maneuvers = <RouteManeuver>[];
    for (final raw in legs) {
      final leg = raw as Map<String, dynamic>;
      final shape = decodePolyline(leg['shape'] as String);
      final joinsPrevious = path.isNotEmpty && shape.isNotEmpty;
      // Index `i` of this leg's shape lands at `path.length + i - 1` when the
      // duplicate join point is dropped.
      final offset = path.length - (joinsPrevious ? 1 : 0);
      path.addAll(joinsPrevious ? shape.skip(1) : shape);
      for (final m in leg['maneuvers'] as List<dynamic>? ?? const []) {
        maneuvers.add(_maneuver(m as Map<String, dynamic>).shifted(offset));
      }
    }
    final summary = trip['summary'] as Map<String, dynamic>?;
    return RoutePlan(
      path: path,
      maneuvers: maneuvers,
      // Requested in kilometers.
      distanceMeters: ((summary?['length'] as num?) ?? 0) * 1000.0,
      durationSeconds: ((summary?['time'] as num?) ?? 0).toDouble(),
      language: _nonEmpty(trip['language']) ?? requestedLanguage,
    );
  }

  RouteManeuver _maneuver(Map<String, dynamic> m) => RouteManeuver(
    type: (m['type'] as num?)?.toInt() ?? 0,
    instruction: (m['instruction'] as String?) ?? '',
    beginShapeIndex: (m['begin_shape_index'] as num?)?.toInt() ?? 0,
    endShapeIndex: (m['end_shape_index'] as num?)?.toInt() ?? 0,
    verbalAlert: _nonEmpty(m['verbal_transition_alert_instruction']),
    verbalPre: _nonEmpty(m['verbal_pre_transition_instruction']),
    verbalPost: _nonEmpty(m['verbal_post_transition_instruction']),
    streetNames: [
      for (final n in m['street_names'] as List<dynamic>? ?? const [])
        n as String,
    ],
    lengthMeters: ((m['length'] as num?) ?? 0) * 1000.0,
    timeSeconds: ((m['time'] as num?) ?? 0).toDouble(),
    roundaboutExitCount: (m['roundabout_exit_count'] as num?)?.toInt(),
    lanes: [
      for (final l in m['lanes'] as List<dynamic>? ?? const [])
        RouteLane(
          directions: ((l as Map)['directions'] as num?)?.toInt() ?? 0,
          valid: (l['valid'] as num?)?.toInt(),
          active: (l['active'] as num?)?.toInt(),
        ),
    ],
  );

  String? _nonEmpty(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
