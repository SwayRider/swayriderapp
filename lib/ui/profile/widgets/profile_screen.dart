import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/branded_app_bar.dart';
import '../../core/ui/primary_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _onChangePasswordPressed(BuildContext context) async {
    final localization = AppLocalization.of(context);
    final changed = await context.push<bool>(Routes.changePassword);
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.passwordChangedMessage)),
      );
    }
  }

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
                    localization.profile,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left, color: AppColors.grey3),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: Dimens.of(context).edgeInsetsScreenSymetric,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  PrimaryButton(
                    label: localization.changePassword,
                    onPressed: () => _onChangePasswordPressed(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
