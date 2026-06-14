# Development Guide

This guide covers prerequisites, setup, running the app, backend
configuration, static analysis/testing, and contributing.

For an overview of the codebase's layering, navigation flow, and directory
structure, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Running the App](#running-the-app)
- [Backend / Configuration](#backend--configuration)
- [Static Analysis & Tests](#static-analysis--tests)
- [Contributing](#contributing)

---

## Prerequisites

- Flutter 3.44+ (stable channel), Dart SDK `^3.12.1`
- A configured iOS/Android toolchain (Xcode / Android SDK) or a connected device/emulator

---

## Setup

```bash
# Install dependencies
flutter pub get

# Generate freezed / json_serializable code (one-shot)
dart run build_runner build -d

# ...or run code generation in watch mode while developing
./build_runner.sh
```

---

## Running the App

```bash
flutter run
```

`lib/main.dart` delegates to `main_development.dart`, which wires up
`providerDev` from `lib/config/dependencies.dart` against the dev AuthService.

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

## Static Analysis & Tests

```bash
flutter analyze
flutter test
```

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
