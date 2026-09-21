import 'package:flutter/material.dart';
import '../constants/poste_design_tokens.dart';

ThemeData buildPosteTheme() {
  return ThemeData(
    useMaterial3: true,
    
    colorScheme: ColorScheme.light(
      primary: PosteDesignTokens.primaryTeal,
      secondary: PosteDesignTokens.accentOrange,
      surface: PosteDesignTokens.backgroundSecondary,
      error: PosteDesignTokens.accentRed,
      onPrimary: PosteDesignTokens.textOnPrimary,
      onSurface: PosteDesignTokens.textPrimary,
    ),
    
    scaffoldBackgroundColor: PosteDesignTokens.backgroundPrimary,
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: PosteDesignTokens.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: PosteDesignTokens.heading2,
    ),
    
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: PosteDesignTokens.borderRadiusMedium,
        side: const BorderSide(color: PosteDesignTokens.borderDefault),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing8,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PosteDesignTokens.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: PosteDesignTokens.spacing24,
          vertical: PosteDesignTokens.spacing16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: PosteDesignTokens.borderRadiusSmall,
        ),
        textStyle: PosteDesignTokens.bodyBold,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PosteDesignTokens.primaryTeal,
        side: const BorderSide(color: PosteDesignTokens.primaryTeal),
        padding: const EdgeInsets.symmetric(
          horizontal: PosteDesignTokens.spacing24,
          vertical: PosteDesignTokens.spacing16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: PosteDesignTokens.borderRadiusSmall,
        ),
        textStyle: PosteDesignTokens.bodyBold,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PosteDesignTokens.primaryTeal,
        padding: const EdgeInsets.symmetric(
          horizontal: PosteDesignTokens.spacing16,
          vertical: PosteDesignTokens.spacing12,
        ),
        textStyle: PosteDesignTokens.bodyBold,
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PosteDesignTokens.backgroundTertiary,
      border: OutlineInputBorder(
        borderRadius: PosteDesignTokens.borderRadiusSmall,
        borderSide: const BorderSide(color: PosteDesignTokens.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: PosteDesignTokens.borderRadiusSmall,
        borderSide: const BorderSide(color: PosteDesignTokens.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: PosteDesignTokens.borderRadiusSmall,
        borderSide: const BorderSide(color: PosteDesignTokens.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: PosteDesignTokens.borderRadiusSmall,
        borderSide: const BorderSide(color: PosteDesignTokens.accentRed),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing12,
      ),
      labelStyle: PosteDesignTokens.body,
      hintStyle: PosteDesignTokens.caption.copyWith(color: PosteDesignTokens.textTertiary),
    ),
    
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing8,
      ),
    ),
    
    dividerTheme: const DividerThemeData(
      color: PosteDesignTokens.borderDefault,
      thickness: 1,
      space: 1,
    ),
    
    textTheme: const TextTheme(
      displayLarge: PosteDesignTokens.heading1,
      displayMedium: PosteDesignTokens.heading2,
      displaySmall: PosteDesignTokens.heading3,
      bodyLarge: PosteDesignTokens.body,
      bodyMedium: PosteDesignTokens.body,
      bodySmall: PosteDesignTokens.caption,
      labelLarge: PosteDesignTokens.bodyBold,
      labelMedium: PosteDesignTokens.label,
    ),
  );
}
