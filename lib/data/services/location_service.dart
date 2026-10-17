import 'dart:async';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../domain/models/location/location_fix.dart';
import '../../utils/result.dart';

/// Provides the device's current geographic location.
abstract class LocationService {
  /// Returns the device's current location, requesting location permission
  /// first if it hasn't been granted yet.
  ///
  /// Returns an [Error] if permission is denied or the location can't be
  /// determined, so callers can fall back to a default location.
  Future<Result<LatLng>> getCurrentLocation();

  /// Continuous stream of GPS fixes tuned for turn-by-turn navigation.
  ///
  /// Permission is expected to be granted already (the home map asks for it
  /// first); on a permission or service error the stream emits the error.
  Stream<LocationFix> positions();
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

  @override
  Stream<LocationFix> positions() {
    final settings = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        accuracy: LocationAccuracy.best,
        intervalDuration: const Duration(seconds: 1),
      ),
      TargetPlatform.iOS => AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
      ),
      _ => const LocationSettings(accuracy: LocationAccuracy.best),
    };
    return Geolocator.getPositionStream(locationSettings: settings).map(
      (p) => LocationFix(
        position: LatLng(p.latitude, p.longitude),
        // geolocator reports -1 / 0 heading when unknown.
        courseDegrees: p.heading >= 0 && p.speed > 0.5 ? p.heading : null,
        speedMps: p.speed < 0 ? 0 : p.speed,
        accuracyMeters: p.accuracy,
      ),
    );
  }
}
