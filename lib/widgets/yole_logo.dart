import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// YOLE Logo variants
enum YoleLogoVariant { light, dark }

/// Light mode YOLE logo with black text and blue circle
class YoleLogoLight extends StatelessWidget {
  final String className; // kept for API parity with the React version
  final double width;
  final double height;

  const YoleLogoLight({
    Key? key,
    this.className = "",
    this.width = 120,
    this.height = 48,
  }) : super(key: key);

  static const String _svgLight = '''
<svg 
  width="120" 
  height="48" 
  viewBox="0 0 120 48" 
  fill="none" 
  xmlns="http://www.w3.org/2000/svg"
>
  <!-- Y -->
  <path 
    d="M8 8L16 20L24 8H28L18 24V36H14V24L4 8H8Z" 
    fill="#1a1a1a"
  />
  
  <!-- O -->
  <circle 
    cx="40" 
    cy="22" 
    r="14" 
    fill="none" 
    stroke="#3B82F6" 
    stroke-width="4"
  />
  
  <!-- L -->
  <path 
    d="M60 8V32H76V36H56V8H60Z" 
    fill="#1a1a1a"
  />
  
  <!-- E -->
  <path 
    d="M84 8V36H80V8H84ZM80 8H96V12H80V8ZM80 20H92V24H80V20ZM80 32H96V36H80V32Z" 
    fill="#1a1a1a"
  />
</svg>
''';

  @override
  Widget build(BuildContext context) {
    // className has no direct Flutter equivalent; we keep it for parity.
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.string(
        _svgLight,
        width: width,
        height: height,
      ),
    );
  }
}

/// Dark mode YOLE logo with all white elements
class YoleLogoDark extends StatelessWidget {
  final String className; // kept for API parity with the React version
  final double width;
  final double height;

  const YoleLogoDark({
    Key? key,
    this.className = "",
    this.width = 120,
    this.height = 48,
  }) : super(key: key);

  static const String _svgDark = '''
<svg 
  width="120" 
  height="48" 
  viewBox="0 0 120 48" 
  fill="none" 
  xmlns="http://www.w3.org/2000/svg"
>
  <!-- Y -->
  <path 
    d="M8 8L16 20L24 8H28L18 24V36H14V24L4 8H8Z" 
    fill="white"
  />
  
  <!-- O -->
  <circle 
    cx="40" 
    cy="22" 
    r="14" 
    fill="none" 
    stroke="white" 
    stroke-width="4"
  />
  
  <!-- L -->
  <path 
    d="M60 8V32H76V36H56V8H60Z" 
    fill="white"
  />
  
  <!-- E -->
  <path 
    d="M84 8V36H80V8H84ZM80 8H96V12H80V8ZM80 20H92V24H80V20ZM80 32H96V36H80V32Z" 
    fill="white"
  />
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.string(
        _svgDark,
        width: width,
        height: height,
      ),
    );
  }
}

/// Main adaptive YOLE logo with full backward compatibility
class YoleLogo extends StatelessWidget {
  final YoleLogoVariant? variant; // Optional override for specific variant
  final bool? isDarkTheme; // Backward compatibility - maps to variant
  final String className; // kept for API parity
  final double? size; // preferred size
  final double? height; // legacy alias supported
  final double? width; // explicit width
  final Color? color; // Backward compatibility (note: SVG colors are fixed)
  final double letterSpacing; // Kept for compatibility (not used in SVG)
  final FontWeight fontWeight; // Kept for compatibility (not used in SVG)
  final bool enableAutoTheme; // Enable automatic theme detection

  const YoleLogo({
    Key? key,
    this.variant,
    this.isDarkTheme, // Backward compatibility
    this.className = "",
    this.size, // preferred size
    this.height, // <- legacy alias supported
    this.width, // explicit width
    this.color, // Backward compatibility (SVG colors are fixed)
    this.letterSpacing = 2.0, // Kept for compatibility
    this.fontWeight = FontWeight.w800, // Kept for compatibility
    this.enableAutoTheme = true, // Enable automatic theme detection
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? height ?? 48.0;
    final resolvedWidth =
        width ?? (resolvedSize * 2.5); // Maintain aspect ratio

    // Determine effective variant with backward compatibility
    final effectiveVariant = _getEffectiveVariant(context);

    // Note: color parameter is ignored for SVG implementation as colors are embedded
    if (color != null) {
      debugPrint('YoleLogo: color parameter ignored in SVG implementation');
    }

    if (effectiveVariant == YoleLogoVariant.dark) {
      return YoleLogoDark(
        className: className,
        width: resolvedWidth,
        height: resolvedSize,
      );
    }

    return YoleLogoLight(
      className: className,
      width: resolvedWidth,
      height: resolvedSize,
    );
  }

  /// Get effective variant with full backward compatibility
  YoleLogoVariant _getEffectiveVariant(BuildContext context) {
    // If explicit variant provided, use it
    if (variant != null) {
      return variant!;
    }

    // If isDarkTheme explicitly provided, use it (backward compatibility)
    if (isDarkTheme != null) {
      return isDarkTheme! ? YoleLogoVariant.dark : YoleLogoVariant.light;
    }

    // Auto-detect theme if enabled
    if (enableAutoTheme) {
      return _isDarkTheme(context)
          ? YoleLogoVariant.dark
          : YoleLogoVariant.light;
    }

    // Default to light theme
    return YoleLogoVariant.light;
  }

  /// Detect if current theme is dark
  bool _isDarkTheme(BuildContext context) {
    try {
      // Primary method: Use Theme.of(context).brightness
      final brightness = Theme.of(context).brightness;
      if (brightness == Brightness.dark) {
        return true;
      }

      // Fallback method: Use MediaQuery.platformBrightnessOf
      final platformBrightness = MediaQuery.platformBrightnessOf(context);
      return platformBrightness == Brightness.dark;
    } catch (e) {
      // Error fallback: Default to light theme
      return false;
    }
  }
}
