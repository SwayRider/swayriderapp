import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_text_field.dart';
import '../../core/ui/branded_app_bar.dart';
import '../../core/ui/circle_icon_button.dart';
import '../../core/ui/vehicle_type_pill.dart';
import '../view_models/home_viewmodel.dart';

enum _ProfileMenuAction { profile, logout }

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final dimens = Dimens.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
                  PopupMenuButton<_ProfileMenuAction>(
                    icon: const Icon(Icons.account_circle, color: AppColors.grey3),
                    color: AppColors.black,
                    onSelected: (action) {
                      switch (action) {
                        case _ProfileMenuAction.profile:
                          context.push(Routes.profile);
                        case _ProfileMenuAction.logout:
                          widget.viewModel.logout.execute();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _ProfileMenuAction.profile,
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, color: AppColors.white),
                            const SizedBox(width: 12),
                            Text(localization.profile, style: const TextStyle(color: AppColors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _ProfileMenuAction.logout,
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: AppColors.white),
                            const SizedBox(width: 12),
                            Text(localization.logout, style: const TextStyle(color: AppColors.white)),
                          ],
                        ),
                      ),
                    ],
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
