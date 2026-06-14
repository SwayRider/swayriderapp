import 'package:flutter/material.dart';

abstract final class AppColors {
  static const black1 = Color(0xFF101010);
  static const white1 = Color(0xFFFFF7Fa);
  static const deepPetrolBlue = Color(0xFF0F4C5C);
  static const lightPetrolBlue = Color(0xFF2A7085);
  static const apexOrange = Color(0xFFFF7A00);
  static const black = Color(0xFF121417);
  static const darkGrey = Color(0xFF1E242B);
  static const white = Color(0xFFE6E8EA);
  static const almostWhite = Color(0xFFF5F7Fa);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF22C55E);
  static const grey1 = Color(0xFFF2F2F2);
  static const grey2 = Color(0xFF4D4D4D);
  static const grey3 = Color(0xFFA4A4A4);
  static const whiteTransparent = Color(0x4DFFFFFF);
  static const blackTransparent = Color(0x4D000000);

  static const lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: deepPetrolBlue,
    onPrimary: white,
    secondary: apexOrange,
    onSecondary: white,
    surface: Colors.white,
    surfaceContainer: almostWhite,
    onSurface: darkGrey,
    error: red,
    onError: white,
  );

  static const darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: lightPetrolBlue,
    onPrimary: white,
    secondary: apexOrange,
    onSecondary: white,
    surface: black,
    surfaceContainer: darkGrey,
    onSurface: white,
    error: red,
    onError: white,
  );
}