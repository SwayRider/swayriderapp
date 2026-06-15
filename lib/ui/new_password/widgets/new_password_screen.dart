import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/password_strength_fields.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_title.dart';
import '../view_models/new_password_viewmodel.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({
    super.key,
    required this.userId,
    required this.token,
    required this.viewModel,
  });

  final String userId;
  final String token;
  final NewPasswordViewModel viewModel;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _passwordMismatch = false;
  bool _passwordTooWeak = false;
  bool? _isPasswordStrong;

  @override
  void dispose() {
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

    await widget.viewModel.resetPassword.execute((
      widget.userId,
      widget.token,
      _passwordController.text,
    ));

    if (!mounted) return;
    if (widget.viewModel.resetPassword.completed) {
      context.go(Routes.passwordChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return BrandedScaffold(
      body: ListenableBuilder(
        listenable: widget.viewModel.resetPassword,
        builder: (context, _) {
          final loading = widget.viewModel.resetPassword.running;
          final hasError = widget.viewModel.resetPassword.error;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Dimens.paddingVertical * 2),
              ScreenTitle(text: localization.resetPassword),
              const SizedBox(height: Dimens.paddingVertical * 2),
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
