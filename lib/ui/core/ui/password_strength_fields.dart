import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/result.dart';
import '../localization/applocalization.dart';
import '../themes/colors.dart';
import '../themes/dimens.dart';
import 'password_field.dart';

/// A "Password" + "Confirm Password" field pair with a thin strength bar
/// below them.
///
/// The bar is transparent until the user starts typing a password. After a
/// short pause in typing, [checkPasswordStrength] is called; the bar turns
/// orange if the password isn't strong enough, or green if it is. [onStrengthChanged]
/// is invoked with the latest strength (`null` while unknown/untouched) so the
/// parent screen can gate form submission.
class PasswordStrengthFields extends StatefulWidget {
  const PasswordStrengthFields({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.checkPasswordStrength,
    this.onStrengthChanged,
    this.passwordHintText,
    this.confirmPasswordHintText,
    this.onConfirmPasswordSubmitted,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final Future<Result<bool>> Function(String password) checkPasswordStrength;
  final ValueChanged<bool?>? onStrengthChanged;
  final String? passwordHintText;
  final String? confirmPasswordHintText;
  final ValueChanged<String>? onConfirmPasswordSubmitted;

  @override
  State<PasswordStrengthFields> createState() =>
      _PasswordStrengthFieldsState();
}

class _PasswordStrengthFieldsState extends State<PasswordStrengthFields> {
  static const _debounceDuration = Duration(milliseconds: 500);

  Timer? _debounce;
  bool? _isStrong;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.passwordController.removeListener(_onPasswordChanged);
    super.dispose();
  }

  void _onPasswordChanged() {
    _debounce?.cancel();
    final password = widget.passwordController.text;
    if (password.isEmpty) {
      _updateStrength(null);
      return;
    }
    _debounce = Timer(_debounceDuration, () => _checkStrength(password));
  }

  Future<void> _checkStrength(String password) async {
    final result = await widget.checkPasswordStrength(password);
    if (!mounted) return;
    if (result case Ok(:final value)) {
      _updateStrength(value);
    }
  }

  void _updateStrength(bool? isStrong) {
    if (_isStrong == isStrong) return;
    setState(() => _isStrong = isStrong);
    widget.onStrengthChanged?.call(isStrong);
  }

  Color get _barColor => switch (_isStrong) {
    null => Colors.transparent,
    false => AppColors.apexOrange,
    true => AppColors.green,
  };

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PasswordField(
          controller: widget.passwordController,
          hintText: widget.passwordHintText ?? localization.password,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Dimens.paddingVertical),
        PasswordField(
          controller: widget.confirmPasswordController,
          hintText:
              widget.confirmPasswordHintText ?? localization.confirmPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: widget.onConfirmPasswordSubmitted,
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          key: const Key('password_strength_bar'),
          duration: const Duration(milliseconds: 200),
          height: 4,
          decoration: BoxDecoration(
            color: _barColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
