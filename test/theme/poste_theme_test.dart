import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yole_mobile/theme/poste_theme.dart';
import 'package:yole_mobile/constants/poste_design_tokens.dart';

void main() {
  group('buildPosteTheme', () {
    test('returns ThemeData with correct primary color', () {
      final theme = buildPosteTheme();

      expect(theme.colorScheme.primary, PosteDesignTokens.primaryTeal);
    });

    test('returns ThemeData with correct scaffold background color', () {
      final theme = buildPosteTheme();

      expect(theme.scaffoldBackgroundColor, PosteDesignTokens.backgroundPrimary);
    });

    test('returns ThemeData with correct card theme border radius', () {
      final theme = buildPosteTheme();

      final cardShape = theme.cardTheme.shape as RoundedRectangleBorder?;
      expect(cardShape?.borderRadius, PosteDesignTokens.borderRadiusMedium);
    });

    test('returns ThemeData with correct elevated button background color', () {
      final theme = buildPosteTheme();

      final buttonStyle = theme.elevatedButtonTheme.style;
      final backgroundColor = buttonStyle?.backgroundColor?.resolve({});
      expect(backgroundColor, PosteDesignTokens.primaryTeal);
    });

    test('returns ThemeData with correct input decoration focused border color', () {
      final theme = buildPosteTheme();

      final focusedBorder = theme.inputDecorationTheme.focusedBorder as OutlineInputBorder?;
      expect(focusedBorder?.borderSide.color, PosteDesignTokens.borderFocus);
    });
  });
}
