abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const mfaVerify = '/mfa-verify';
  static const mfaSetup = '/mfa-setup';
  static const mfaResetRequest = '/mfa-reset-request';
  static const mfaResetConfirmation = '/mfa-reset-confirmation';
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';
  static const emailVerified = '/email-verified';
  static const invitationOnly = '/invitation-only';
  static const resetPassword = '/reset-password';
  static const resetPasswordConfirmation = '/reset-password-confirmation';
  static const newPassword = '/new-password';
  static const passwordChanged = '/password-changed';
  static const profile = '/profile';
  static const account = '/account';
  static const changePassword = '/change-password';

  /// Routes accessible while the user is not authenticated.
  static const publicRoutes = {
    login,
    // The second-factor step completes a login before any tokens exist, so
    // it must stay reachable while unauthenticated.
    mfaVerify,
    // Reached from the unauthenticated "Lost access to your authenticator?"
    // link on mfaVerify -- there is no direct backup-code login, so losing
    // the authenticator always routes here rather than through mfaVerify
    // itself. See alwaysAccessibleRoutes below.
    mfaResetRequest,
    mfaResetConfirmation,
    signup,
    verifyEmail,
    emailVerified,
    invitationOnly,
    resetPassword,
    resetPasswordConfirmation,
    newPassword,
    passwordChanged,
  };

  /// Subset of [publicRoutes] that must stay reachable even if the user
  /// happens to already be authenticated, so the router's "authenticated +
  /// on a public route -> redirect home" rule can't bounce them away
  /// mid-flow -- defensive: nothing currently navigates here while
  /// authenticated, but nothing should assume that either.
  static const alwaysAccessibleRoutes = {mfaResetRequest, mfaResetConfirmation};
}
