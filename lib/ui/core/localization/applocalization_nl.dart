import 'applocalization.dart';

class AppLocalizationNl extends AppLocalization {
  static const _nl = <String, String>{
    'close': 'Sluiten',
    'confirm': 'Bevestigen',

    'email': 'E-mail',
    'password': 'Wachtwoord',
    'confirmPassword': 'Bevestig wachtwoord',
    'show': 'Tonen',
    'hide': 'Verbergen',

    'login': 'Inloggen',
    'signup': 'Registreren',

    'invalidLogin': 'Ongeldige inloggegevens',
    'forgotPassword': 'Wachtwoord vergeten?',
    'resetPassword': 'Wachtwoord resetten',
    'noAccount': 'Geen account?',

    'passwordNotStrongEnough': 'Wachtwoord is niet sterk genoeg',
    'passwordsDoNotMatch': 'Wachtwoorden komen niet overeen',
    'signupFailed': 'Registratie mislukt',
    'haveAccount': 'Heb je al een account?',

    'dashboard': 'Dashboard',
    'profile': 'Profiel',
    'logout': 'Uitloggen',
    'comingSoon': 'Binnenkort beschikbaar',

    'verified': 'Geverifieerd',
    'emailVerifiedMessage':
        'Je e-mailadres is geverifieerd.\n'
        'Je kan nu inloggen in de SwayRider-app.',
    'clickBelowToLogin': 'Klik hieronder om terug te gaan naar de inlogpagina',

    'invitationOnly': 'Enkel op uitnodiging',
    'invitationOnlyMessage':
        'SwayRider is momenteel enkel toegankelijk op uitnodiging.\n'
        'Dit e-mailadres heeft geen uitnodiging.',
    'visitHomepage': 'Bezoek website',

    'verifyEmail': 'E-mail verifiëren',
    'yourEmailAddress': 'jouw e-mailadres',
    'verificationEmailSentTo': 'Er is een verificatie-e-mail verzonden naar {email}',
    'noEmailReceived': 'Geen e-mail ontvangen?',
    'resendEmail': 'E-mail opnieuw verzenden',
    'alreadyVerified': 'Al geverifieerd?',
  };

  @override
  Map<String, String> get strings => _nl;
}