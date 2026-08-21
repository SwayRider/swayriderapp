import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/branded_app_bar.dart';
import '../../core/ui/primary_button.dart';
import '../view_models/mfa_profile_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.viewModel});

  final MfaProfileViewModel viewModel;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load.execute();
  }

  Future<void> _onChangePasswordPressed(BuildContext context) async {
    final localization = AppLocalization.of(context);
    final changed = await context.push<bool>(Routes.changePassword);
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.passwordChangedMessage)),
      );
    }
  }

  Future<void> _onEnablePressed(BuildContext context) async {
    final localization = AppLocalization.of(context);
    final enabled = await context.push<bool>(Routes.mfaSetup);
    if (enabled == true && context.mounted) {
      await widget.viewModel.load.execute();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.mfaEnableSuccess)),
      );
    }
  }

  Future<void> _onDisablePressed(BuildContext context) async {
    final localization = AppLocalization.of(context);
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _DisableMfaPasswordDialog(),
    );
    if (password == null || !context.mounted) return;
    await widget.viewModel.disable.execute(password);
    if (!context.mounted) return;
    if (widget.viewModel.disable.completed) {
      await widget.viewModel.load.execute();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.mfaDisableSuccess)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.mfaDisableFailed)),
      );
    }
  }

  Widget _mfaSection(BuildContext context) {
    final localization = AppLocalization.of(context);
    final theme = Theme.of(context);
    final viewModel = widget.viewModel;

    return ListenableBuilder(
      listenable: Listenable.merge([viewModel.load, viewModel.disable]),
      builder: (context, _) {
        final enabled = viewModel.enabled;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localization.twoFactorAuthentication,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimens.paddingVertical / 2),
            if (viewModel.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(Dimens.paddingVertical / 2),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Text(
                enabled == true
                    ? localization.mfaEnabled
                    : localization.mfaDisabled,
              ),
              const SizedBox(height: Dimens.paddingVertical / 2),
              PrimaryButton(
                label: enabled == true
                    ? localization.disableTwoFactor
                    : localization.enableTwoFactor,
                loading: viewModel.disable.running,
                onPressed: enabled == true
                    ? () => _onDisablePressed(context)
                    : () => _onEnablePressed(context),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localization = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: const BrandedAppBar(),
      body: Column(
        children: [
          Container(
            color: AppColors.black,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  // Placeholder until the navigation drawer is implemented.
                  onPressed: () {},
                  icon: const Icon(Icons.menu, color: AppColors.grey3),
                ),
                Expanded(
                  child: Text(
                    localization.profile,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left, color: AppColors.grey3),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: Dimens.of(context).edgeInsetsScreenSymetric,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  PrimaryButton(
                    label: localization.changePassword,
                    onPressed: () => _onChangePasswordPressed(context),
                  ),
                  const SizedBox(height: Dimens.paddingVertical),
                  _mfaSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collects the account password required to disable two-factor
/// authentication; pops with the entered password, or null when dismissed.
class _DisableMfaPasswordDialog extends StatefulWidget {
  const _DisableMfaPasswordDialog();

  @override
  State<_DisableMfaPasswordDialog> createState() =>
      _DisableMfaPasswordDialogState();
}

class _DisableMfaPasswordDialogState extends State<_DisableMfaPasswordDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return AlertDialog(
      title: Text(localization.mfaDisablePasswordPrompt),
      content: TextField(
        controller: _passwordController,
        obscureText: true,
        autofocus: true,
        decoration: InputDecoration(labelText: localization.password),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localization.close),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_passwordController.text),
          child: Text(localization.confirm),
        ),
      ],
    );
  }
}
