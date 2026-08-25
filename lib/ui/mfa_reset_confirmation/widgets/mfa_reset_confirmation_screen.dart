import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/auth_prompt.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/screen_title.dart';

/// Shown after a successful `RequestMfaReset` call. Unlike the
/// password-reset confirmation screen, this has no "resend" action: the
/// backup code that got the user here was already consumed (single-use), so
/// resubmitting the same one would just fail. If the email doesn't arrive,
/// the user needs a fresh backup code, so "try again" goes back to the
/// request form rather than replaying the same request.
class MfaResetConfirmationScreen extends StatelessWidget {
  const MfaResetConfirmationScreen({super.key, required this.email});

  final String email;

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
          ScreenTitle(text: localization.mfaResetRequestTitle),
          const SizedBox(height: Dimens.paddingVertical * 2),
          Text(localization.mfaResetEmailSentTo(email), style: bodyStyle),
          const SizedBox(height: Dimens.paddingVertical * 4),
          AuthPrompt(
            text: localization.noEmailReceived,
            buttonLabel: localization.mfaResetRequestTryAgain,
            onPressed: () => context.go(Routes.mfaResetRequest),
          ),
          const SizedBox(height: Dimens.paddingVertical * 2),
          AuthPrompt(
            text: localization.rememberPassword,
            buttonLabel: localization.login,
            onPressed: () => context.go(Routes.login),
          ),
        ],
      ),
    );
  }
}
