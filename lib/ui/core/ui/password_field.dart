import 'package:flutter/material.dart';

import '../localization/applocalization.dart';
import 'app_text_field.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.hintText,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? hintText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      hintText: widget.hintText,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      suffixIcon: TextButton(
        onPressed: () => setState(() => _obscureText = !_obscureText),
        child: Text(
          _obscureText
              ? AppLocalization.of(context).show
              : AppLocalization.of(context).hide,
        ),
      ),
    );
  }
}
