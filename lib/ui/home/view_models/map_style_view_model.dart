import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../../../data/repositories/tiles/tiles_repository.dart';
import '../../../data/services/ambient_light_service.dart';
import '../../../data/services/map_style_preference_service.dart';
import '../../../domain/models/map/map_style_mode.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import 'auto_variant_resolver.dart';

/// Owns which map style is shown: the user's choice (day / night / auto), the
/// light or dark variant that results from it, and the style JSON for it.
///
/// Auto follows the ambient light sensor, evaluated on a slow timer by an
/// [AutoVariantResolver]. Without usable readings (no sensor, an error, iOS
/// before the user opted in) it follows the system appearance instead.
///
/// The map must never lose its style while switching: [mapStyle] keeps the old
/// value until the new one has been loaded, so the map widget is not replaced.
class MapStyleViewModel extends ChangeNotifier {
  MapStyleViewModel({
    required this._tilesRepository,
    required this._preferences,
    required this._ambientLight,
    required this._styleId,
    required this._platformBrightness,
    this.evaluateEvery = const Duration(milliseconds: 500),
    AutoVariantResolver Function(MapVariant initial)? resolverFactory,
  }) : _resolverFactory =
           resolverFactory ??
           ((initial) => AutoVariantResolver(initial: initial)) {
    load = Command0<void>(_load);
  }

  final TilesRepository _tilesRepository;
  final MapStylePreferenceService _preferences;
  final AmbientLightService _ambientLight;
  final String _styleId;
  final Brightness Function() _platformBrightness;
  final AutoVariantResolver Function(MapVariant initial) _resolverFactory;
  final _log = Logger('MapStyleViewModel');

  /// How often the light level is looked at besides on every reading (the
  /// sensor only reports on change, and the debounce needs time to pass).
  final Duration evaluateEvery;

  /// Loads the saved choice and the first style. The map waits for it.
  late final Command0<void> load;

  MapStyleMode _mode = MapStylePreferenceService.defaultMode;
  MapVariant _variant = MapVariant.light;
  String? _mapStyle;
  int _switchFailures = 0;

  final _styleCache = <MapVariant, String>{};
  final _downloads = <MapVariant, Future<Result<String>>>{};
  int _applySeq = 0;

  bool _sensorOptIn = false;
  bool _active = true;
  bool _disposed = false;
  AutoVariantResolver? _resolver;
  StreamSubscription<double>? _sensorSub;
  Timer? _timer;

  /// The user's choice.
  MapStyleMode get mode => _mode;

  /// The variant on screen. For [MapStyleMode.auto] this is what Auto decided.
  MapVariant get variant => _variant;

  /// Style JSON for `MapLibreMap.styleString`; null until the first load.
  String? get mapStyle => _mapStyle;

  /// Counts failed attempts to switch style (the old style stays on screen).
  /// The screen shows a message when it goes up.
  int get switchFailures => _switchFailures;

  /// Whether measuring the light needs the camera on this device (iOS), which
  /// the picker should say.
  bool get autoNeedsCamera => _ambientLight.needsExplicitOptIn;

  /// Whether Auto currently follows a light sensor rather than the system
  /// appearance.
  bool get autoUsesSensor =>
      _sensorSub != null && (_resolver?.hasReadings ?? false);

  Future<Result<void>> _load() async {
    final mode = await _preferences.loadMode();
    if (mode case Ok(:final value)) _mode = value;
    final optIn = await _preferences.loadSensorOptIn();
    if (optIn case Ok(:final value)) _sensorOptIn = value;

    final target = _targetVariant();
    final result = await _fetchStyle(target);
    switch (result) {
      case Error(:final error):
        _log.warning('Failed to load the map style: $error');
        return Result.error(error);
      case Ok(:final value):
        _variant = target;
        _mapStyle = value;
        notifyListeners();
        _updateSensor();
        unawaited(
          _prefetch(
            target == MapVariant.light ? MapVariant.dark : MapVariant.light,
          ),
        );
        return const Result.ok(null);
    }
  }

  /// Changes the user's choice and applies it. Safe to call repeatedly: the
  /// last call wins and an older, slower style load is discarded.
  Future<void> setMode(MapStyleMode mode) async {
    if (_disposed) return;
    _mode = mode;
    // Picking Auto is the consent iOS needs before the camera measures light.
    if (mode == MapStyleMode.auto &&
        _ambientLight.needsExplicitOptIn &&
        !_sensorOptIn) {
      _sensorOptIn = true;
      unawaited(_preferences.saveSensorOptIn(true));
    }
    unawaited(_preferences.saveMode(mode));
    notifyListeners();
    _updateSensor();
    await _applyVariant(_targetVariant());
  }

  /// Call when the system light/dark appearance changes.
  void onPlatformBrightnessChanged() {
    if (_disposed || _mode != MapStyleMode.auto || autoUsesSensor) return;
    unawaited(_applyVariant(_targetVariant()));
  }

  /// Call when the app goes to the background (false) or comes back (true).
  /// The sensor only runs while the app is in the foreground.
  void setAppActive(bool active) {
    if (_disposed || _active == active) return;
    _active = active;
    _updateSensor();
  }

  MapVariant _variantFromBrightness() =>
      _platformBrightness() == Brightness.dark
      ? MapVariant.dark
      : MapVariant.light;

  MapVariant _targetVariant() => switch (_mode) {
    MapStyleMode.day => MapVariant.light,
    MapStyleMode.night => MapVariant.dark,
    MapStyleMode.auto =>
      autoUsesSensor ? _resolver!.variant : _variantFromBrightness(),
  };

  bool get _sensorAllowed => !_ambientLight.needsExplicitOptIn || _sensorOptIn;

  /// Starts or stops the sensor so that it runs only for Auto, in the
  /// foreground, and (on iOS) after the user opted in.
  void _updateSensor() {
    final shouldRun =
        !_disposed && _mode == MapStyleMode.auto && _active && _sensorAllowed;
    if (shouldRun && _sensorSub == null) {
      final resolver = _resolverFactory(_variant);
      _resolver = resolver;
      _log.info('Ambient light: started, showing ${_variant.name}');
      var first = true;
      _sensorSub = _ambientLight.lux.listen(
        (lux) {
          if (first) {
            first = false;
            _log.info(
              'Ambient light: first reading ${lux.toStringAsFixed(1)} lx',
            );
          }
          resolver.addReading(lux);
          _onTick();
        },
        onError: (Object e) =>
            _log.info('Ambient light unavailable, following the system: $e'),
      );
      _timer = Timer.periodic(evaluateEvery, (_) => _onTick());
    } else if (!shouldRun && _sensorSub != null) {
      unawaited(_sensorSub!.cancel());
      _sensorSub = null;
      _timer?.cancel();
      _timer = null;
    }
  }

  void _onTick() {
    final resolver = _resolver;
    if (_disposed || resolver == null || _mode != MapStyleMode.auto) return;
    if (resolver.evaluate()) {
      _log.info(
        'Ambient light: ${resolver.currentLux?.toStringAsFixed(1)} lx (smoothed) '
        '-> ${resolver.variant.name}',
      );
      unawaited(_applyVariant(resolver.variant));
    }
  }

  /// Shows [variant]. The old style stays until the new one is in hand.
  Future<void> _applyVariant(MapVariant variant) async {
    final token = ++_applySeq;
    if (variant == _variant && _mapStyle != null) return;

    final result = await _fetchStyle(variant);
    if (_disposed || token != _applySeq) return; // a newer request took over
    switch (result) {
      case Ok(:final value):
        _variant = variant;
        _mapStyle = value;
      case Error(:final error):
        _log.warning(
          'Failed to switch the map style to ${variant.name}: $error',
        );
        _switchFailures++;
    }
    notifyListeners();
  }

  /// The style JSON for [variant]: from the cache, from a download that is
  /// already running (e.g. the prefetch), or from a new one.
  Future<Result<String>> _fetchStyle(MapVariant variant) {
    final cached = _styleCache[variant];
    if (cached != null) return Future.value(Result.ok(cached));
    // A block body on purpose: `remove` returns this very future, and
    // `whenComplete` would wait for a returned future (waiting on itself).
    return _downloads[variant] ??= _download(variant).whenComplete(() {
      _downloads.remove(variant);
    });
  }

  Future<Result<String>> _download(MapVariant variant) async {
    final result = await _tilesRepository.getMapStyle(
      name: '$_styleId/${variant.path}',
    );
    if (result case Ok(:final value)) _styleCache[variant] = value;
    return result;
  }

  Future<void> _prefetch(MapVariant variant) async {
    try {
      await _fetchStyle(variant);
    } on Object catch (e) {
      _log.fine('Prefetching the ${variant.name} style failed: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_sensorSub?.cancel());
    _sensorSub = null;
    _timer?.cancel();
    _timer = null;
    load.dispose();
    super.dispose();
  }
}
