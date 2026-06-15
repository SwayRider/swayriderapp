import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/auth_prompt.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/resend_email_button.dart';
import '../../core/ui/screen_title.dart';
import '../view_models/verify_email_viewmodel.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.email, required this.viewModel});

  final String? email;
  final VerifyEmailViewModel viewModel;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.resendVerification.execute();
  }

  Future<void> _backToLogin() async {
    await widget.viewModel.logout.execute();
    if (mounted) context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.primary,
    );
    final localization = AppLocalization.of(context);
    final viewModel = widget.viewModel;

    return BrandedScaffold(
      body: ListenableBuilder(
        listenable: viewModel.resendVerification,
        builder: (context, _) {
          final error = viewModel.resendVerification.error;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Dimens.paddingVertical * 2),
              ScreenTitle(text: localization.verifyEmail),
              const SizedBox(height: Dimens.paddingVertical * 2),
              Text(
                localization.verificationEmailSentTo(
                  widget.email ?? localization.yourEmailAddress,
                ),
                style: bodyStyle,
              ),
              const SizedBox(height: Dimens.paddingVertical),
              Text(localization.noEmailReceived, style: bodyStyle),
              const SizedBox(height: Dimens.paddingVertical / 2),
              ResendEmailButton(
                label: localization.resendEmail,
                command: viewModel.resendVerification,
                onPressed: () => viewModel.resendVerification.execute(),
              ),
              if (error) ...[
                const SizedBox(height: Dimens.paddingVertical / 2),
                ErrorMessage(text: localization.resendVerificationFailed),
              ],
              const SizedBox(height: Dimens.paddingVertical * 4),
              AuthPrompt(
                text: localization.alreadyVerified,
                buttonLabel: localization.login,
                onPressed: _backToLogin,
              ),
            ],
          );
        },
      ),
    );
  }
}
