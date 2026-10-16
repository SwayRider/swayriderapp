/// What the user picked for the map's look.
enum MapStyleMode {
  /// Always the light style.
  day,

  /// Always the dark style.
  night,

  /// Light or dark depending on the surroundings (ambient light sensor, or the
  /// system appearance when no sensor reading is available).
  auto,
}

/// One of the two variants of a map style served by the tiles API.
enum MapVariant {
  light,
  dark;

  /// Path segment used in `{prefix}/styles/<style id>/<variant>`.
  String get path => name;
}
