import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_text_field.dart';
import '../../core/ui/auth_prompt.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/password_field.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_title.dart';
import '../view_models/mfa_reset_request_viewmodel.dart';

class MfaResetRequestScreen extends StatefulWidget {
  const MfaResetRequestScreen({super.key, required this.viewModel});

  final MfaResetRequestViewModel viewModel;

  @override
  State<MfaResetRequestScreen> createState() => _MfaResetRequestScreenState();
}

class _MfaResetRequestScreenState extends State<MfaResetRequestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _backupCodeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _backupCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final backupCode = _backupCodeController.text.trim();
    await widget.viewModel.requestReset.execute((email, password, backupCode));

    if (!mounted) return;
    if (widget.viewModel.requestReset.completed) {
      context.go(Routes.mfaResetConfirmation, extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return BrandedScaffold(
      body: ListenableBuilder(
        listenable: widget.viewModel.requestReset,
        builder: (context, _) {
          final loading = widget.viewModel.requestReset.running;
          final hasError = widget.viewModel.requestReset.error;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Dimens.paddingVertical * 2),
              ScreenTitle(text: localization.mfaResetRequestTitle),
              const SizedBox(height: Dimens.paddingVertical),
              Text(
                localization.mfaResetRequestIntro,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: Dimens.paddingVertical * 2),
              AppTextField(
                controller: _emailController,
                hintText: localization.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: Dimens.paddingVertical),
              PasswordField(
                controller: _passwordController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: Dimens.paddingVertical),
              AppTextField(
                controller: _backupCodeController,
                hintText: localization.mfaResetRequestBackupCodeLabel,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Dimens.paddingVertical),
              PrimaryButton(
                label: localization.mfaResetRequestSubmit,
                loading: loading,
                onPressed: _submit,
              ),
              if (hasError) ...[
                const SizedBox(height: Dimens.paddingVertical),
                ErrorMessage(text: localization.mfaResetRequestFailed),
              ],
              const SizedBox(height: Dimens.paddingVertical * 4),
              AuthPrompt(
                text: localization.rememberPassword,
                buttonLabel: localization.login,
                onPressed: () => context.go(Routes.login),
              ),
            ],
          );
        },
      ),
    );
  }
}
