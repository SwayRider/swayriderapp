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

/// Street + city text for an address result, with no house number — used
/// both for the street-only search box text and an address row's title, so
/// what's shown always matches what tapping the row searches for.
///
/// Belgian municipality names often land in `localAdmin` rather than
/// `locality` (Pelias reserves `locality` for smaller named places), so fall
/// back to it to avoid dropping the city entirely.
String _streetLabel(SearchResultItem item) {
  final city = item.locality.trim().isNotEmpty
      ? item.locality
      : (item.localAdmin ?? '');
  return [
    item.street ?? item.label,
    city,
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
      _applySelection(_streetLabel(item));

  void _selectAddress(SearchResultItem item) => _applySelection(item.label);

  void _applySelection(String text) {
    _searchController.text = text;
    widget.viewModel.clearSuggestions();
    FocusScope.of(context).unfocus();
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
      _selectAddress(result.value);
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
                      suffixIcon: const Icon(Icons.search),
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
                          onPressed: () {},
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: suggestions.length,
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
            final isMislabeledAddress =
                item.layer == 'address' && hasStreetText;
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
                        if (hasStreetText)
                          TextButton(
                            onPressed: () => onPickHouseNumber(item),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.apexOrange,
                            ),
                            child: Text(
                              AppLocalization.of(context).houseNumber,
                            ),
                          ),
                        if (subtitleText.isNotEmpty)
                          Text(
                            subtitleText,
                            style: const TextStyle(color: AppColors.grey3),
                          ),
                      ],
                    )
                  : null,
              onTap: () => onSelected(item),
            );
          },
        ),
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
