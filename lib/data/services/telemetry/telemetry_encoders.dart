import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../domain/models/location/location_fix.dart';
import '../../../domain/models/route/reroute_request.dart';
import '../../../domain/models/route/route_maneuver.dart';
import '../../../domain/models/route/route_plan.dart';
import '../api/model/search/search_result_item.dart';

/// JSON encoders for the values stored in telemetry events. The domain
/// models are not serializable themselves; these keep the trace format in one
/// place.

/// Coordinates are rounded to 7 decimals (about 1 cm), which drops the float
/// noise from longitude normalisation and keeps the trace small.
double _coord(double degrees) => (degrees * 1e7).round() / 1e7;

Map<String, Object?> encodeLatLng(LatLng p) => {
  'lat': _coord(p.latitude),
  'lon': _coord(p.longitude),
};

Map<String, Object?> encodeFix(LocationFix fix) => {
  ...encodeLatLng(fix.position),
  'course': fix.courseDegrees,
  'speedMps': fix.speedMps,
  'accuracyM': fix.accuracyMeters,
};

Map<String, Object?> encodeSearchItem(SearchResultItem item) => {
  'label': item.label,
  'layer': item.layer,
  'confidence': item.confidence,
  'lat': item.lat,
  'lon': item.lon,
  'street': item.street,
  'houseNumber': item.houseNumber,
  'id': item.id,
  'name': item.name,
};

Map<String, Object?> encodeManeuver(RouteManeuver m) => {
  'type': m.type,
  'instruction': m.instruction,
  'verbalAlert': m.verbalAlert,
  'verbalPre': m.verbalPre,
  'verbalPost': m.verbalPost,
  'streetNames': m.streetNames,
  'lengthM': m.lengthMeters,
  'timeS': m.timeSeconds,
  'beginShapeIndex': m.beginShapeIndex,
  'endShapeIndex': m.endShapeIndex,
  'roundaboutExit': m.roundaboutExitCount,
};

/// The path is flattened to `[lat, lon, lat, lon, ...]` to keep long routes
/// compact.
Map<String, Object?> encodeRoutePlan(RoutePlan plan) => {
  'distanceM': plan.distanceMeters,
  'durationS': plan.durationSeconds,
  'language': plan.language,
  'drivesOnRight': plan.drivesOnRight,
  'path': [
    for (final p in plan.path) ...[_coord(p.latitude), _coord(p.longitude)],
  ],
  'maneuvers': plan.maneuvers.map(encodeManeuver).toList(),
};

Map<String, Object?> encodeRerouteRequest(RerouteRequest r) => {
  'from': encodeLatLng(r.from),
  'heading': r.heading,
  'stops': r.stops.map(encodeLatLng).toList(),
  'exclusions': [
    for (final ring in r.exclusions) ring.map(encodeLatLng).toList(),
  ],
  'language': r.language,
};
