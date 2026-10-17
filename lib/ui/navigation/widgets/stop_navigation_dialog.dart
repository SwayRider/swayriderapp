import 'package:flutter/material.dart';

import '../../core/localization/applocalization.dart';

/// Asks whether navigation should really stop. "Yes" is the highlighted
/// (filled) answer and has the focus; returns `true` only for "Yes".
Future<bool> confirmStopNavigation(BuildContext context) async {
  final l10n = AppLocalization.of(context);
  final answer = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.navigationStopTitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.navigationStopNo),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.navigationStopYes),
        ),
      ],
    ),
  );
  return answer ?? false;
}
