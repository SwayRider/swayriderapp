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
- [Map Tiles](#map-tiles)
- [Map Controls](#map-controls)
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

## Map Tiles

The map is `maplibre_gl`. Its native renderer fetches style, tiles, glyphs and
sprites itself and cannot attach an `Authorization` header, but the tiles API
(behind `swayrider-api`) needs the user's bearer token on every request.
`TilesRepositoryRemote` bridges that:

1. `getMapStyle` fetches `GET {prefix}/styles/<style id>/<variant>`
   (`AppConfig.tilesStyleId` and the light or dark variant) with the token.
2. It rewrites every string in the style that contains `/v1/tiles/` (tile
   template, glyphs, sprite) to point at a loopback HTTP server on `127.0.0.1`,
   and returns that JSON as `MapLibreMap.styleString`.
3. The loopback server forwards each request to the tiles API with the current
   token (`shelf_proxy`). It only serves what MapLibre fetches by itself:
   `GET`/`HEAD` of `/v1/tiles/{tileset}/{z}/{x}/{y}`, `/v1/tiles/fonts/…/{a}-{b}.pbf`
   and `/v1/tiles/sprites/{name}[@2x].{json,png}`. Everything else is `404`
   (`405` for other methods), so other apps on the device cannot use it to make
   authenticated requests.

Notes:
- The server stores tiles gzipped; `shelf_proxy` decodes them and drops
  `Content-Encoding`, so MapLibre and the optional `TileCache` see plain MVT.
- `204` (no tile at that zoom/area; MapLibre over-zooms) and `304` pass through
  and are never cached; only a `200` is written to the `TileCache`.
- `TileCache` is a no-op today. A real offline cache needs a build/release id in
  its key, because planet releases replace tiles under the same URL.
- Tiles are rate limited per user by the gateway (a map view is dozens of
  requests); a `429` shows as holes in the map until the next move.

---

## Map Controls

Two floating controls sit on the map in `HomeScreen`.

**Map style button (top-left): day / night / auto.** `MapStyleViewModel` owns
the user's choice (`MapStyleMode`, remembered with `shared_preferences` through
`MapStylePreferenceService`, default Auto), the variant on screen
(`MapVariant.light`/`dark`) and the style JSON for it. Both variants are
fetched through the same `TilesRepository` and cached (the JSON only holds
loopback URLs); the other variant is prefetched. A switch keeps the old style on
screen until the new JSON is in hand, then `MapLibreMap.styleString` changes and
the map reloads the style natively. A style load wipes every annotation, so
`HomeScreen._onStyleLoaded` drops its stale handles and re-adds the route
markers, route line and search marker (this also runs for the first load).

*Auto* follows ambient light through `AmbientLightService` (the `ambient_light`
package), decided by `AutoVariantResolver`:
- It looks at the **median** of the last 10 s of readings every 5 s, never at a
  single event; the Android sensor only reports on change, so the last reading
  stays valid.
- **Hysteresis:** dark below 10 lx, light again above 40 lx; the other side
  must hold for two evaluations in a row, and a switch is followed by at least
  60 s of calm. A style switch is a network fetch plus a native reload, so it is
  deliberately conservative.
- **Android** streams real lux from `Sensor.TYPE_LIGHT`. **iOS** has no light
  sensor API: the plugin reads the camera frame's EXIF brightness (APEX, a log
  scale). `AmbientLightServicePlugin` takes a short burst every 15 s (ignoring
  the first frames while the exposure settles, then the median of five), stops
  the camera between bursts, and converts with `lux ≈ 2^(Bv+5)`. **That
  conversion is provisional** and not calibrated against a light meter
  (`apexToLuxExponentOffset`).
- On iOS the camera needs consent: the sensor only starts after the user has
  picked Auto in the picker (`NSCameraUsageDescription`), never at first launch.
- The sensor runs only for Auto, while the app is in the foreground.
- Without usable readings (no sensor, error, no consent) Auto follows the system
  appearance (`didChangePlatformBrightness`).

**Compass button (top-right).** The needle is rotated by `-bearing` of the
map camera (`trackCameraPosition`), so it always points north, also when the user
rotates the map. `CompassState` holds the rules: from *free* or *following* a tap
points the map north (compass tracking is stopped first, because camera moves end
it on Android); from *north up* a tap starts MapLibre's `trackingCompass`, which
follows the device heading and the user's position. A manual rotation ends it.
Plain `tracking` (seen on iOS after a manual rotation) is normalised to `none`.

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
