import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../routing/routes.dart';
import '../themes/colors.dart';
import '../themes/dimens.dart';
import 'branded_app_bar.dart';
import 'profile_menu_button.dart';

/// Shared shell for pages reached from the home screen's person-icon menu
/// (Profile, Account, and future additions to that menu): a [BrandedAppBar]
/// plus a black toolbar row (placeholder menu icon, centered [title],
/// person-icon menu, back chevron) above a padded [body]. The person-icon
/// menu lets a user jump directly between these pages (e.g. Profile ->
/// Account) without detouring through Home; the back chevron always
/// navigates to Home itself, regardless of how deep that jump made the
/// navigation stack.
class SectionScaffold extends StatelessWidget {
  const SectionScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ProfileMenuButton(
                  onLogout: () => context.read<AuthRepository>().logout(),
                ),
                IconButton(
                  onPressed: () => context.go(Routes.home),
                  icon: const Icon(Icons.chevron_left, color: AppColors.grey3),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: Dimens.of(context).edgeInsetsScreenSymetric,
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
