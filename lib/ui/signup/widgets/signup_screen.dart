import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_text_field.dart';
import '../../core/ui/auth_prompt.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/password_strength_fields.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_title.dart';
import '../view_models/signup_viewmodel.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.viewModel});

  final SignupViewModel viewModel;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordMismatch = false;
  bool _passwordTooWeak = false;
  bool? _isPasswordStrong;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _passwordMismatch = true;
        _passwordTooWeak = false;
      });
      return;
    }

    if (_isPasswordStrong == false) {
      setState(() {
        _passwordMismatch = false;
        _passwordTooWeak = true;
      });
      return;
    }

    setState(() {
      _passwordMismatch = false;
      _passwordTooWeak = false;
    });

    final email = _emailController.text.trim();
    await widget.viewModel.signup.execute((email, _passwordController.text));

    if (!mounted) return;
    if (widget.viewModel.signup.completed) {
      context.go(Routes.verifyEmail, extra: email);
    } else if (widget.viewModel.invitationRequired) {
      context.go(Routes.invitationOnly);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return BrandedScaffold(
      body: ListenableBuilder(
        listenable: widget.viewModel.signup,
        builder: (context, _) {
          final loading = widget.viewModel.signup.running;
          final hasError =
              widget.viewModel.signup.error &&
              !widget.viewModel.invitationRequired &&
              !widget.viewModel.passwordTooWeak;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Dimens.paddingVertical * 2),
              ScreenTitle(text: localization.signup),
              const SizedBox(height: Dimens.paddingVertical * 2),
              AppTextField(
                controller: _emailController,
                hintText: localization.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: Dimens.paddingVertical),
              PasswordStrengthFields(
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                checkPasswordStrength: widget.viewModel.checkPasswordStrength,
                onStrengthChanged: (isStrong) =>
                    setState(() => _isPasswordStrong = isStrong),
                onConfirmPasswordSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Dimens.paddingVertical),
              PrimaryButton(
                label: localization.signup,
                loading: loading,
                onPressed: _submit,
              ),
              if (_passwordMismatch) ...[
                const SizedBox(height: Dimens.paddingVertical),
                ErrorMessage(text: localization.passwordsDoNotMatch),
              ],
              if (_passwordTooWeak ||
                  widget.viewModel.passwordTooWeak) ...[
                const SizedBox(height: Dimens.paddingVertical),
                ErrorMessage(text: localization.passwordNotStrongEnough),
              ],
              if (hasError) ...[
                const SizedBox(height: Dimens.paddingVertical),
                ErrorMessage(text: localization.signupFailed),
              ],
              const SizedBox(height: Dimens.paddingVertical * 4),
              AuthPrompt(
                text: localization.haveAccount,
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
