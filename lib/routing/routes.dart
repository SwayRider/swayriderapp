abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const mfaVerify = '/mfa-verify';
  static const mfaSetup = '/mfa-setup';
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';
  static const emailVerified = '/email-verified';
  static const invitationOnly = '/invitation-only';
  static const resetPassword = '/reset-password';
  static const resetPasswordConfirmation = '/reset-password-confirmation';
  static const newPassword = '/new-password';
  static const passwordChanged = '/password-changed';
  static const profile = '/profile';
  static const changePassword = '/change-password';

  /// Routes accessible while the user is not authenticated.
  static const publicRoutes = {
    login,
    // The second-factor step completes a login before any tokens exist, so
    // it must stay reachable while unauthenticated.
    mfaVerify,
    signup,
    verifyEmail,
    emailVerified,
    invitationOnly,
    resetPassword,
    resetPasswordConfirmation,
    newPassword,
    passwordChanged,
  };
}
