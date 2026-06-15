import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/auth_prompt.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/resend_email_button.dart';
import '../../core/ui/screen_title.dart';
import '../../reset_password/view_models/reset_password_viewmodel.dart';

class ResetPasswordConfirmationScreen extends StatelessWidget {
  const ResetPasswordConfirmationScreen({
    super.key,
    required this.email,
    required this.viewModel,
  });

  final String email;
  final ResetPasswordViewModel viewModel;

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
          ScreenTitle(text: localization.resetPassword),
          const SizedBox(height: Dimens.paddingVertical * 2),
          Text(
            localization.passwordResetEmailSentTo(email),
            style: bodyStyle,
          ),
          const SizedBox(height: Dimens.paddingVertical),
          Text(localization.noEmailReceived, style: bodyStyle),
          const SizedBox(height: Dimens.paddingVertical / 2),
          ResendEmailButton(
            label: localization.resendEmail,
            command: viewModel.requestReset,
            onPressed: () => viewModel.requestReset.execute(email),
            startCooldownOnInit: true,
          ),
          const SizedBox(height: Dimens.paddingVertical * 4),
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
