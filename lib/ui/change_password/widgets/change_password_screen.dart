import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/password_field.dart';
import '../../core/ui/password_strength_fields.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_title.dart';
import '../view_models/change_password_viewmodel.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.viewModel});

  final ChangePasswordViewModel viewModel;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordMismatch = false;
  bool _passwordTooWeak = false;
  bool? _isPasswordStrong;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_newPasswordController.text != _confirmPasswordController.text) {
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

    await widget.viewModel.changePassword.execute((
      _oldPasswordController.text,
      _newPasswordController.text,
    ));

    if (!mounted) return;
    if (widget.viewModel.changePassword.completed) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.headlineMedium?.copyWith(
      color: theme.colorScheme.primary,
    );

    return BrandedScaffold(
      body: ListenableBuilder(
        listenable: widget.viewModel.changePassword,
        builder: (context, _) {
          final loading = widget.viewModel.changePassword.running;
          final hasError = widget.viewModel.changePassword.error;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Dimens.paddingVertical * 2),
              ScreenTitle(text: localization.changePassword),
              const SizedBox(height: Dimens.paddingVertical * 2),
              Text(localization.oldPassword, style: headerStyle),
              const SizedBox(height: Dimens.paddingVertical / 2),
              PasswordField(
                controller: _oldPasswordController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: Dimens.paddingVertical),
              Text(localization.newPassword, style: headerStyle),
              const SizedBox(height: Dimens.paddingVertical / 2),
              PasswordStrengthFields(
                passwordController: _newPasswordController,
                confirmPasswordController: _confirmPasswordController,
                checkPasswordStrength: widget.viewModel.checkPasswordStrength,
                onStrengthChanged: (isStrong) =>
                    setState(() => _isPasswordStrong = isStrong),
                onConfirmPasswordSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Dimens.paddingVertical),
              PrimaryButton(
                label: localization.changePassword,
                loading: loading,
                onPressed: _submit,
              ),
              if (_passwordMismatch) ...[
                const SizedBox(height: Dimens.paddingVertical),
                ErrorMessage(text: localization.passwordsDoNotMatch),
              ],
              if (_passwordTooWeak) ...[
                const SizedBox(height: Dimens.paddingVertical),
                ErrorMessage(text: localization.passwordNotStrongEnough),
              ],
              if (hasError) ...[
                const SizedBox(height: Dimens.paddingVertical),
                ErrorMessage(text: localization.changePasswordFailed),
              ],
            ],
          );
        },
      ),
    );
  }
}
