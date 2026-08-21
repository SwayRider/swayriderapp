import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/applocalization.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_text_field.dart';
import '../../core/ui/branded_scaffold.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/screen_title.dart';
import '../view_models/mfa_setup_viewmodel.dart';

/// Groups a base32 secret into 4-character blocks, uppercased, e.g.
/// `ABCD EFGH IJKL MNOP QRST UVWX YZ12 3456`.
String _formatSecret(String secret) {
  final upper = secret.toUpperCase().replaceAll(' ', '');
  final buffer = StringBuffer();
  for (var i = 0; i < upper.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(upper[i]);
  }
  return buffer.toString();
}

class MfaSetupScreen extends StatefulWidget {
  const MfaSetupScreen({super.key, required this.viewModel});

  final MfaSetupViewModel viewModel;

  @override
  State<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends State<MfaSetupScreen> {
  final _codeController = TextEditingController();

  // 0 intro, 1 key + QR, 2 code entry, 3 backup codes.
  int _step = 0;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startSetup() async {
    await widget.viewModel.startSetup.execute(null);
    if (!mounted) return;
    if (widget.viewModel.startSetup.completed) {
      setState(() => _step = 1);
    }
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    await widget.viewModel.enable.execute(_codeController.text.trim());
    if (!mounted) return;
    if (widget.viewModel.enable.completed) {
      setState(() => _step = 3);
    }
  }

  Future<void> _copyKey() async {
    final info = widget.viewModel.setupInfo;
    if (info == null) return;
    await Clipboard.setData(ClipboardData(text: info.secret));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalization.of(context).keyCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return BrandedScaffold(
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.viewModel.startSetup,
          widget.viewModel.enable,
        ]),
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Dimens.paddingVertical * 2),
              ScreenTitle(text: localization.mfaSetupTitle),
              const SizedBox(height: Dimens.paddingVertical * 2),
              switch (_step) {
                1 => _keyAndQrStep(context),
                2 => _codeEntryStep(context),
                3 => _backupCodesStep(context),
                _ => _introStep(context),
              },
            ],
          );
        },
      ),
    );
  }

  Widget _introStep(BuildContext context) {
    final localization = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localization.mfaSetupIntro,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: Dimens.paddingVertical * 2),
        PrimaryButton(
          label: localization.startSetup,
          loading: widget.viewModel.startSetup.running,
          onPressed: _startSetup,
        ),
        if (widget.viewModel.startSetup.error) ...[
          const SizedBox(height: Dimens.paddingVertical),
          ErrorMessage(text: localization.mfaSetupFailed),
        ],
      ],
    );
  }

  Widget _keyAndQrStep(BuildContext context) {
    final localization = AppLocalization.of(context);
    final theme = Theme.of(context);
    final info = widget.viewModel.setupInfo;
    if (info == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(localization.mfaSecretKey, style: theme.textTheme.titleMedium),
        const SizedBox(height: Dimens.paddingVertical / 2),
        Container(
          padding: const EdgeInsets.all(Dimens.paddingVertical / 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: AppColors.black1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _formatSecret(info.secret),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: Dimens.paddingVertical / 2),
        PrimaryButton(
          label: localization.copyKey,
          onPressed: _copyKey,
        ),
        const SizedBox(height: Dimens.paddingVertical),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(
              base64Decode(info.qrPngBase64),
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: Dimens.paddingVertical / 2),
        Text(
          localization.mfaQrHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Dimens.paddingVertical),
        PrimaryButton(
          label: localization.mfaAddedKey,
          onPressed: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  Widget _codeEntryStep(BuildContext context) {
    final localization = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _codeController,
          hintText: localization.mfaCodeLabel,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: Dimens.paddingVertical),
        PrimaryButton(
          label: localization.verify,
          loading: widget.viewModel.enable.running,
          onPressed: _verify,
        ),
        if (widget.viewModel.invalidCode) ...[
          const SizedBox(height: Dimens.paddingVertical),
          ErrorMessage(text: localization.mfaInvalidCode),
        ],
      ],
    );
  }

  Widget _backupCodesStep(BuildContext context) {
    final localization = AppLocalization.of(context);
    final theme = Theme.of(context);
    final codes = widget.viewModel.backupCodes ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localization.mfaBackupCodesIntro,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: Dimens.paddingVertical),
        Container(
          padding: const EdgeInsets.all(Dimens.paddingVertical / 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: AppColors.black1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              for (final code in codes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    code,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Dimens.paddingVertical / 2),
        Text(
          localization.mfaBackupCodesShownOnce,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: Dimens.paddingVertical),
        PrimaryButton(
          label: localization.mfaBackupCodesSaved,
          onPressed: () => context.pop(true),
        ),
      ],
    );
  }
}
