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
package), decided by `AutoVariantResolver`. It has to follow a tunnel entrance
or exit within a couple of seconds, so it is event driven and fast:
- The level is smoothed as `log10(lux + 1)` with a **time constant of 1 s**,
  evaluated on every reading and on a 0.5 s timer (the Android sensor only
  reports on change, so the last reading simply holds). On a log scale a drop
  from daylight (10 000 lx) to dark crosses a threshold in well under a second.
- **Hysteresis:** dark below 150 lx, light again above 1 000 lx. Daylight is
  over 1 000 lx; lit tunnels, garages and living rooms are roughly 50-300 lx.
  The wide gap keeps a bright petrol station canopy or street lamp at night
  (a few hundred lx) from flipping the map to light.
- **Debounce:** the other side must hold for 0.5 s, so a hand over the sensor
  or a passing shadow does not flip the map. After a switch it stays put for
  **5 s**, because a switch reloads the map style.
- Measured in the resolver tests: about 1.4 s from daylight to dark at a very
  dark entrance (5 lx), about 2.6 s into a dimly lit tunnel (80 lx); back to
  light about 1.3-1.7 s into full daylight (10 000 lx), about 2 s into overcast
  (3 000 lx) and up to 3 s at 1 500 lx. Plus the native style reload (both
  styles are cached).
- All values are parameters of `AutoVariantResolver` and are starting points to
  tune on real devices.
- **Android** streams real lux from `Sensor.TYPE_LIGHT`. **iOS** has no light
  sensor API: the plugin reads the camera frame's EXIF brightness (APEX, a log
  scale). `AmbientLightServicePlugin` takes a short burst (about half a second,
  ignoring the first frames while the exposure settles, then the median of
  three) **every 3 s** and stops the camera in between, so iOS reacts within
  about 3-4 s. The conversion `lux ≈ 2^(Bv+5)` is **provisional** and not
  calibrated against a light meter (`apexToLuxExponentOffset`).
- On iOS the camera needs consent: the sensor only starts after the user has
  picked Auto in the picker (`NSCameraUsageDescription`), never at first launch.
- The sensor runs only for Auto, while the app is in the foreground.
- Without usable readings (no sensor, error, no consent) Auto follows the system
  appearance (`didChangePlatformBrightness`).
- Debug runs print the decisions (`MapStyleViewModel`: sensor started, first
  reading, each switch with the smoothed lux).

**Compass button (top-right).** The needle is rotated by `-bearing` of the
map camera (`trackCameraPosition`), so it always points north, also when the user
rotates the map. `CompassState` holds the rules: from *free* or *following* a tap
points the map north; from *north up* a tap starts following the heading; a
manual rotation or a drag ends it.

*Following the heading* is driven by the app, not by MapLibre's `trackingCompass`:
that mode cannot be smoothed and on many phones the map spins, even when the
phone lies still. Native tracking stays off; `FollowHeadingController` moves the
camera itself (`animateCamera` to the user's position and a bearing, keeping the
user's zoom and tilt, about 10 times a second at most):
- **Compass source:** `CompassService`, a small platform channel of the app
  itself (no package: the common one forces CocoaPods on this Swift Package
  Manager project). Android: the rotation vector sensor in
  `CompassStreamHandler.kt` (the top of the screen when held flat, the back of
  the phone when upright, whichever points more horizontally; screen rotation
  accounted for), with the sensor's own accuracy estimate. iOS: Core Location's
  heading in `AppDelegate.swift` (true north, real accuracy, the system's
  calibration prompt).
- **`HeadingFilter`** turns the raw heading into a calm bearing: averaging on the
  circle (359° and 1° give 0°), time smoothing (0.6 s, twice as slow when the
  accuracy is only medium), a 4° dead band so a phone lying still shows a still
  map, a turning speed limit of 120°/s, and readings that are 45° off or worse
  (an "unreliable" sensor) are ignored. When that lasts 3 s the app suggests
  moving the phone in a figure 8.
- **GPS course while moving:** above 3 m/s (about 11 km/h) the direction of
  travel drives the bearing instead of the magnetometer (which a bike frame and
  mounts disturb), until the speed falls below 1.5 m/s.
- **Taking over:** `FollowGestureDetector` watches the raw pointers on top of the
  map (it is a native view): dragging or turning with two fingers ends following,
  pinch-zooming does not, and no camera moves happen while fingers are on the
  map. As a safety net, a camera bearing that stays more than 25° from the
  commanded one for a second also ends it.
- Magnetic north is used on Android (the difference to true north is a few
  degrees in Belgium); iOS delivers true north; the GPS course is true north.

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
