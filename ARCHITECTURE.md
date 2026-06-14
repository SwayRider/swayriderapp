# Architecture

This document describes the architecture of the SwayRider Flutter mobile
client: the technology stack, the layering used throughout the codebase, the
navigation flow, and the project's directory structure.

For setup, running the app, configuration, and contributing, see
[DEVELOPMENT.md](DEVELOPMENT.md).

---

## Table of Contents

- [Technology Stack](#technology-stack)
- [Layers](#layers)
- [Navigation Flow](#navigation-flow)
- [Project Structure](#project-structure)

---

## Technology Stack

| Layer | Technology |
|-------|------------|
| Language | Dart `^3.12.1` |
| Framework | Flutter (stable channel) |
| Architecture | MVVM + Command/Result, based on the official Flutter ["Compass App"](https://docs.flutter.dev/app-architecture/case-study) sample |
| State management | `provider` |
| Routing | `go_router`, with `AuthRepository` as the router's `refreshListenable` |
| Networking | `dart:io` `HttpClient`-based `AuthApiClient` |
| Models / serialization | `freezed` + `json_serializable` |
| Local storage | `shared_preferences` (access/refresh tokens) |
| Fonts | `google_fonts` (Exo 2, used in the SwayRider logo) |
| Localization | Custom localization system (English, Dutch) |
| Icons / branding | `flutter_svg` |
| Linting | `flutter_lints` |
| Testing | `flutter_test`, `mocktail` |

---

## Layers

```
+------------------------------------------------------+
|                       UI Layer                        |
|  ui/<feature>/widgets/   - screens                    |
|  ui/core/ui/             - shared widget library      |
|  (BrandedScaffold, AppTextField, PrimaryButton, ...)  |
+------------------------------------------------------+
                          |
                          v
+------------------------------------------------------+
|                   ViewModel Layer                     |
|  ui/<feature>/view_models/                            |
|  Exposes Command0 / Command1 (utils/command.dart)     |
+------------------------------------------------------+
                          |
                          v
+------------------------------------------------------+
|                  Repository Layer                     |
|  data/repositories/<feature>/                         |
|  - AuthRepository       (abstract, ChangeNotifier)    |
|  - AuthRepositoryRemote  (implementation)             |
+------------------------------------------------------+
                          |
                          v
+------------------------------------------------------+
|                   Service Layer                       |
|  data/services/api/         - AuthApiClient (HTTP)    |
|  data/services/shared_preferences_service.dart        |
|  data/services/api/model/<feature>/ - freezed DTOs    |
+------------------------------------------------------+
```

`Result<T>` (`utils/result.dart`) is the return type for nearly all
repository/service calls, and `Command0`/`Command1` (`utils/command.dart`) wrap
those calls for the UI, exposing `running` / `error` / `completed` state.

---

## Navigation Flow

```
LoginScreen
  |
  +--> SignupScreen
  |       +--> InvitationOnlyScreen   (signup blocked, no invitation)
  |       +--> VerifyEmailScreen --> EmailVerifiedScreen
  |
  +--> HomeScreen (authenticated)
          +--> Profile menu --> Logout --> LoginScreen
```

`router.dart` redirects unauthenticated users to `/login`, and unverified users
to `/verify-email`, based on `AuthRepository.isAuthenticated` /
`isVerified`.

---

## Project Structure

```
swayriderapp/
├── lib/
│   ├── config/
│   │   ├── app_config.dart        # Build-time config (--dart-define)
│   │   └── dependencies.dart      # Provider wiring (providerDev)
│   ├── data/
│   │   ├── repositories/auth/     # AuthRepository + AuthRepositoryRemote
│   │   └── services/
│   │       ├── api/
│   │       │   ├── auth_api_client.dart       # AuthService HTTP client
│   │       │   ├── auth_header_provider.dart
│   │       │   └── model/auth/                # freezed + json_serializable DTOs
│   │       └── shared_preferences_service.dart
│   ├── domain/models/             # Freezed domain models (e.g. User)
│   ├── routing/                   # go_router setup (router.dart, routes.dart)
│   ├── ui/
│   │   ├── core/
│   │   │   ├── themes/             # AppColors, AppTheme, Dimens
│   │   │   ├── localization/       # Custom localization (en, nl)
│   │   │   └── ui/                 # Shared widget library
│   │   ├── login/                  # Login screen + view model
│   │   ├── signup/                 # Signup screen + view model
│   │   ├── verify_email/           # Email verification prompt
│   │   ├── email_verified/         # Verification result screen
│   │   ├── invitation_only/        # Invitation-only signup notice
│   │   └── home/                   # Authenticated dashboard shell
│   ├── utils/
│   │   ├── result.dart             # Sealed Result<T> (Ok / Error)
│   │   └── command.dart            # Command0 / Command1
│   ├── main.dart
│   └── main_development.dart       # Entry point, wires up providerDev
├── assets/branding/                 # SwayRider SVG branding assets
├── docs/
│   ├── design/color-scheme.md      # SwayRider color palette
│   ├── storyboards/auth-flows.md   # Intended auth flows
│   └── screens/                    # Screen mockups (PNG)
├── android/, ios/                   # Platform projects
└── test/
```
