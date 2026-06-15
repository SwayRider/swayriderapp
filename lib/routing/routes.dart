abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';
  static const emailVerified = '/email-verified';
  static const invitationOnly = '/invitation-only';
  static const resetPassword = '/reset-password';
  static const resetPasswordConfirmation = '/reset-password-confirmation';
  static const newPassword = '/new-password';
  static const passwordChanged = '/password-changed';

  /// Routes accessible while the user is not authenticated.
  static const publicRoutes = {
    login,
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