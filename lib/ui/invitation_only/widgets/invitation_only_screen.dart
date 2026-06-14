import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/app_config.dart';
import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/auth_prompt.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_title.dart';

class InvitationOnlyScreen extends StatelessWidget {
  const InvitationOnlyScreen({super.key});

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
          ScreenTitle(text: localization.invitationOnly),
          const SizedBox(height: Dimens.paddingVertical * 2),
          Text(localization.invitationOnlyMessage, style: bodyStyle),
          if (AppConfig.homepageUrl.isNotEmpty) ...[
            const SizedBox(height: Dimens.paddingVertical),
            PrimaryButton(
              label: localization.visitHomepage,
              onPressed: () => launchUrl(Uri.parse(AppConfig.homepageUrl)),
            ),
          ],
          const SizedBox(height: Dimens.paddingVertical * 4),
          AuthPrompt(
            text: localization.haveAccount,
            buttonLabel: localization.login,
            onPressed: () => context.go(Routes.login),
          ),
        ],
      ),
    );
  }
}
