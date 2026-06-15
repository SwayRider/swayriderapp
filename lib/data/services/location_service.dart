import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../utils/result.dart';

/// Provides the device's current geographic location.
abstract class LocationService {
  /// Returns the device's current location, requesting location permission
  /// first if it hasn't been granted yet.
  ///
  /// Returns an [Error] if permission is denied or the location can't be
  /// determined, so callers can fall back to a default location.
  Future<Result<LatLng>> getCurrentLocation();
}

/// [LocationService] backed by the `geolocator` plugin.
class LocationServiceGeolocator implements LocationService {
  @override
  Future<Result<LatLng>> getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return Result.error(Exception('Location permission denied'));
      }

      final position = await Geolocator.getCurrentPosition();
      return Result.ok(LatLng(position.latitude, position.longitude));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
