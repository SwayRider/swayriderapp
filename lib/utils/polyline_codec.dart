import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

/// Decodes a Google-style encoded polyline: signed values delta-encoded as
/// 5-bit chunks (continuation bit `0x20`, offset `0x3f`), one per
/// coordinate. `routerservice` returns `Leg.shape` in this format at
/// [precision] `1e6` ("polyline6").
List<LatLng> decodePolyline(String encoded, {double precision = 1e6}) {
  final points = <LatLng>[];
  var index = 0;
  var lat = 0;
  var lng = 0;

  while (index < encoded.length) {
    lat += _decodeSignedChunk(encoded, () => index, (next) => index = next);
    lng += _decodeSignedChunk(encoded, () => index, (next) => index = next);
    points.add(LatLng(lat / precision, lng / precision));
  }

  return points;
}

int _decodeSignedChunk(
  String encoded,
  int Function() getIndex,
  void Function(int) setIndex,
) {
  var index = getIndex();
  var shift = 0;
  var result = 0;
  int byte;
  do {
    byte = encoded.codeUnitAt(index++) - 63;
    result |= (byte & 0x1f) << shift;
    shift += 5;
  } while (byte >= 0x20);
  setIndex(index);
  return (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
}
