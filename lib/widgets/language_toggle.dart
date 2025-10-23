import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/global_locale_provider.dart';
import '../l10n/app_localizations.dart';

/// A reusable language toggle widget that can be used across all screens
class LanguageToggle extends ConsumerWidget {
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final Color? textColor;

  const LanguageToggle({
    super.key,
    this.isDark = false,
    this.padding,
    this.fontSize = 16,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(currentLocaleProvider);
    final localeService = ref.watch(globalLocaleServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    return TextButton(
      onPressed: () {
        localeService.toggleLanguage();
      },
      style: TextButton.styleFrom(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        foregroundColor:
            textColor ?? (isDark ? Colors.white70 : const Color(0xFF64748B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLocale.languageCode == 'fr' ? '🇫🇷' : '🇺🇸',
            style: TextStyle(fontSize: fontSize),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              currentLocale.languageCode == 'fr' ? l10n.french : l10n.english,
              key: ValueKey(currentLocale.languageCode == 'fr'
                  ? l10n.french
                  : l10n.english),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
