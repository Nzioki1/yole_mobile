import 'package:flutter/material.dart';

class YoleColors {
  // Define your brand colors here
  static const Color primary = Color(0xFF0A84FF);
  static const Color secondary = Color(0xFF7BC5FF);
  static const Color backgroundLight = Colors.white;
  static const Color backgroundDark = Color(0xFF121212);
  static const Color textLight = Colors.black87;
  static const Color textDark = Colors.white70;
}

class YoleTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: YoleColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: YoleColors.backgroundLight,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: YoleColors.textLight),
      bodyMedium: TextStyle(color: YoleColors.textLight),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: YoleColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: YoleColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: YoleColors.backgroundDark,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: YoleColors.textDark),
      bodyMedium: TextStyle(color: YoleColors.textDark),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: YoleColors.secondary,
        foregroundColor: Colors.black,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
  );
}
