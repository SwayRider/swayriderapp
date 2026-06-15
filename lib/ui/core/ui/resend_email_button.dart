import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/command.dart';
import '../localization/applocalization.dart';
import '../themes/dimens.dart';
import 'primary_button.dart';

/// A [PrimaryButton] for (re)sending a verification/reset email.
///
/// Once [command] finishes (successfully or not), the button is disabled
/// for [cooldown] and a countdown is shown below it, so the user can't
/// trigger repeated sends too quickly. If [startCooldownOnInit] is true,
/// the cooldown also starts as soon as this widget is built - useful when
/// an email was already sent on a previous screen.
class ResendEmailButton extends StatefulWidget {
  const ResendEmailButton({
    super.key,
    required this.label,
    required this.command,
    required this.onPressed,
    this.startCooldownOnInit = false,
    this.cooldown = const Duration(seconds: 30),
  });

  final String label;
  final Command<void> command;
  final VoidCallback onPressed;
  final bool startCooldownOnInit;
  final Duration cooldown;

  @override
  State<ResendEmailButton> createState() => _ResendEmailButtonState();
}

class _ResendEmailButtonState extends State<ResendEmailButton> {
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    widget.command.addListener(_onCommandStateChanged);
    if (widget.startCooldownOnInit) {
      _cooldownSeconds = widget.cooldown.inSeconds;
      _startCooldownTimer();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    widget.command.removeListener(_onCommandStateChanged);
    super.dispose();
  }

  void _onCommandStateChanged() {
    if (!widget.command.running && widget.command.result != null) {
      _cooldownTimer?.cancel();
      setState(() => _cooldownSeconds = widget.cooldown.inSeconds);
      _startCooldownTimer();
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalization.of(context);

    return ListenableBuilder(
      listenable: widget.command,
      builder: (context, _) {
        final onCooldown = _cooldownSeconds > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              label: widget.label,
              loading: widget.command.running,
              onPressed: onCooldown ? null : widget.onPressed,
            ),
            if (onCooldown) ...[
              const SizedBox(height: Dimens.paddingVertical / 2),
              Text(
                localization.resendEmailIn(_cooldownSeconds),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
