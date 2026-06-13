import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'applocalization_en.dart';
import 'applocalization_nl.dart';

class AppLocalization {
  static AppLocalization of(BuildContext context) {
    return Localizations.of(context, AppLocalization);
  }

  @protected
  Map<String, String> get strings => {};

  String _get(String label) =>
    strings[label] ?? '[${label.toUpperCase()}]';

  String get close => _get('close');
  String get confirm => _get('confirm');
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  static const _languages = <String, AppLocalization Function()>{
    'en': AppLocalizationEn.new,
    'nl': AppLocalizationNl.new,
  };

  @override
  bool isSupported(Locale locale) => _languages.containsKey(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) {
    final factory = _languages[locale.languageCode] ?? AppLocalization.new;
    return SynchronousFuture<AppLocalization>(factory());
  }

  @override
  bool shouldReload(covariant AppLocalizationDelegate old) => false;
}