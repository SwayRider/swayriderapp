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

  String get email => _get('email');
  String get password => _get('password');
  String get confirmPassword => _get('confirmPassword');
  String get oldPassword => _get('oldPassword');
  String get newPassword => _get('newPassword');
  String get show => _get('show');
  String get hide => _get('hide');

  String get login => _get('login');
  String get signup => _get('signup');

  String get invalidLogin => _get('invalidLogin');
  String get forgotPassword => _get('forgotPassword');
  String get resetPassword => _get('resetPassword');
  String get noAccount => _get('noAccount');

  String get passwordNotStrongEnough => _get('passwordNotStrongEnough');
  String get passwordsDoNotMatch => _get('passwordsDoNotMatch');
  String get signupFailed => _get('signupFailed');
  String get haveAccount => _get('haveAccount');

  String get dashboard => _get('dashboard');
  String get profile => _get('profile');
  String get logout => _get('logout');
  String get comingSoon => _get('comingSoon');
  String get search => _get('search');
  String get standardMotorcycle => _get('standardMotorcycle');

  String get verified => _get('verified');
  String get emailVerifiedMessage => _get('emailVerifiedMessage');
  String get clickBelowToLogin => _get('clickBelowToLogin');

  String get invitationOnly => _get('invitationOnly');
  String get invitationOnlyMessage => _get('invitationOnlyMessage');
  String get visitHomepage => _get('visitHomepage');

  String get verifyEmail => _get('verifyEmail');
  String get yourEmailAddress => _get('yourEmailAddress');
  String verificationEmailSentTo(String email) =>
      _get('verificationEmailSentTo').replaceFirst('{email}', email);
  String get noEmailReceived => _get('noEmailReceived');
  String get resendEmail => _get('resendEmail');
  String get alreadyVerified => _get('alreadyVerified');
  String get resendVerificationFailed => _get('resendVerificationFailed');
  String resendEmailIn(int seconds) =>
      _get('resendEmailIn').replaceFirst('{seconds}', '$seconds');

  String get resetPasswordFailed => _get('resetPasswordFailed');
  String get rememberPassword => _get('rememberPassword');
  String passwordResetEmailSentTo(String email) =>
      _get('passwordResetEmailSentTo').replaceFirst('{email}', email);

  String get changePassword => _get('changePassword');
  String get changePasswordFailed => _get('changePasswordFailed');

  String get passwordChanged => _get('passwordChanged');
  String get passwordChangedMessage => _get('passwordChangedMessage');
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