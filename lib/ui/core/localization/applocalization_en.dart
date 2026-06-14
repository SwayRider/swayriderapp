import 'applocalization.dart';

class AppLocalizationEn  extends AppLocalization {
  static const _en = <String, String>{
    'close': 'Close',
    'confirm': 'Confirm',

    'email': 'Email',
    'password': 'Password',
    'confirmPassword': 'Confirm Password',
    'show': 'Show',
    'hide': 'Hide',

    'login': 'Login',
    'signup': 'Signup',

    'invalidLogin': 'Invalid Login',
    'forgotPassword': 'Forgot Password?',
    'resetPassword': 'Reset Password',
    'noAccount': 'No Account?',

    'passwordNotStrongEnough': 'Password is not strong enough',
    'passwordsDoNotMatch': 'Passwords do not match',
    'signupFailed': 'Signup failed',
    'haveAccount': 'Have an Account?',

    'dashboard': 'Dashboard',
    'profile': 'Profile',
    'logout': 'Logout',
    'comingSoon': 'Coming soon',

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
  };

  @override
  Map<String, String> get strings => _en;
}