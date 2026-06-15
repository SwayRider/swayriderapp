import 'package:flutter/material.dart';

import '../themes/colors.dart';

/// A rounded pill showing the currently selected vehicle type, with a
/// dropdown chevron — used as a map overlay control.
class VehicleTypePill extends StatelessWidget {
  const VehicleTypePill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.black1),
            ],
          ),
        ),
      ),
    );
  }
}
