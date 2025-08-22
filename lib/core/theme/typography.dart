import 'package:flutter/material.dart';

TextTheme buildTextTheme() {
  return const TextTheme(
    displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
}