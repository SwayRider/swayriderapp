import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../localization/applocalization.dart';
import '../themes/colors.dart';

enum _ProfileMenuAction { profile, account, logout }

/// Person-icon popup menu (Profile / Account / Logout) shared by the home
/// screen and every [SectionScaffold]-based screen, so any of those pages
/// can be reached directly from any other without detouring through Home.
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key, required this.onLogout});

  /// Invoked when Logout is selected. Callers own how logout is performed
  /// (e.g. via a view model's Command) since that varies by screen.
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return PopupMenuButton<_ProfileMenuAction>(
      icon: const Icon(Icons.account_circle, color: AppColors.grey3),
      color: AppColors.black,
      onSelected: (action) {
        switch (action) {
          case _ProfileMenuAction.profile:
            context.push(Routes.profile);
          case _ProfileMenuAction.account:
            context.push(Routes.account);
          case _ProfileMenuAction.logout:
            onLogout();
        }
      },
      itemBuilder: (context) => [
        _item(
          _ProfileMenuAction.profile,
          Icons.person_outline,
          localization.profile,
        ),
        _item(
          _ProfileMenuAction.account,
          Icons.manage_accounts,
          localization.account,
        ),
        _item(_ProfileMenuAction.logout, Icons.logout, localization.logout),
      ],
    );
  }

  PopupMenuItem<_ProfileMenuAction> _item(
    _ProfileMenuAction value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.white),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.white)),
        ],
      ),
    );
  }
}
