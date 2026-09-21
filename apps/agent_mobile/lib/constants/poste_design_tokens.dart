import 'package:flutter/material.dart';

/// Poste Finance DRC design tokens
class PosteDesignTokens {
  PosteDesignTokens._();

  // === COLORS ===
  
  /// Primary brand teal
  static const Color primaryTeal = Color(0xFF00acac);
  
  /// Primary teal shades
  static const Color tealLight = Color(0xFF33BDBD);
  static const Color tealDark = Color(0xFF008A8A);
  static const Color tealPale = Color(0xFFE0F7F7);
  
  /// Accent colors
  static const Color accentOrange = Color(0xFFFF6B35);
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentRed = Color(0xFFFF3B30);
  static const Color accentYellow = Color(0xFFFFCC00);
  
  /// Neutrals
  static const Color neutral900 = Color(0xFF1A1A1A);
  static const Color neutral800 = Color(0xFF333333);
  static const Color neutral700 = Color(0xFF4D4D4D);
  static const Color neutral600 = Color(0xFF666666);
  static const Color neutral500 = Color(0xFF808080);
  static const Color neutral400 = Color(0xFF999999);
  static const Color neutral300 = Color(0xFFCCCCCC);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral50 = Color(0xFFFAFAFA);
  
  /// Background
  static const Color backgroundPrimary = Color(0xFFFAFAFA);
  static const Color backgroundSecondary = Colors.white;
  static const Color backgroundTertiary = Color(0xFFF5F5F5);
  
  /// Text
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral600;
  static const Color textTertiary = neutral400;
  static const Color textOnPrimary = Colors.white;
  
  /// Borders
  static const Color borderDefault = neutral200;
  static const Color borderFocus = primaryTeal;
  
  // === TYPOGRAPHY ===
  
  static const String fontFamily = 'Inter';
  
  /// Heading 1 (Page titles)
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );
  
  /// Heading 2 (Section titles)
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  /// Heading 3 (Card titles)
  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );
  
  /// Body (Default text)
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );
  
  /// Body bold
  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.5,
  );
  
  /// Caption (Secondary info)
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );
  
  /// Label (Small labels, tags)
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.3,
  );
  
  /// Amount large (Balance displays)
  static const TextStyle amountLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );
  
  /// Amount medium (Transaction amounts)
  static const TextStyle amountMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  // === SPACING ===
  
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  
  // === BORDER RADIUS ===
  
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  static const BorderRadius borderRadiusSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius borderRadiusMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius borderRadiusLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(Radius.circular(radiusXLarge));
  
  // === SHADOWS ===
  
  static const BoxShadow shadowSmall = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  
  static const BoxShadow shadowMedium = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
  
  static const BoxShadow shadowLarge = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );
  
  // === ELEVATION (Lists of shadows for cards) ===
  
  static const List<BoxShadow> elevation2 = [shadowSmall];
  static const List<BoxShadow> elevation4 = [shadowMedium];
  static const List<BoxShadow> elevation8 = [shadowLarge];
}
