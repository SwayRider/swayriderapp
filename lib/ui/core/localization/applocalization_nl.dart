import 'applocalization.dart';

class AppLocalizationNl extends AppLocalization {
  static const _nl = <String, String>{
    'close': 'Sluiten',
    'confirm': 'Bevestigen',

    'email': 'E-mail',
    'password': 'Wachtwoord',
    'confirmPassword': 'Bevestig wachtwoord',
    'oldPassword': 'Oud wachtwoord',
    'newPassword': 'Nieuw wachtwoord',
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
    'search': 'Zoeken',
    'standardMotorcycle': 'Standaard motorfiets',

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
    'resendVerificationFailed': 'Verzenden van verificatie-e-mail mislukt',
    'resendEmailIn': 'Je kan de e-mail opnieuw verzenden in {seconds}s',

    'resetPasswordFailed': 'Versturen van wachtwoord-reset e-mail mislukt',
    'rememberPassword': 'Wachtwoord toch nog gekend?',
    'passwordResetEmailSentTo':
        'Er is een wachtwoord-reset e-mail verzonden naar {email}',

    'changePassword': 'Wachtwoord wijzigen',
    'changePasswordFailed': 'Wachtwoord wijzigen mislukt',

    'passwordChanged': 'Wachtwoord gewijzigd',
    'passwordChangedMessage': 'Je wachtwoord is succesvol gewijzigd.',
  };

  @override
  Map<String, String> get strings => _nl;
}