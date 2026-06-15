import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_title.dart';

class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key});

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
          ScreenTitle(text: localization.passwordChanged),
          const SizedBox(height: Dimens.paddingVertical * 2),
          Text(localization.passwordChangedMessage, style: bodyStyle),
          const SizedBox(height: Dimens.paddingVertical),
          Text(localization.clickBelowToLogin, style: bodyStyle),
          const SizedBox(height: Dimens.paddingVertical / 2),
          PrimaryButton(
            label: localization.login,
            onPressed: () => context.go(Routes.login),
          ),
        ],
      ),
    );
  }
}
