import 'package:flutter/material.dart';

import '../themes/colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLength,
  });

  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      obscureText: obscureText,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        suffixIcon: suffixIcon,
        // Hide the character counter for fixed-length fields (e.g. TOTP codes).
        counterText: maxLength == null ? null : '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.black1),
        ),
      ),
    );
  }
}
