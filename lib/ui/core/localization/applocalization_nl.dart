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
    'passwordBreached':
        'Dit wachtwoord is aangetroffen in een bekend datalek. '
        'Kies een ander wachtwoord.',
    'passwordReused':
        'Dit wachtwoord is eerder gebruikt. Kies een ander wachtwoord.',
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
    'verificationEmailSentTo':
        'Er is een verificatie-e-mail verzonden naar {email}',
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

    'twoFactorAuthentication': 'Tweestapsverificatie',
    'mfaEnabled': 'Tweestapsverificatie: Aan',
    'mfaDisabled': 'Tweestapsverificatie: Uit',
    'enableTwoFactor': '2FA inschakelen',
    'disableTwoFactor': '2FA uitschakelen',

    'mfaSetupTitle': 'Tweestapsverificatie instellen',
    'mfaSetupFailed': 'Instellen mislukt',
    'mfaSetupIntro':
        'Tweestapsverificatie voegt een tweede stap toe aan het inloggen: '
        'na je wachtwoord voer je een code in uit een authenticator-app.\n\n'
        'Een authenticator-app van een derde partij (Google Authenticator, '
        'Authy, 1Password, …) is vereist. Je krijgt een handmatige sleutel '
        'te zien die je in de app moet invoeren — er wordt ook een QR-code '
        'getoond voor een tweede apparaat.',
    'startSetup': 'Instellen starten',
    'mfaSecretKey': 'Geheime sleutel',
    'copyKey': 'Sleutel kopiëren',
    'keyCopied': 'Sleutel gekopieerd naar klembord',
    'mfaQrHint': 'Scan met een tweede apparaat, of voer de sleutel handmatig in',
    'mfaAddedKey': 'Ik heb de sleutel toegevoegd',
    'mfaCodeLabel': 'Verificatiecode',
    'verify': 'Verifiëren',
    'mfaInvalidCode': 'Ongeldige code. Probeer het opnieuw.',
    'mfaBackupCodesTitle': 'Backupcodes',
    'mfaBackupCodesIntro':
        'Als je geen toegang meer hebt tot je authenticator-app, gebruik dan '
        'een van deze eenmalige backupcodes om in te loggen.',
    'mfaBackupCodesShownOnce':
        'Deze codes worden slechts één keer getoond. Bewaar ze op een '
        'veilige plek.',
    'mfaBackupCodesSaved': 'Ik heb ze bewaard',

    'mfaVerifyTitle': 'Verifieer dat jij het bent',
    'mfaUseBackupCode': 'Gebruik een backupcode',
    'mfaUseVerificationCode': 'Gebruik een verificatiecode',

    'mfaDisablePasswordPrompt':
        'Voer je wachtwoord in om tweestapsverificatie uit te schakelen',
    'mfaDisableSuccess': 'Tweestapsverificatie uitgeschakeld',
    'mfaDisableFailed': 'Tweestapsverificatie uitschakelen mislukt',
    'mfaEnableSuccess': 'Tweestapsverificatie ingeschakeld',
  };

  @override
  Map<String, String> get strings => _nl;
}
