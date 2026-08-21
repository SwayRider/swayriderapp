import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_text_field.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_title.dart';
import '../../../routing/routes.dart';
import '../view_models/mfa_verify_viewmodel.dart';

class MfaVerifyScreen extends StatefulWidget {
  const MfaVerifyScreen({super.key, required this.viewModel});

  final MfaVerifyViewModel viewModel;

  @override
  State<MfaVerifyScreen> createState() => _MfaVerifyScreenState();
}

class _MfaVerifyScreenState extends State<MfaVerifyScreen> {
  final _codeController = TextEditingController();
  bool _useBackupCode = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await widget.viewModel.verify.execute(_codeController.text.trim());
    if (!mounted) return;
    if (widget.viewModel.verify.completed) {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return BrandedScaffold(
      body: ListenableBuilder(
        listenable: widget.viewModel.verify,
        builder: (context, _) {
          final loading = widget.viewModel.verify.running;
          final invalidCode = widget.viewModel.invalidCode;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Dimens.paddingVertical * 2),
              ScreenTitle(text: localization.mfaVerifyTitle),
              const SizedBox(height: Dimens.paddingVertical * 2),
              AppTextField(
                controller: _codeController,
                hintText: _useBackupCode
                    ? localization.mfaUseBackupCode
                    : localization.mfaCodeLabel,
                keyboardType: _useBackupCode
                    ? TextInputType.text
                    : TextInputType.number,
                // TOTP codes are 6 digits; backup codes are 8-9 characters
                // (optionally dash-separated), so the field widens in backup
                // mode. The server accepts either in the same field.
                maxLength: _useBackupCode ? 9 : 6,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Dimens.paddingVertical),
              PrimaryButton(
                label: localization.verify,
                loading: loading,
                onPressed: _submit,
              ),
              if (invalidCode) ...[
                const SizedBox(height: Dimens.paddingVertical),
                ErrorMessage(text: localization.mfaInvalidCode),
              ],
              const SizedBox(height: Dimens.paddingVertical / 2),
              TextButton(
                onPressed: () =>
                    setState(() => _useBackupCode = !_useBackupCode),
                child: Text(
                  _useBackupCode
                      ? localization.mfaUseVerificationCode
                      : localization.mfaUseBackupCode,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
