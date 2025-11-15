import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: isDark ? Colors.white60 : Colors.black45,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: AppLocalizations.of(context)!.history,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded),
            label: AppLocalizations.of(context)!.favorites,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }
}
