import 'package:flutter/material.dart';

import '../../core/localization/applocalization.dart';
import '../../core/ui/section_scaffold.dart';

/// Placeholder for now; will hold full name, address, billing information,
/// etc. once those are implemented. Account-related settings (change
/// password, two-factor authentication) live on the Account screen instead.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionScaffold(
      title: AppLocalization.of(context).profile,
      body: const SizedBox.shrink(),
    );
  }
}
