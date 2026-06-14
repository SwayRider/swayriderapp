# SwayRider Mobile App

![Flutter](https://img.shields.io/badge/Flutter-3.44-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12-0175C2?style=flat-square&logo=dart&logoColor=white)
![Status](https://img.shields.io/badge/Status-In%20Development-orange?style=flat-square)
![License](https://img.shields.io/badge/License-AGPLv3-blue?style=flat-square)

SwayRider is a navigation platform for motorcycles and scooters, providing route
planning, location search, and map-based navigation optimized for urban
micro-mobility.

This repository contains the **Flutter mobile client**. It is the new home for the
SwayRider mobile app and will replace the Kotlin/Jetpack Compose prototype at
[SwayRider/mobile](https://github.com/SwayRider/mobile).

> **Note**
> This app is under active development. Only the authentication flow and a
> placeholder authenticated dashboard are implemented so far. Navigation, route
> planning, location search, and map display are not yet built — see
> [Status](#status).

---

## Table of Contents

- [What is SwayRider](#what-is-swayrider)
- [Status](#status)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Backend / Configuration](#backend--configuration)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)
- [Related Projects](#related-projects)

---

## What is SwayRider

SwayRider is a mobile app designed for motorcycle and scooter riders. The
end-to-end product offers:

- **User Authentication** — secure registration and login, with email
  verification and invitation-only access control
- **Route Planning** — calculate optimal routes based on rider preferences
- **Location Search** — find addresses and points of interest with autocomplete
- **Map Display** — interactive maps with custom styling

The app communicates with backend microservices (AuthService, RouterService,
SearchService, TilesService, RegionService — see
[Related Projects](#related-projects)) to provide these features.

---

## Status

### Implemented

| Feature | Description |
|---------|-------------|
| Login | Email/password login against AuthService; access & refresh tokens persisted via `shared_preferences` |
| Signup | Registration with live password-strength checking |
| Invitation-only access | Signup screen gracefully handles invitation-only backends |
| Email verification | "Check your inbox" prompt + "email verified" confirmation screen, driven by deep links |
| Home / Dashboard shell | Authenticated `BrandedAppBar` + toolbar with a profile menu (Logout wired to `AuthRepository.logout()`) |

### Not yet implemented

The following are designed in [`docs/storyboards/auth-flows.md`](docs/storyboards/auth-flows.md)
and mocked up in [`docs/screens/`](docs/screens/), but have no screen/route yet:

- Reset password & "password changed" confirmation
- Change password (from the profile screen)
- Profile screen & navigation drawer
- Route planning, location search, and map navigation

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

## Architecture

### Layers

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

### Navigation flow

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

---

## Backend / Configuration

The app talks to the SwayRider **AuthService**. Connection settings are
build-time configuration, supplied via `--dart-define` and defined in
[`lib/config/app_config.dart`](lib/config/app_config.dart):

| Variable | Default | Purpose |
|----------|---------|---------|
| `AUTH_API_SCHEME` | `https` | Scheme used to reach the AuthService |
| `AUTH_API_HOST` | `api.swayrider-dev.hevanto-it.com` | AuthService host |
| `AUTH_API_PORT` | `443` | AuthService port |
| `AUTH_API_PATH_PREFIX` | `/api/v1/auth` | Base path for auth endpoints |
| `VERIFICATION_REDIRECT_URL` | `https://api.swayrider-dev.hevanto-it.com/web/verify-user` | Redirect target after email verification |
| `HOMEPAGE_URL` | _(empty)_ | SwayRider homepage link shown on the invitation-only screen |

Example — pointing the app at a locally running AuthService:

```bash
flutter run \
  --dart-define=AUTH_API_SCHEME=http \
  --dart-define=AUTH_API_HOST=192.168.1.100 \
  --dart-define=AUTH_API_PORT=34001 \
  --dart-define=AUTH_API_PATH_PREFIX=/api/v1/auth
```

---

## Getting Started

### Prerequisites

- Flutter 3.44+ (stable channel), Dart SDK `^3.12.1`
- A configured iOS/Android toolchain (Xcode / Android SDK) or a connected device/emulator

### Setup

```bash
# Install dependencies
flutter pub get

# Generate freezed / json_serializable code (one-shot)
dart run build_runner build -d

# ...or run code generation in watch mode while developing
./build_runner.sh
```

### Running the app

```bash
flutter run
```

`lib/main.dart` delegates to `main_development.dart`, which wires up
`providerDev` from `lib/config/dependencies.dart` against the dev AuthService.

### Static analysis & tests

```bash
flutter analyze
flutter test
```

---

## Documentation

- [`docs/storyboards/auth-flows.md`](docs/storyboards/auth-flows.md) — intended
  login, signup, email verification, reset password, and change password flows
- [`docs/design/color-scheme.md`](docs/design/color-scheme.md) — SwayRider color
  palette, encoded in [`lib/ui/core/themes/colors.dart`](lib/ui/core/themes/colors.dart)
- [`docs/screens/`](docs/screens/) — screen mockups for implemented and planned
  screens
- [`CLAUDE.md`](CLAUDE.md) — architecture and conventions reference for AI-assisted development

---

## Contributing

This project is under active development. Contributions should align with the
designs in `docs/storyboards/` and `docs/screens/`, and reuse the shared widget
library under `lib/ui/core/ui/` rather than re-implementing layout/styling.

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Run code generation if you touched any `@freezed` model:
   `dart run build_runner build -d`
3. Verify with `flutter analyze` and `flutter test`
4. Submit a pull request

---

## License

Licensed under the [GNU Affero General Public License v3.0](LICENSE).

---

## Related Projects

The SwayRider platform consists of multiple services and repositories:

| Project | Description |
|---------|-------------|
| [SwayRider/mobile](https://github.com/SwayRider/mobile) | Kotlin/Jetpack Compose prototype this app replaces |
| [SwayRider/authservice](https://github.com/SwayRider/authservice) | Authentication & authorization backend |
| [SwayRider/swayrider-api](https://github.com/SwayRider/swayrider-api) | API gateway |
| [SwayRider/routerservice](https://github.com/SwayRider/routerservice) | Route calculations |
| [SwayRider/searchservice](https://github.com/SwayRider/searchservice) | Location search |
| [SwayRider/tilesservice](https://github.com/SwayRider/tilesservice) | Map vector tiles |
| [SwayRider/regionservice](https://github.com/SwayRider/regionservice) | Region/municipality data |
| [SwayRider/mailservice](https://github.com/SwayRider/mailservice) | Transactional email delivery |
| [SwayRider/swayrider](https://github.com/SwayRider/swayrider) | Platform overview & developer setup |
