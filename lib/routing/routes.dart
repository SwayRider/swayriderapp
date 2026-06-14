abstract final class Routes {
  static const home = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';
  static const emailVerified = '/email-verified';
  static const invitationOnly = '/invitation-only';

  /// Routes accessible while the user is not authenticated.
  static const publicRoutes = {
    login,
    signup,
    verifyEmail,
    emailVerified,
    invitationOnly,
  };
}