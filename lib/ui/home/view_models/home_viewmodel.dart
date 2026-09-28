import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/search/search_repository.dart';
import '../../../data/repositories/tiles/tiles_repository.dart';
import '../../../data/services/api/model/search/search_result_item.dart';
import '../../../data/services/location_service.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// Map center used when the device's current location can't be determined.
const _defaultLocation = LatLng(51.2194, 4.4025);

/// Style served by tilesservice; see `tilesservice/assets/map/styles/`.
const _mapStyleName = 'light';

/// Minimum query length before triggering an autocomplete request.
const _minSearchTextLength = 2;

/// Delay after the last keystroke before triggering an autocomplete request.
const _searchDebounce = Duration(milliseconds: 400);

/// Arguments for [HomeViewModel.resolveHouseNumber]: the street the house
/// number is being resolved on, the number as typed by the user, and the
/// locale to query with.
typedef ResolveHouseNumberArgs = ({
  SearchResultItem street,
  String houseNumber,
  String language,
});

/// Squared Euclidean distance in degrees — good enough to rank a handful of
/// nearby candidates by proximity without needing a true geodesic formula.
double _squaredDistance(double lat1, double lon1, double lat2, double lon2) {
  final dLat = lat1 - lat2;
  final dLon = lon1 - lon2;
  return dLat * dLat + dLon * dLon;
}

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this._authRepository,
    required this._tilesRepository,
    required this._locationService,
    required this._searchRepository,
  }) {
    logout = Command0<void>(_logout);
    loadMap = Command0<void>(_loadMap);
    resolveHouseNumber = Command1<SearchResultItem, ResolveHouseNumberArgs>(
      _resolveHouseNumber,
    );
  }

  final AuthRepository _authRepository;
  final TilesRepository _tilesRepository;
  final LocationService _locationService;
  final SearchRepository _searchRepository;
  final _log = Logger('HomeViewModel');

  late Command0 logout;
  late Command0<void> loadMap;
  late Command1<SearchResultItem, ResolveHouseNumberArgs> resolveHouseNumber;

  LatLng? location;
  String? mapStyle;

  List<SearchResultItem> suggestions = [];
  bool isSearchLoading = false;

  Timer? _searchDebounceTimer;

  Future<Result<void>> _logout() async {
    final result = await _authRepository.logout();
    if (result is Error<void>) {
      _log.warning('Logout failed! ${result.error}');
    }
    return result;
  }

  Future<Result<void>> _loadMap() async {
    final (locationResult, styleResult) = await (
      _locationService.getCurrentLocation(),
      _tilesRepository.getMapStyle(name: _mapStyleName),
    ).wait;

    location = switch (locationResult) {
      Ok(:final value) => value,
      Error(:final error) => _fallbackLocation(error),
    };

    switch (styleResult) {
      case Ok(:final value):
        mapStyle = value;
        return const Result.ok(null);
      case Error(:final error):
        _log.warning('Failed to load map style: $error');
        return Result.error(error);
    }
  }

  LatLng _fallbackLocation(Object error) {
    _log.info('Could not determine current location, using default: $error');
    return _defaultLocation;
  }

  /// Called as the user types in the search field. Debounces requests and
  /// clears suggestions immediately for short/empty queries.
  void onSearchChanged(String text, {String language = 'en'}) {
    _searchDebounceTimer?.cancel();
    if (text.trim().length < _minSearchTextLength) {
      clearSuggestions();
      return;
    }
    _searchDebounceTimer = Timer(
      _searchDebounce,
      () => _doSearch(text, language),
    );
  }

  Future<void> _doSearch(String text, String language) async {
    isSearchLoading = true;
    notifyListeners();

    final result = await _searchRepository.autocomplete(
      text: text,
      focusPoint: location ?? _defaultLocation,
      language: language,
    );

    switch (result) {
      case Ok(:final value):
        suggestions = value;
      case Error(:final error):
        _log.warning('Autocomplete failed: $error');
        suggestions = [];
    }
    isSearchLoading = false;
    notifyListeners();
  }

  /// Resolves [ResolveHouseNumberArgs.houseNumber] on
  /// [ResolveHouseNumberArgs.street] to a concrete address. The backend picks
  /// the numerically closest known house number on that street to the one
  /// requested, so the result may not be an exact match.
  Future<Result<SearchResultItem>> _resolveHouseNumber(
    ResolveHouseNumberArgs args,
  ) async {
    // Deliberately no locality/city text here: `locality` is inconsistently
    // tagged in the source data (e.g. a hamlet name that differs from the
    // municipality the address is actually filed under), so including it
    // can make an otherwise-findable address match nothing. Disambiguation
    // instead comes from focusPoint (centered on the original street match)
    // and targetHousenumber.
    final query = [
      args.street.street ?? args.street.label,
      args.houseNumber,
    ].where((part) => part.trim().isNotEmpty).join(' ');

    final result = await _searchRepository.autocomplete(
      text: query,
      focusPoint: LatLng(args.street.lat, args.street.lon),
      language: args.language,
      targetHousenumber: args.houseNumber,
    );

    switch (result) {
      case Ok(:final value):
        // Match by street name, then pick the candidate closest to the
        // originally selected street's coordinates. Locality text can't be
        // used to disambiguate (see above) — but nearby villages can share
        // a street name (e.g. three separate "Erkstraat"s a few km apart),
        // so name alone isn't enough either. Coordinates are reliable where
        // the text fields aren't.
        SearchResultItem? closest;
        double? closestDistance;
        for (final r in value) {
          if (r.street != args.street.street) continue;
          final distance = _squaredDistance(
            r.lat,
            r.lon,
            args.street.lat,
            args.street.lon,
          );
          if (closestDistance == null || distance < closestDistance) {
            closest = r;
            closestDistance = distance;
          }
        }
        if (closest != null) return Result.ok(closest);
        return Result.error(Exception('No address found on this street'));
      case Error(:final error):
        _log.warning('House number resolution failed: $error');
        return Result.error(error);
    }
  }

  /// Clears any pending search results and cancels a pending debounce.
  void clearSuggestions() {
    _searchDebounceTimer?.cancel();
    suggestions = [];
    isSearchLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
