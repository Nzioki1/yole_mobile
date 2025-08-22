import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

ThemeData buildAppTheme() {
  final text = buildTextTheme();
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      error: AppColors.error,
      brightness: Brightness.light,
    ),
    textTheme: text,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    useMaterial3: true,
  );
}