import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Drop-in replacement for your previous YoleBottomNav that also supports [onTap].
/// Place this file at: lib/widgets/yole_bottom_nav.dart
class YoleBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const YoleBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
      selectedItemColor: theme.primaryColor, // Use theme primary color
      unselectedItemColor:
          isDark ? Colors.white70 : Colors.black54, // Dynamic unselected color
      items: [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppLocalizations.of(context)!.home),
        BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: AppLocalizations.of(context)!.history),
        BottomNavigationBarItem(
            icon: Icon(Icons.star_border_rounded),
            label: AppLocalizations.of(context)!.favorites),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: AppLocalizations.of(context)!.profile),
      ],
    );
  }
}
