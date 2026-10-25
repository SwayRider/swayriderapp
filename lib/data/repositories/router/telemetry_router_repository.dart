import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../domain/models/route/reroute_request.dart';
import '../../../domain/models/route/route_plan.dart';
import '../../../utils/result.dart';
import '../../services/telemetry/telemetry_encoders.dart';
import '../../services/telemetry/telemetry_service.dart';
import 'router_repository.dart';

/// Records every route and reroute request with the plan that came back in
/// the telemetry trace, then passes the result through unchanged.
class TelemetryRouterRepository implements RouterRepository {
  TelemetryRouterRepository({required this._inner, required this._telemetry});

  final RouterRepository _inner;
  final TelemetryService _telemetry;
  int _serial = 0;

  @override
  Future<Result<RoutePlan>> calculateRoute({
    required List<LatLng> points,
    bool isRoundTrip = false,
    String language = 'en-US',
  }) => _record(
    'route',
    {
      'points': points.map(encodeLatLng).toList(),
      'isRoundTrip': isRoundTrip,
      'language': language,
    },
    () => _inner.calculateRoute(
      points: points,
      isRoundTrip: isRoundTrip,
      language: language,
    ),
  );

  @override
  Future<Result<RoutePlan>> reroute(RerouteRequest request) => _record(
    'reroute',
    encodeRerouteRequest(request),
    () => _inner.reroute(request),
  );

  Future<Result<RoutePlan>> _record(
    String kind,
    Map<String, Object?> request,
    Future<Result<RoutePlan>> Function() call,
  ) async {
    final id = ++_serial;
    final watch = Stopwatch()..start();
    _telemetry.record('route_request', {'id': id, 'kind': kind, ...request});
    final result = await call();
    _telemetry.record('route_response', {
      'id': id,
      'kind': kind,
      'latencyMs': watch.elapsedMilliseconds,
      ...switch (result) {
        Ok<RoutePlan>() => {'plan': encodeRoutePlan(result.value)},
        Error<RoutePlan>() => {'error': '${result.error}'},
      },
    });
    return result;
  }
}
