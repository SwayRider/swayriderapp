import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../data/services/api/model/search/search_result_item.dart';
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

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadMap.execute();
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    widget.viewModel.onSearchChanged(
      _searchController.text,
      language: Localizations.localeOf(context).languageCode,
    );
  }

  void _selectStreet(SearchResultItem item) =>
      _applySelection(_streetLabel(item), LatLng(item.lat, item.lon));

  void _applySelection(String text, LatLng point) {
    _searchController.text = text;
    widget.viewModel.clearSuggestions();
    FocusScope.of(context).unfocus();
    _showSearchMarker(point);
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
                        onMapCreated: (controller) =>
                            _mapController = controller,
                      ),
                      Positioned(
                        left: dimens.paddingScreenHorizontal,
                        bottom: dimens.paddingScreenVertical,
                        child: CircleIconButton(
                          icon: Icons.add,
                          backgroundColor: AppColors.apexOrange,
                          iconColor: Colors.white,
                          onPressed: () {},
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
                        child: CircleIconButton(
                          icon: Icons.my_location,
                          onPressed: _recenterToCurrentLocation,
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
