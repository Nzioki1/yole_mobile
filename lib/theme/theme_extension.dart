import 'package:flutter/material.dart';

extension ThemeExtensions on ThemeData {
  _YoleCustomColors get yoleColors =>
      extension<_YoleCustomColors>() ?? const _YoleCustomColors(
        cardBackground: Colors.white,
        cardBorder: Color(0xFFE5E7EB),
        statCardBackground: Color(0xFFF1F5F9),
        textSecondary: Color(0xFF6B7280),
        textTertiary: Color(0xFF9CA3AF),
      );
}

class _YoleCustomColors extends ThemeExtension<_YoleCustomColors> {
  const _YoleCustomColors({
    required this.cardBackground,
    required this.cardBorder,
    required this.statCardBackground,
    required this.textSecondary,
    required this.textTertiary,
  });

  final Color cardBackground;
  final Color cardBorder;
  final Color statCardBackground;
  final Color textSecondary;
  final Color textTertiary;

  @override
  ThemeExtension<_YoleCustomColors> copyWith({
    Color? cardBackground,
    Color? cardBorder,
    Color? statCardBackground,
    Color? textSecondary,
    Color? textTertiary,
  }) {
    return _YoleCustomColors(
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      statCardBackground: statCardBackground ?? this.statCardBackground,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
    );
  }

  @override
  ThemeExtension<_YoleCustomColors> lerp(
    ThemeExtension<_YoleCustomColors>? other,
    double t,
  ) {
    if (other is! _YoleCustomColors) {
      return this;
    }
    return _YoleCustomColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      statCardBackground: Color.lerp(statCardBackground, other.statCardBackground, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
    );
  }
}