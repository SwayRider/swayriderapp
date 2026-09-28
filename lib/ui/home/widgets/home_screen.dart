import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../data/services/api/model/search/search_result_item.dart';
import '../../../domain/models/route/route_point.dart';
import '../../../utils/result.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_text_field.dart';
import '../../core/ui/branded_app_bar.dart';
import '../../core/ui/circle_icon_button.dart';
import '../../core/ui/profile_menu_button.dart';
import '../../core/ui/vehicle_type_pill.dart';
import '../view_models/home_viewmodel.dart';

/// The city name to display for a result: `locality` when set, falling back
/// to `localAdmin` (Belgian municipality names often land there rather than
/// in `locality`, which Pelias reserves for smaller named places such as a
/// hamlet within that municipality) so the city isn't dropped entirely.
String _cityFor(SearchResultItem item) =>
    item.locality.trim().isNotEmpty ? item.locality : (item.localAdmin ?? '');

/// Street + city text for an address result, with no house number — used
/// both for the street-only search box text and an address row's title, so
/// what's shown always matches what tapping the row searches for.
String _streetLabel(SearchResultItem item) {
  return [
    item.street ?? item.label,
    _cityFor(item),
  ].where((part) => part.trim().isNotEmpty).join(', ');
}

/// Street + house number + city text for a resolved address, built from
/// [original]'s city rather than [resolved]'s own label. The same street can
/// be filed under different city names depending on which record matched
/// (e.g. a hamlet vs. the municipality it belongs to) even though it's the
/// same physical location — using [original]'s city keeps the result
/// consistent with the row the user actually picked.
String _resolvedAddressLabel(
  SearchResultItem original,
  SearchResultItem resolved,
) {
  final streetAndNumber = [
    resolved.street ?? original.street ?? original.label,
    resolved.houseNumber,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
  return [
    streetAndNumber,
    _cityFor(original),
  ].where((part) => part.trim().isNotEmpty).join(', ');
}

enum _LocationMenuAction {
  currentPosition,
  routeStart,
  routeEnd,
  completeRoute,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  MapLibreMapController? _mapController;
  Circle? _searchMarker;
  final List<Circle> _routeMarkers = [];
  Future<void>? _markerSyncFuture;
  Line? _routeLine;
  Future<void>? _lineSyncFuture;
  List<LatLng>? _syncedRoutePath;

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadMap.execute();
    _searchController.addListener(_onSearchTextChanged);
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  // The route line depends on an async network result, unlike the point
  // markers (which react to a synchronous local mutation and are synced
  // imperatively right after it) — so it's synced reactively here instead
  // of from the same call sites.
  void _onViewModelChanged() {
    final path = widget.viewModel.routePath;
    if (!identical(path, _syncedRoutePath)) {
      _syncedRoutePath = path;
      _syncRouteLine();
    }
  }

  void _onSearchTextChanged() {
    widget.viewModel.onSearchChanged(
      _searchController.text,
      language: Localizations.localeOf(context).languageCode,
    );
  }

  void _selectStreet(SearchResultItem item) =>
      _applySelection(_streetLabel(item), LatLng(item.lat, item.lon));

  Future<void> _applySelection(String text, LatLng point) async {
    _searchController.text = text;
    widget.viewModel.clearSuggestions();
    FocusScope.of(context).unfocus();
    await _showSearchMarker(point);
    if (!mounted) return;
    await _showRoleSheet(label: text, point: point);
  }

  Future<void> _showRoleSheet({
    required String label,
    required LatLng point,
  }) async {
    final role = await showModalBottomSheet<RouteRole>(
      context: context,
      backgroundColor: AppColors.black,
      builder: (context) =>
          _RoleSheet(routePointCount: widget.viewModel.routePoints.length),
    );
    if (role == null || !mounted) return;

    final routePoint = RoutePoint(label: label, point: point);
    switch (role) {
      case RouteRole.start:
        widget.viewModel.setAsStartPoint(routePoint);
      case RouteRole.destination:
        widget.viewModel.setAsDestination(routePoint);
      case RouteRole.waypoint:
        widget.viewModel.setAsWaypoint(routePoint);
    }

    // The point now has a permanent role-colored marker (below) — drop the
    // transient orange preview so the two don't sit stacked on each other.
    final marker = _searchMarker;
    if (marker != null) {
      await _mapController?.removeCircle(marker);
      _searchMarker = null;
    }

    await _syncRouteMarkers();
    _searchController.clear();
  }

  Future<void> _syncRouteMarkers() {
    final previous = _markerSyncFuture ?? Future.value();
    final next = previous.then((_) => _doSyncRouteMarkers());
    _markerSyncFuture = next;
    return next;
  }

  Future<void> _doSyncRouteMarkers() async {
    final controller = _mapController;
    if (controller == null) return;
    if (_routeMarkers.isNotEmpty) {
      await controller.removeCircles(_routeMarkers);
      _routeMarkers.clear();
    }
    final points = widget.viewModel.routePoints;
    if (points.isEmpty) return;
    final isRoundTrip = widget.viewModel.isRoundTrip;
    final options = [
      for (var i = 0; i < points.length; i++)
        CircleOptions(
          geometry: points[i].point,
          circleColor: _hexForRole(
            routeRoleAt(i, points.length, isRoundTrip: isRoundTrip),
          ),
          circleRadius: 8,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
    ];
    _routeMarkers.addAll(await controller.addCircles(options));
  }

  Future<void> _syncRouteLine() {
    final previous = _lineSyncFuture ?? Future.value();
    final next = previous.then((_) => _doSyncRouteLine());
    _lineSyncFuture = next;
    return next;
  }

  Future<void> _doSyncRouteLine() async {
    final controller = _mapController;
    if (controller == null) return;
    final existing = _routeLine;
    if (existing != null) {
      await controller.removeLine(existing);
      _routeLine = null;
    }
    final path = widget.viewModel.routePath;
    if (path == null || path.length < 2) return;
    _routeLine = await controller.addLine(
      LineOptions(
        geometry: path,
        lineColor: '#FF7A00', // AppColors.apexOrange
        lineWidth: 4,
      ),
    );
  }

  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    widget.viewModel.reorderRoutePoints(oldIndex, newIndex);
    await _syncRouteMarkers();
  }

  Future<void> _clearRoutePoints() async {
    widget.viewModel.clearRoutePoints();
    await _syncRouteMarkers();
  }

  Future<void> _removeWaypoint(RoutePoint point) async {
    widget.viewModel.removeWaypoint(point);
    await _syncRouteMarkers();
  }

  Future<void> _setRoundTrip(bool value) async {
    widget.viewModel.setRoundTrip(value);
    await _syncRouteMarkers();
  }

  Future<void> _showRoutePointsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.black,
      isScrollControlled: true,
      // The sheet's own swipe-to-dismiss gesture otherwise competes with
      // the list items' drag-to-reorder gesture for the same vertical
      // drag, breaking reordering. The header's back button is the
      // dismiss affordance instead.
      enableDrag: false,
      builder: (context) => _RoutePointsSheet(
        viewModel: widget.viewModel,
        onReorder: _handleReorder,
        onClearAll: _clearRoutePoints,
        onDeleteWaypoint: _removeWaypoint,
        onRoundTripChanged: _setRoundTrip,
      ),
    );
  }

  Future<void> _showSearchMarker(LatLng point) async {
    final controller = _mapController;
    if (controller == null) return;
    final marker = _searchMarker;
    if (marker != null) {
      await controller.updateCircle(marker, CircleOptions(geometry: point));
    } else {
      _searchMarker = await controller.addCircle(
        CircleOptions(
          geometry: point,
          circleColor: '#FF7A00',
          circleRadius: 8,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
    }
    await controller.animateCamera(CameraUpdate.newLatLng(point));
  }

  Future<void> _recenterToCurrentLocation() async {
    final controller = _mapController;
    final marker = _searchMarker;
    if (controller != null && marker != null) {
      await controller.removeCircle(marker);
      _searchMarker = null;
    }
    final location = widget.viewModel.location;
    if (controller != null && location != null) {
      await controller.animateCamera(CameraUpdate.newLatLng(location));
    }
  }

  Future<void> _showLocationMenu(Offset position) async {
    final localization = AppLocalization.of(context);
    final hasRoutePoints = widget.viewModel.routePoints.isNotEmpty;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<_LocationMenuAction>(
      context: context,
      color: AppColors.black,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: _LocationMenuAction.currentPosition,
          child: Text(
            localization.currentPosition,
            style: const TextStyle(color: AppColors.white),
          ),
        ),
        PopupMenuItem(
          enabled: hasRoutePoints,
          value: _LocationMenuAction.routeStart,
          child: Text(
            localization.routeStart,
            style: TextStyle(
              color: hasRoutePoints ? AppColors.white : AppColors.grey3,
            ),
          ),
        ),
        PopupMenuItem(
          enabled: hasRoutePoints,
          value: _LocationMenuAction.routeEnd,
          child: Text(
            localization.routeEnd,
            style: TextStyle(
              color: hasRoutePoints ? AppColors.white : AppColors.grey3,
            ),
          ),
        ),
        PopupMenuItem(
          enabled: hasRoutePoints,
          value: _LocationMenuAction.completeRoute,
          child: Text(
            localization.completeRoute,
            style: TextStyle(
              color: hasRoutePoints ? AppColors.white : AppColors.grey3,
            ),
          ),
        ),
      ],
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case _LocationMenuAction.currentPosition:
        await _recenterToCurrentLocation();
      case _LocationMenuAction.routeStart:
        await _centerOnPoint(widget.viewModel.routePoints.first.point);
      case _LocationMenuAction.routeEnd:
        await _centerOnPoint(widget.viewModel.routePoints.last.point);
      case _LocationMenuAction.completeRoute:
        await _fitRouteBounds();
    }
  }

  Future<void> _centerOnPoint(LatLng point) async {
    await _mapController?.animateCamera(CameraUpdate.newLatLng(point));
  }

  Future<void> _fitRouteBounds() async {
    final controller = _mapController;
    final points = widget.viewModel.routePoints;
    if (controller == null || points.isEmpty) return;
    var minLat = points.first.point.latitude;
    var maxLat = points.first.point.latitude;
    var minLng = points.first.point.longitude;
    var maxLng = points.first.point.longitude;
    for (final routePoint in points.skip(1)) {
      final lat = routePoint.point.latitude;
      final lng = routePoint.point.longitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        left: 48,
        top: 48,
        right: 48,
        bottom: 48,
      ),
    );
  }

  Future<void> _onPickHouseNumber(SearchResultItem item) async {
    final houseNumber = await showDialog<String>(
      context: context,
      builder: (context) => _HouseNumberDialog(street: item),
    );
    if (houseNumber == null || houseNumber.trim().isEmpty || !mounted) {
      return;
    }

    await widget.viewModel.resolveHouseNumber.execute((
      street: item,
      houseNumber: houseNumber.trim(),
      language: Localizations.localeOf(context).languageCode,
    ));
    if (!mounted) return;

    final result = widget.viewModel.resolveHouseNumber.result;
    if (result is Ok<SearchResultItem>) {
      _applySelection(
        _resolvedAddressLabel(item, result.value),
        LatLng(result.value.lat, result.value.lon),
      );
    } else {
      // Best-effort fallback: nothing usable came back for this street.
      _selectStreet(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalization.of(context).houseNumberNotFound),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final dimens = Dimens.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      resizeToAvoidBottomInset: false,
      appBar: const BrandedAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.black,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    // Placeholder until the navigation drawer is implemented.
                    onPressed: () {},
                    icon: const Icon(Icons.menu, color: AppColors.grey3),
                  ),
                  Expanded(
                    child: AppTextField(
                      controller: _searchController,
                      hintText: localization.search,
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: _searchController.clear,
                          );
                        },
                      ),
                    ),
                  ),
                  ProfileMenuButton(
                    onLogout: () => widget.viewModel.logout.execute(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.viewModel.loadMap,
                builder: (context, _) {
                  final location = widget.viewModel.location;
                  final mapStyle = widget.viewModel.mapStyle;
                  if (location == null || mapStyle == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Stack(
                    children: [
                      MapLibreMap(
                        styleString: mapStyle,
                        initialCameraPosition: CameraPosition(
                          target: location,
                          zoom: 15,
                        ),
                        myLocationEnabled: true,
                        myLocationRenderMode: MyLocationRenderMode.normal,
                        // The compass mockup doesn't include one, and the
                        // default icon renders as a clipped half-circle on
                        // high-density displays (upstream maplibre rendering
                        // issue), so disable it.
                        compassEnabled: false,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _syncRouteMarkers();
                          _syncRouteLine();
                        },
                      ),
                      Positioned(
                        left: dimens.paddingScreenHorizontal,
                        bottom: dimens.paddingScreenVertical,
                        child: ListenableBuilder(
                          listenable: widget.viewModel,
                          builder: (context, _) {
                            final count = widget.viewModel.routePoints.length;
                            return Badge(
                              label: Text('$count'),
                              isLabelVisible: count > 0,
                              child: CircleIconButton(
                                icon: Icons.route,
                                onPressed: _showRoutePointsSheet,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: dimens.paddingScreenVertical,
                        child: Center(
                          child: VehicleTypePill(
                            label: localization.standardMotorcycle,
                            onTap: () {},
                          ),
                        ),
                      ),
                      Positioned(
                        right: dimens.paddingScreenHorizontal,
                        bottom: dimens.paddingScreenVertical,
                        child: GestureDetector(
                          onLongPressStart: (details) =>
                              _showLocationMenu(details.globalPosition),
                          child: CircleIconButton(
                            icon: Icons.my_location,
                            onPressed: _recenterToCurrentLocation,
                          ),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: widget.viewModel,
                        builder: (context, _) {
                          final suggestions = widget.viewModel.suggestions;
                          if (suggestions.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: _SuggestionsList(
                              suggestions: suggestions,
                              onSelected: _selectStreet,
                              onPickHouseNumber: _onPickHouseNumber,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({
    required this.suggestions,
    required this.onSelected,
    required this.onPickHouseNumber,
  });

  final List<SearchResultItem> suggestions;
  final ValueChanged<SearchResultItem> onSelected;
  final ValueChanged<SearchResultItem> onPickHouseNumber;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.black,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, thickness: 1, color: AppColors.darkGrey),
        itemBuilder: (context, index) {
          final item = suggestions[index];
          final subtitleText = [
            item.locality,
            item.country,
          ].where((part) => part.isNotEmpty).join(', ');
          final hasStreetText = item.street?.trim().isNotEmpty ?? false;
          // Only address-layer rows have a housenumber baked into their
          // label (the backend's arbitrary "best match" pick) — strip it
          // there so the title matches what tapping the row will search
          // for. Rows without a parsed `street` (e.g. a venue whose name
          // merely mentions a street) never had one to begin with, and
          // have no street to search a house number on either.
          final isMislabeledAddress = item.layer == 'address' && hasStreetText;
          return ListTile(
            leading: const Icon(Icons.location_on, color: AppColors.grey3),
            title: Text(
              isMislabeledAddress ? _streetLabel(item) : item.label,
              style: const TextStyle(color: AppColors.white),
            ),
            subtitle: (hasStreetText || subtitleText.isNotEmpty)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (subtitleText.isNotEmpty)
                        Text(
                          subtitleText,
                          style: const TextStyle(color: AppColors.grey3),
                        ),
                      if (hasStreetText)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: OutlinedButton(
                            onPressed: () => onPickHouseNumber(item),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.apexOrange,
                              side: const BorderSide(
                                color: AppColors.apexOrange,
                              ),
                            ),
                            child: Text(
                              AppLocalization.of(context).houseNumber,
                            ),
                          ),
                        ),
                    ],
                  )
                : null,
            onTap: () => onSelected(item),
          );
        },
      ),
    );
  }
}

/// Collects a house number for [street]; pops with the entered text, or
/// null when dismissed.
class _HouseNumberDialog extends StatefulWidget {
  const _HouseNumberDialog({required this.street});

  final SearchResultItem street;

  @override
  State<_HouseNumberDialog> createState() => _HouseNumberDialogState();
}

class _HouseNumberDialogState extends State<_HouseNumberDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return AlertDialog(
      title: Text(widget.street.street ?? widget.street.label),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: localization.houseNumberPrompt),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localization.close),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(localization.confirm),
        ),
      ],
    );
  }
}

/// Offers a choice of route role for a just-selected point, shown after
/// the map jumps to it. Which rows appear depends on the current route
/// state: "Set as destination" is always offered; "Set as start point"
/// only while the route is empty; "Set as waypoint" only once a start and
/// destination already exist.
class _RoleSheet extends StatelessWidget {
  const _RoleSheet({required this.routePointCount});

  final int routePointCount;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final showStart = routePointCount == 0;
    final showWaypoint = routePointCount >= 2;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoleSheetTile(
            icon: Icons.flag,
            label: localization.setAsDestination,
            onTap: () => Navigator.pop(context, RouteRole.destination),
          ),
          if (showStart)
            _RoleSheetTile(
              icon: Icons.trip_origin,
              label: localization.setAsStartPoint,
              onTap: () => Navigator.pop(context, RouteRole.start),
            ),
          if (showWaypoint)
            _RoleSheetTile(
              icon: Icons.add_location_alt,
              label: localization.setAsWaypoint,
              onTap: () => Navigator.pop(context, RouteRole.waypoint),
            ),
        ],
      ),
    );
  }
}

class _RoleSheetTile extends StatelessWidget {
  const _RoleSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.white),
    title: Text(label, style: const TextStyle(color: AppColors.white)),
    onTap: onTap,
  );
}

/// Lists the current route points, reorderable by drag-and-drop, with a
/// header offering back / save (not yet implemented) / clear-all actions.
class _RoutePointsSheet extends StatelessWidget {
  const _RoutePointsSheet({
    required this.viewModel,
    required this.onReorder,
    required this.onClearAll,
    required this.onDeleteWaypoint,
    required this.onRoundTripChanged,
  });

  final HomeViewModel viewModel;
  final Future<void> Function(int oldIndex, int newIndex) onReorder;
  final Future<void> Function() onClearAll;
  final Future<void> Function(RoutePoint point) onDeleteWaypoint;
  final ValueChanged<bool> onRoundTripChanged;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final points = viewModel.routePoints;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    tooltip: localization.routePointsBack,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save, color: AppColors.white),
                    tooltip: localization.routePointsSave,
                    onPressed: () {}, // Not implemented yet.
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            localization.roundTrip,
                            style: const TextStyle(color: AppColors.white),
                          ),
                          Switch(
                            value: viewModel.isRoundTrip,
                            activeThumbColor: AppColors.apexOrange,
                            onChanged: onRoundTripChanged,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.white),
                    tooltip: localization.routePointsClearAll,
                    onPressed: () async {
                      await onClearAll();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              if (points.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    localization.noRoutePointsYet,
                    style: const TextStyle(color: AppColors.white),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    localization.routePointsTitle,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.6,
                  ),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    itemCount: points.length,
                    onReorderItem: onReorder,
                    // Reordering starts only from the explicit trailing
                    // handle below, rather than a long-press anywhere on
                    // the row — that leaves long-press free for the
                    // waypoint delete menu without the two gestures
                    // fighting over the same touch.
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final point = points[index];
                      final role = routeRoleAt(
                        index,
                        points.length,
                        isRoundTrip: viewModel.isRoundTrip,
                      );
                      final tile = ListTile(
                        leading: Icon(
                          _iconForRole(role),
                          color: AppColors.white,
                        ),
                        title: Text(
                          point.isCurrentLocation
                              ? localization.currentLocation
                              : point.label,
                          style: const TextStyle(color: AppColors.white),
                        ),
                        subtitle: Text(
                          _labelForRole(localization, role),
                          style: const TextStyle(color: AppColors.grey3),
                        ),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(
                            Icons.drag_handle,
                            color: AppColors.grey3,
                          ),
                        ),
                      );
                      return GestureDetector(
                        key: ObjectKey(point),
                        behavior: HitTestBehavior.opaque,
                        onLongPressStart: role == RouteRole.waypoint
                            ? (details) => _showDeleteWaypointMenu(
                                context,
                                details.globalPosition,
                                point,
                              )
                            : null,
                        child: tile,
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _showDeleteWaypointMenu(
    BuildContext context,
    Offset position,
    RoutePoint point,
  ) async {
    final localization = AppLocalization.of(context);
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<bool>(
      context: context,
      color: AppColors.black,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: true,
          child: Row(
            children: [
              const Icon(Icons.delete, color: AppColors.white),
              const SizedBox(width: 12),
              Text(
                localization.deleteWaypoint,
                style: const TextStyle(color: AppColors.white),
              ),
            ],
          ),
        ),
      ],
    );
    if (selected == true) {
      await onDeleteWaypoint(point);
    }
  }
}

IconData _iconForRole(RouteRole role) => switch (role) {
  RouteRole.start => Icons.trip_origin,
  RouteRole.destination => Icons.flag,
  RouteRole.waypoint => Icons.add_location_alt,
};

String _labelForRole(AppLocalization localization, RouteRole role) =>
    switch (role) {
      RouteRole.start => localization.routeRoleStart,
      RouteRole.destination => localization.routeRoleDestination,
      RouteRole.waypoint => localization.routeRoleWaypoint,
    };

String _hexForRole(RouteRole role) => switch (role) {
  RouteRole.start => '#22C55E', // AppColors.green
  RouteRole.destination => '#EF4444', // AppColors.red
  RouteRole.waypoint => '#0F4C5C', // AppColors.deepPetrolBlue
};
