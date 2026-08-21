import 'applocalization.dart';

class AppLocalizationEn extends AppLocalization {
  static const _en = <String, String>{
    'close': 'Close',
    'confirm': 'Confirm',

    'email': 'Email',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'oldPassword': 'Old Password',
    'newPassword': 'New Password',
    'show': 'Show',
    'hide': 'Hide',

    'login': 'Login',
    'signup': 'Signup',

    'invalidLogin': 'Invalid Login',
    'forgotPassword': 'Forgot Password?',
    'resetPassword': 'Reset Password',
    'noAccount': 'No Account?',

    'passwordNotStrongEnough': 'Password is not strong enough',
    'passwordBreached':
        'This password has appeared in a known data breach. '
        'Please choose a different one.',
    'passwordReused':
        'This password has been used before. Please choose a different one.',
    'passwordsDoNotMatch': 'Passwords do not match',
    'signupFailed': 'Signup failed',
    'haveAccount': 'Have an Account?',

    'dashboard': 'Dashboard',
    'profile': 'Profile',
    'logout': 'Logout',
    'comingSoon': 'Coming soon',
    'search': 'Search',
    'standardMotorcycle': 'Standard Motorcycle',

    'verified': 'Verified',
    'emailVerifiedMessage':
        'Your email address has been verified\n'
        'You can now login into the SwayRider app.',
    'clickBelowToLogin': 'Click below to go back to the login page',

    'invitationOnly': 'Invitation Only',
    'invitationOnlyMessage':
        'SwayRider is currently invitation-only.\n'
        'This email address does not have an invitation.',
    'visitHomepage': 'Visit Homepage',

    'verifyEmail': 'Verify Email',
    'yourEmailAddress': 'your email address',
    'verificationEmailSentTo': 'A verification email has been sent to {email}',
    'noEmailReceived': 'No email received?',
    'resendEmail': 'Resend Email',
    'alreadyVerified': 'Already verified?',
    'resendVerificationFailed': 'Failed to resend verification email',
    'resendEmailIn': 'You can resend the email in {seconds}s',

    'resetPasswordFailed': 'Failed to send password reset email',
    'rememberPassword': 'Remember your password?',
    'passwordResetEmailSentTo':
        'A password reset email has been sent to {email}',

    'changePassword': 'Change Password',
    'changePasswordFailed': 'Failed to change password',

    'passwordChanged': 'Password Changed',
    'passwordChangedMessage': 'Your password has been successfully changed.',

    'twoFactorAuthentication': 'Two-Factor Authentication',
    'mfaEnabled': 'Two-factor authentication: On',
    'mfaDisabled': 'Two-factor authentication: Off',
    'enableTwoFactor': 'Enable 2FA',
    'disableTwoFactor': 'Disable 2FA',

    'mfaSetupTitle': 'Set Up Two-Factor Authentication',
    'mfaSetupFailed': 'Failed to start setup',
    'mfaSetupIntro':
        'Two-factor authentication adds a second step to logging in: '
        'after your password, you enter a code from an authenticator app.\n\n'
        'A third-party authenticator app (Google Authenticator, Authy, '
        '1Password, …) is required. You will be shown a manual key to enter '
        'into the app — a QR code is also shown for enrolling on a second '
        'device.',
    'startSetup': 'Start Setup',
    'mfaSecretKey': 'Secret Key',
    'copyKey': 'Copy Key',
    'keyCopied': 'Key copied to clipboard',
    'mfaQrHint': 'Scan with a second device, or enter the key manually',
    'mfaAddedKey': "I've Added the Key",
    'mfaCodeLabel': 'Verification Code',
    'verify': 'Verify',
    'mfaInvalidCode': 'Invalid code. Please try again.',
    'mfaBackupCodesTitle': 'Backup Codes',
    'mfaBackupCodesIntro':
        'If you ever lose access to your authenticator app, use one of '
        'these one-time backup codes to log in.',
    'mfaBackupCodesShownOnce':
        'These codes are shown only once. Store them somewhere safe.',
    'mfaBackupCodesSaved': "I've Saved Them",

    'mfaVerifyTitle': "Verify It's You",
    'mfaUseBackupCode': 'Use a backup code',
    'mfaUseVerificationCode': 'Use a verification code',

    'mfaDisablePasswordPrompt':
        'Enter your password to disable two-factor authentication',
    'mfaDisableSuccess': 'Two-factor authentication disabled',
    'mfaDisableFailed': 'Failed to disable two-factor authentication',
    'mfaEnableSuccess': 'Two-factor authentication enabled',
  };

  @override
  Map<String, String> get strings => _en;
}
