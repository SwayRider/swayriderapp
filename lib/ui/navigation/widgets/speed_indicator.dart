import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';

/// Round badge with the current speed in km/h.
class SpeedIndicator extends StatelessWidget {
  const SpeedIndicator({super.key, required this.speedKmh});

  final int speedKmh;

  static const size = 72.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$speedKmh km/h',
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.black1,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$speedKmh',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            Text(
              'km/h',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
