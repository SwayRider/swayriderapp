import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_title.dart';

// Shown when the router's redirect check can't reach the backend at all
// (a ConnectionException from AuthRepository.isVerified), instead of
// silently treating that as "not verified". See router.dart's _redirect.
class ConnectionIssueScreen extends StatelessWidget {
  const ConnectionIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.primary,
    );
    final localization = AppLocalization.of(context);

    return BrandedScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Dimens.paddingVertical * 2),
          ScreenTitle(text: localization.connectionIssueTitle),
          const SizedBox(height: Dimens.paddingVertical * 2),
          Text(localization.connectionIssueMessage, style: bodyStyle),
          const SizedBox(height: Dimens.paddingVertical * 2),
          // Re-navigating re-runs the router's redirect check, so this
          // naturally proceeds to home/login/verify-email once the
          // connection recovers instead of needing its own retry logic.
          PrimaryButton(
            label: localization.retry,
            onPressed: () => context.go(Routes.home),
          ),
        ],
      ),
    );
  }
}
