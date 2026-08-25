import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../routing/routes.dart';
import '../../core/localization/applocalization.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/error_message.dart';
import '../../core/ui/primary_button.dart';
import '../../core/ui/section_scaffold.dart';
import '../view_models/mfa_profile_viewmodel.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // Owned by this State (not the route builder) so it survives the
  // push/pop into MFA setup: go_router re-invokes GoRoute.builder on every
  // navigation event, which would otherwise hand this screen a fresh,
  // never-loaded view model each time and silently discard any status
  // already confirmed.
  late final MfaProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MfaProfileViewModel(
      authRepository: context.read<AuthRepository>(),
    );
    _viewModel.load.execute();
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
      // Setup only pops `true` after the backend has already confirmed MFA
      // is enabled (it returns backup codes on that same success). Trust
      // that directly instead of re-fetching status: a re-fetch here would
      // race the backend's own read path and can come back stale, which
      // would silently overwrite this known-correct state with "off".
      _viewModel.confirmEnabled();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.mfaEnableSuccess)));
    }
  }

  Future<void> _onDisablePressed(BuildContext context) async {
    final localization = AppLocalization.of(context);
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _DisableMfaPasswordDialog(),
    );
    if (password == null || !context.mounted) return;
    await _viewModel.disable.execute(password);
    if (!context.mounted) return;
    if (_viewModel.disable.completed) {
      await _viewModel.load.execute();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.mfaDisableSuccess)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localization.mfaDisableFailed)));
    }
  }

  Widget _mfaSection(BuildContext context) {
    final localization = AppLocalization.of(context);
    final theme = Theme.of(context);
    final viewModel = _viewModel;

    return ListenableBuilder(
      // `viewModel` itself must be included: confirmEnabled() notifies the
      // view model directly (there's no Command execution to piggyback on),
      // and without listening to it here that notification is silently
      // dropped and the section never rebuilds.
      listenable: Listenable.merge([
        viewModel,
        viewModel.load,
        viewModel.disable,
      ]),
      builder: (context, _) {
        final enabled = viewModel.enabled;
        // Only treat this as an unrecoverable error state when we have no
        // known status at all — if `enabled` is already set (a prior
        // successful load, or an optimistic confirmEnabled() call), trust
        // it rather than letting a background reconciliation failure hide
        // it behind an error screen.
        final showError = viewModel.error && enabled == null;

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
            else if (showError) ...[
              ErrorMessage(text: localization.mfaStatusLoadFailed),
              const SizedBox(height: Dimens.paddingVertical / 2),
              PrimaryButton(
                label: localization.retry,
                onPressed: () => viewModel.load.execute(),
              ),
            ] else ...[
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
    final localization = AppLocalization.of(context);

    return SectionScaffold(
      title: localization.account,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: localization.changePassword,
            onPressed: () => _onChangePasswordPressed(context),
          ),
          const SizedBox(height: Dimens.paddingVertical),
          _mfaSection(context),
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
