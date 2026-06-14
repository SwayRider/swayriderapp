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
import '../view_models/login_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    widget.viewModel.login.execute((
      _emailController.text.trim(),
      _passwordController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return BrandedScaffold(
      body: ListenableBuilder(
        listenable: widget.viewModel.login,
        builder: (context, _) {
          final loading = widget.viewModel.login.running;
          final hasError = widget.viewModel.login.error;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Dimens.paddingVertical * 2),
              ScreenTitle(text: localization.login),
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Dimens.paddingVertical),
              PrimaryButton(
                label: localization.login,
                loading: loading,
                onPressed: _submit,
              ),
              if (hasError) ...[
                const SizedBox(height: Dimens.paddingVertical),
                ErrorMessage(text: localization.invalidLogin),
                const SizedBox(height: Dimens.paddingVertical),
                AuthPrompt(
                  text: localization.forgotPassword,
                  buttonLabel: localization.resetPassword,
                  spacing: Dimens.paddingVertical / 2,
                  // Placeholder until /reset-password is implemented.
                  onPressed: () {},
                ),
              ],
              const SizedBox(height: Dimens.paddingVertical * 4),
              AuthPrompt(
                text: localization.noAccount,
                buttonLabel: localization.signup,
                onPressed: () => context.go(Routes.signup),
              ),
            ],
          );
        },
      ),
    );
  }
}
