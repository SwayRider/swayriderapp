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
- [Documentation](#documentation)
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

---

## Status

### Implemented

| Feature | Description |
|---------|-------------|
| Login | Email/password login, with secure session persistence |
| Signup | Registration with live password-strength checking |
| Invitation-only access | Signup screen gracefully handles invitation-only backends |
| Email verification | "Check your inbox" prompt + "email verified" confirmation screen |
| Home / Dashboard shell | Authenticated home screen with a profile menu and logout |

### Not yet implemented

- Reset password & "password changed" confirmation
- Change password (from the profile screen)
- Profile screen & navigation drawer
- Route planning, location search, and map navigation

---

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — technology stack, layered architecture,
  navigation flow, and project structure
- [DEVELOPMENT.md](DEVELOPMENT.md) — prerequisites, setup, running the app,
  backend configuration, testing, and contributing
- [`docs/storyboards/auth-flows.md`](docs/storyboards/auth-flows.md) — intended
  login, signup, email verification, reset password, and change password flows
- [`docs/design/color-scheme.md`](docs/design/color-scheme.md) — SwayRider color
  palette
- [`docs/screens/`](docs/screens/) — screen mockups for implemented and planned
  screens
- [`CLAUDE.md`](CLAUDE.md) — architecture and conventions reference for AI-assisted
  development

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
