import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../data/services/location_service.dart';
import '../../../data/services/speech_service.dart';
import '../../../domain/models/route/route_plan.dart';
import '../../../domain/navigation/camera_zoom.dart';
import '../../../domain/navigation/geo.dart';
import '../../../data/repositories/router/router_repository.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/route_map_colors.dart';
import '../../home/view_models/map_style_view_model.dart';
import '../view_models/navigation_viewmodel.dart';
import 'lane_guidance.dart';
import 'navigation_header.dart';
import 'stop_navigation_dialog.dart';
import 'speed_indicator.dart';

/// Fullscreen 3D map with turn-by-turn guidance along [plan].
///
/// The camera follows a dot snapped to the route, looking along the route
/// with a steep tilt; the dot sits in the lower part of the screen so more
/// of the road ahead is visible. While this screen is open the display stays
/// on and the maneuvers are spoken.
class NavigationScreen extends StatefulWidget {
  const NavigationScreen({
    super.key,
    required this.plan,
    required this.locationService,
    required this.speechService,
    required this.styleViewModel,
    this.routerRepository,
  });

  final RoutePlan plan;
  final LocationService locationService;
  final SpeechService speechService;
  final MapStyleViewModel styleViewModel;

  /// Asks for the way back when the rider leaves the route; without it the
  /// route is only followed.
  final RouterRepository? routerRepository;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const _tilt = 60.0;
  static const _tickPeriod = Duration(milliseconds: 100);

  /// Share of the screen height the dot is moved down from the centre.
  static const _dotOffsetShare = 0.22;

  /// Fraction of the remaining distance / angle covered per tick, so the dot
  /// and camera glide between the ~1 Hz GPS fixes.
  static const _positionSmoothing = 0.3;
  static const _bearingSmoothing = 0.2;
  static const _zoomSmoothing = 0.1;

  final _log = Logger('NavigationScreen');

  late final NavigationViewModel _viewModel;
  MapLibreMapController? _map;
  Line? _routeLine;
  Line? _routeCasing;
  int _drawnRouteVersion = 0;
  bool _redrawing = false;
  Circle? _dot;
  Timer? _timer;
  bool _busy = false;

  LatLng? _position;
  double _bearing = 0;
  double _zoom = CameraZoom.slowZoom;
  double? _appliedZoom;
  bool _bearingInitialised = false;
  LatLng? _appliedCenter;
  double? _appliedBearing;

  @override
  void initState() {
    super.initState();
    _viewModel = NavigationViewModel(
      plan: widget.plan,
      routerRepository: widget.routerRepository,
      locationService: widget.locationService,
      speechService: widget.speechService,
    );
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.start();
    unawaited(_setWakelock(true));
    _timer = Timer.periodic(_tickPeriod, (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    unawaited(_setWakelock(false));
    super.dispose();
  }

  Future<void> _setWakelock(bool enabled) async {
    try {
      await (enabled ? WakelockPlus.enable() : WakelockPlus.disable());
    } on Object catch (e) {
      _log.info('Could not change the wakelock: $e');
    }
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    setState(() {});
    // A new route (the way back): draw it in place of the old one.
    if (_viewModel.routeVersion != _drawnRouteVersion && !_redrawing) {
      unawaited(_redrawRoute());
    }
  }

  Future<void> _redrawRoute() async {
    final controller = _map;
    if (controller == null || _routeLine == null) return;
    _redrawing = true;
    try {
      final casing = _routeCasing;
      final line = _routeLine;
      _routeCasing = null;
      _routeLine = null;
      if (casing != null) await controller.removeLine(casing);
      if (line != null) await controller.removeLine(line);
      await _drawRoute(controller);
    } finally {
      _redrawing = false;
    }
  }

  // A new style wipes every annotation; drop the stale handles and add
  // everything again (also runs for the first style load).
  Future<void> _onStyleLoaded() async {
    _routeLine = null;
    _dot = null;
    _appliedCenter = null;
    final controller = _map;
    if (controller == null) return;
    _routeCasing = null;
    await _drawRoute(controller);
  }

  /// Draws the route of the view model: petrol on a white edge on the light
  /// map, orange on a dark edge on the dark one, so it stands out from the
  /// roads either way.
  Future<void> _drawRoute(MapLibreMapController controller) async {
    _drawnRouteVersion = _viewModel.routeVersion;
    final path = _viewModel.plan.path;
    final colors = RouteMapColors.of(widget.styleViewModel.variant);
    _routeCasing = await controller.addLine(
      LineOptions(
        geometry: path,
        lineColor: colors.casing,
        lineWidth: 16,
        lineJoin: 'round',
      ),
    );
    _routeLine = await controller.addLine(
      LineOptions(
        geometry: path,
        lineColor: colors.line,
        lineWidth: 12,
        lineJoin: 'round',
      ),
    );
  }

  /// Moves the dot and the camera one smoothing step towards the latest
  /// snapped position and route bearing.
  Future<void> _tick() async {
    final controller = _map;
    final camera = controller?.cameraPosition;
    final target = _viewModel.dotPosition;
    if (_busy || controller == null || camera == null || target == null) {
      return;
    }
    if (_routeLine == null) return; // style not loaded yet

    final targetBearing = _targetBearing();
    final position = _position;
    _position = position == null
        ? target
        : lerpLatLng(position, target, _positionSmoothing);
    if (!_bearingInitialised) {
      _bearing = targetBearing;
      _bearingInitialised = true;
    } else {
      _bearing =
          (_bearing +
              shortestAngleDelta(_bearing, targetBearing) * _bearingSmoothing +
              360) %
          360;
    }

    _zoom += (_viewModel.targetZoom - _zoom) * _zoomSmoothing;

    final dotAt = _position!;
    final center = destinationPoint(
      dotAt,
      _bearing,
      _aheadMeters(dotAt.latitude, _zoom),
    );
    final moved = _appliedCenter == null
        ? double.infinity
        : distanceMeters(_appliedCenter!, center);
    final turned = _appliedBearing == null
        ? double.infinity
        : shortestAngleDelta(_appliedBearing!, _bearing).abs();
    final zoomed = _appliedZoom == null
        ? double.infinity
        : (_zoom - _appliedZoom!).abs();
    if (moved < 0.2 && turned < 0.2 && zoomed < 0.005 && _dot != null) return;

    _busy = true;
    try {
      final dot = _dot;
      if (dot == null) {
        _dot = await controller.addCircle(_dotOptions(dotAt));
      } else {
        await controller.updateCircle(dot, CircleOptions(geometry: dotAt));
      }
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: center,
            bearing: _bearing,
            zoom: _zoom,
            tilt: _tilt,
          ),
        ),
      );
      _appliedCenter = center;
      _appliedBearing = _bearing;
      _appliedZoom = _zoom;
    } on Object catch (e) {
      _log.fine('Camera/dot update failed: $e');
    } finally {
      _busy = false;
    }
  }

  double _targetBearing() {
    final routeBearing = _viewModel.routeBearing;
    if (_viewModel.offRoute) {
      final course = _viewModel.fix?.courseDegrees;
      if (course != null) return course;
    }
    return routeBearing ?? _bearing;
  }

  /// Distance the camera target has to sit ahead of the dot so that the dot
  /// appears [_dotOffsetShare] of the screen height below the centre.
  ///
  /// At this zoom one logical pixel covers `78271.5 * cos(lat) / 2^zoom`
  /// meters; a ground distance along the view direction is foreshortened by
  /// `cos(tilt)` on screen.
  double _aheadMeters(double latitude, double zoom) {
    final height = MediaQuery.sizeOf(context).height;
    final metersPerPixel =
        78271.517 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);
    return _dotOffsetShare *
        height *
        metersPerPixel /
        math.cos(_tilt * math.pi / 180);
  }

  CircleOptions _dotOptions(LatLng at) => CircleOptions(
    geometry: at,
    circleRadius: 10,
    circleColor: RouteMapColors.of(widget.styleViewModel.variant).dot,
    circleStrokeColor: '#FFFFFF',
    circleStrokeWidth: 3,
  );

  /// The close button: ask first while guiding, "Done" after arriving ends
  /// right away.
  Future<void> _confirmEnd() async {
    if (!_viewModel.arrived && !await confirmStopNavigation(context)) return;
    if (mounted) _end();
  }

  void _end() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black1,
      body: Stack(
        children: [
          Positioned.fill(
            child: ListenableBuilder(
              listenable: widget.styleViewModel,
              builder: (context, _) {
                final style = widget.styleViewModel.mapStyle;
                if (style == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final path = widget.plan.path;
                return MapLibreMap(
                  styleString: style,
                  initialCameraPosition: CameraPosition(
                    target: path.first,
                    zoom: _zoom,
                    tilt: _tilt,
                    bearing: path.length > 1
                        ? bearingDegrees(path[0], path[1])
                        : 0,
                  ),
                  myLocationEnabled: false,
                  compassEnabled: false,
                  trackCameraPosition: true,
                  // The app drives the camera, zoom included.
                  zoomGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  onMapCreated: (controller) => _map = controller,
                  onStyleLoadedCallback: _onStyleLoaded,
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NavigationHeader(
                  maneuver: _viewModel.upcoming,
                  drivesOnRight: _viewModel.drivesOnRight,
                  eta: _viewModel.eta,
                  remainingMeters: _viewModel.remainingMeters,
                  distanceMeters: _viewModel.distanceToUpcomingMeters,
                  arrived: _viewModel.arrived,
                  offRoute: _viewModel.offRoute,
                  recalculating:
                      _viewModel.rerouteStatus == RerouteStatus.pending,
                  hasLocationError: _viewModel.locationError != null,
                  onEnd: _confirmEnd,
                ),
                if (!_viewModel.arrived && _viewModel.laneGuidance.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: LaneGuidance(lanes: _viewModel.laneGuidance),
                  ),
              ],
            ),
          ),
          if (_viewModel.fix != null)
            Positioned(
              left: 16,
              bottom: 12,
              child: SafeArea(
                child: SpeedIndicator(speedKmh: _viewModel.speedKmh),
              ),
            ),
        ],
      ),
    );
  }
}
