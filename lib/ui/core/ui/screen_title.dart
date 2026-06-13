import 'package:flutter/material.dart';

class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineLarge?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: color ?? theme.colorScheme.primary,
      ),
    );
  }
}
