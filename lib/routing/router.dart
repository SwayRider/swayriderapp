import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../ui/change_password/view_models/change_password_viewmodel.dart';
import '../ui/change_password/widgets/change_password_screen.dart';
import '../ui/email_verified/widgets/email_verified_screen.dart';
import '../ui/invitation_only/widgets/invitation_only_screen.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/login/view_models/login_viewmodel.dart';
import '../ui/login/widgets/login_screen.dart';
import '../ui/new_password/view_models/new_password_viewmodel.dart';
import '../ui/new_password/widgets/new_password_screen.dart';
import '../ui/password_changed/widgets/password_changed_screen.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/reset_password/view_models/reset_password_viewmodel.dart';
import '../ui/reset_password/widgets/reset_password_screen.dart';
import '../ui/reset_password_confirmation/widgets/reset_password_confirmation_screen.dart';
import '../ui/signup/view_models/signup_viewmodel.dart';
import '../ui/signup/widgets/signup_screen.dart';
import '../ui/verify_email/view_models/verify_email_viewmodel.dart';
import '../ui/verify_email/widgets/verify_email_screen.dart';
import 'routes.dart';
import '../data/repositories/auth/auth_repository.dart';

/// Top go_router entry point.
///
/// Listens to changes in [AuthTokenRepository] to redirect the user
/// to /login when the user logs out.
GoRouter router(AuthRepository authRepository) => GoRouter(
  initialLocation: Routes.home,
  debugLogDiagnostics: true,
  redirect: _redirect,
  refreshListenable: authRepository,
  routes: [
    GoRoute(
      path: Routes.login,
      builder: (context, state) {
        return LoginScreen(
          viewModel: LoginViewModel(authRepository: context.read()),
        );
      },
    ),
    GoRoute(
      path: Routes.signup,
      builder: (context, state) {
        return SignupScreen(
          viewModel: SignupViewModel(authRepository: context.read()),
        );
      },
    ),
    GoRoute(
      path: Routes.verifyEmail,
      builder: (context, state) {
        final email = state.extra;
        final resolvedEmail = email is String ? email : null;
        return VerifyEmailScreen(
          email: resolvedEmail,
          viewModel: VerifyEmailViewModel(
            authRepository: context.read(),
            email: resolvedEmail,
          ),
        );
      },
    ),
    GoRoute(
      path: Routes.emailVerified,
      builder: (context, state) => const EmailVerifiedScreen(),
    ),
    GoRoute(
      path: Routes.invitationOnly,
      builder: (context, state) => const InvitationOnlyScreen(),
    ),
    GoRoute(
      path: Routes.resetPassword,
      builder: (context, state) {
        return ResetPasswordScreen(
          viewModel: ResetPasswordViewModel(authRepository: context.read()),
        );
      },
    ),
    GoRoute(
      path: Routes.resetPasswordConfirmation,
      builder: (context, state) {
        final email = state.extra;
        return ResetPasswordConfirmationScreen(
          email: email is String ? email : '',
          viewModel: ResetPasswordViewModel(authRepository: context.read()),
        );
      },
    ),
    GoRoute(
      path: Routes.newPassword,
      builder: (context, state) {
        return NewPasswordScreen(
          userId: state.uri.queryParameters['user_id'] ?? '',
          token: state.uri.queryParameters['token'] ?? '',
          viewModel: NewPasswordViewModel(authRepository: context.read()),
        );
      },
    ),
    GoRoute(
      path: Routes.passwordChanged,
      builder: (context, state) => const PasswordChangedScreen(),
    ),
    GoRoute(
      path: Routes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: Routes.changePassword,
      builder: (context, state) {
        return ChangePasswordScreen(
          viewModel: ChangePasswordViewModel(authRepository: context.read()),
        );
      },
    ),
    GoRoute(
      path: Routes.home,
      builder: (context, state) {
        return HomeScreen(viewModel: context.read());
      },
    )
  ]
);

final _redirectLog = Logger('GoRouterRedirect');

// From https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/redirection.dart
Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final authRepository = context.read<AuthRepository>();
  final loggedIn = await authRepository.isAuthenticated;
  final onPublicRoute = Routes.publicRoutes.contains(state.matchedLocation);
  _redirectLog.fine('[DIAG] _redirect: loggedIn=$loggedIn onPublicRoute=$onPublicRoute matchedLocation=${state.matchedLocation}');

  // if the user is not logged in, they need to be on a public route
  // (login, signup, verify-email, email-verified, invitation-only)
  if (!loggedIn) {
    _redirectLog.fine('[DIAG] _redirect: not logged in, returning ${onPublicRoute ? null : Routes.login}');
    return onPublicRoute ? null : Routes.login;
  }

  // if the user is logged in but hasn't verified their email yet, send
  // them to the verify-email screen (unless they're already there)
  final isVerified = await authRepository.isVerified;
  _redirectLog.fine('[DIAG] _redirect: isVerified=$isVerified');
  if (!isVerified) {
    // isVerified may have cleared the session (an expired access token and
    // a failed refresh); re-check isAuthenticated so a fully expired
    // session goes to /login instead of getting stuck on /verify-email.
    final stillAuthenticated = await authRepository.isAuthenticated;
    _redirectLog.fine('[DIAG] _redirect: not verified, re-checked isAuthenticated=$stillAuthenticated');
    if (!stillAuthenticated) {
      _redirectLog.fine('[DIAG] _redirect: returning ${onPublicRoute ? null : Routes.login}');
      return onPublicRoute ? null : Routes.login;
    }
    final target = state.matchedLocation == Routes.verifyEmail ? null : Routes.verifyEmail;
    _redirectLog.fine('[DIAG] _redirect: returning $target');
    return target;
  }

  // if the user is logged in but on a public route, send them to the
  // home page
  if (onPublicRoute) {
    _redirectLog.fine('[DIAG] _redirect: on public route while verified, returning ${Routes.home}');
    return Routes.home;
  }

  // no need to redirect at all
  _redirectLog.fine('[DIAG] _redirect: no redirect needed, returning null');
  return null;
}