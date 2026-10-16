import 'package:flutter/material.dart';

import '../../../domain/models/map/map_style_mode.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/colors.dart';
import '../view_models/map_style_view_model.dart';

String mapStyleModeLabel(AppLocalization localization, MapStyleMode mode) =>
    switch (mode) {
      MapStyleMode.day => localization.mapStyleDay,
      MapStyleMode.night => localization.mapStyleNight,
      MapStyleMode.auto => localization.mapStyleAuto,
    };

IconData mapStyleModeIcon(MapStyleMode mode) => switch (mode) {
  MapStyleMode.day => Icons.wb_sunny,
  MapStyleMode.night => Icons.nightlight_round,
  MapStyleMode.auto => Icons.brightness_auto,
};

/// Floating pill on the map showing the current style. The icon is the variant
/// on screen (so Auto shows whether it is currently day or night); the label is
/// the user's choice. Tapping it opens [showMapStyleSheet].
class MapStyleButton extends StatelessWidget {
  const MapStyleButton({
    super.key,
    required this.mode,
    required this.variant,
    required this.onPressed,
  });

  final MapStyleMode mode;
  final MapVariant variant;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final label = mapStyleModeLabel(localization, mode);
    final icon = variant == MapVariant.dark
        ? Icons.nightlight_round
        : Icons.wb_sunny;
    return Semantics(
      button: true,
      label: '${localization.mapStyleTitle}: $label',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: AppColors.black1),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.black1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: AppColors.black1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to pick day, night or auto. Applies the choice at once.
Future<void> showMapStyleSheet(
  BuildContext context, {
  required MapStyleViewModel viewModel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.black,
    builder: (context) => _MapStyleSheet(viewModel: viewModel),
  );
}

class _MapStyleSheet extends StatelessWidget {
  const _MapStyleSheet({required this.viewModel});

  final MapStyleViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  localization.mapStyleTitle,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            for (final mode in MapStyleMode.values)
              ListTile(
                leading: Icon(mapStyleModeIcon(mode), color: AppColors.white),
                title: Text(
                  mapStyleModeLabel(localization, mode),
                  style: const TextStyle(color: AppColors.white),
                ),
                subtitle: mode == MapStyleMode.auto
                    ? Text(
                        viewModel.autoNeedsCamera
                            ? '${localization.mapStyleAutoHint} '
                                  '${localization.mapStyleAutoCameraHint}'
                            : localization.mapStyleAutoHint,
                        style: const TextStyle(color: AppColors.grey3),
                      )
                    : null,
                trailing: viewModel.mode == mode
                    ? const Icon(Icons.check, color: AppColors.apexOrange)
                    : null,
                selected: viewModel.mode == mode,
                onTap: () {
                  viewModel.setMode(mode);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
