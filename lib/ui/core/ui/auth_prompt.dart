import 'package:flutter/material.dart';

import '../themes/dimens.dart';

class AuthPrompt extends StatelessWidget {
  const AuthPrompt({
    super.key,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
    this.spacing = Dimens.paddingVertical,
  });

  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: spacing),
        FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
      ],
    );
  }
}
