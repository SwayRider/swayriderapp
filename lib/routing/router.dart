import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/email_verified/widgets/email_verified_screen.dart';
import '../ui/home/view_models/home_viewmodel.dart';
import '../ui/invitation_only/widgets/invitation_only_screen.dart';
import '../ui/home/widgets/home_screen.dart';
import '../ui/login/view_models/login_viewmodel.dart';
import '../ui/login/widgets/login_screen.dart';
import '../ui/signup/view_models/signup_viewmodel.dart';
import '../ui/signup/widgets/signup_screen.dart';
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
        return VerifyEmailScreen(email: email is String ? email : null);
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
      path: Routes.home,
      builder: (context, state) {
        final viewModel = HomeViewModel(authRepository: context.read());
        return HomeScreen(viewModel: viewModel);
      },
    )
  ]
);

// From https://github.com/flutter/packages/blob/main/packages/go_router/example/lib/redirection.dart
Future<String?> _redirect(BuildContext context, GoRouterState state) async {
  final authRepository = context.read<AuthRepository>();
  final loggedIn = await authRepository.isAuthenticated;
  final onPublicRoute = Routes.publicRoutes.contains(state.matchedLocation);

  // if the user is not logged in, they need to be on a public route
  // (login, signup, verify-email, email-verified, invitation-only)
  if (!loggedIn) {
    return onPublicRoute ? null : Routes.login;
  }

  // if the user is logged in but hasn't verified their email yet, send
  // them to the verify-email screen (unless they're already there)
  if (!await authRepository.isVerified) {
    return state.matchedLocation == Routes.verifyEmail
        ? null
        : Routes.verifyEmail;
  }

  // if the user is logged in but on a public route, send them to the
  // home page
  if (onPublicRoute) {
    return Routes.home;
  }

  // no need to redirect at all
  return null;
}