import 'package:flutter/material.dart';

import '../../core/localization/applocalization.dart';
import '../../core/themes/colors.dart';
import '../../core/ui/branded_app_bar.dart';
import '../view_models/home_viewmodel.dart';

enum _ProfileMenuAction { profile, logout }

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localization = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: const BrandedAppBar(),
      body: Column(
        children: [
          Container(
            color: AppColors.black,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  // Placeholder until the navigation drawer is implemented.
                  onPressed: () {},
                  icon: const Icon(Icons.menu, color: AppColors.grey3),
                ),
                Expanded(
                  child: Text(
                    localization.dashboard,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<_ProfileMenuAction>(
                  icon: const Icon(Icons.account_circle, color: AppColors.grey3),
                  color: AppColors.black,
                  onSelected: (action) {
                    switch (action) {
                      case _ProfileMenuAction.profile:
                        break; // Placeholder until /profile is implemented.
                      case _ProfileMenuAction.logout:
                        viewModel.logout.execute();
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
            child: Center(
              child: Text(localization.comingSoon, style: textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
