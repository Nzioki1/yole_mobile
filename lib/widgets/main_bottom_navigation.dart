import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../router_types.dart';

class YoleBottomNav extends StatelessWidget {
  const YoleBottomNav({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        if (currentIndex != 0) {
          Navigator.of(context).pushReplacementNamed(RouteNames.home);
        }
        break;
      case 1:
        if (currentIndex != 1) {
          Navigator.of(context).pushReplacementNamed(RouteNames.transactions);
        }
        break;
      case 2:
        if (currentIndex != 2) {
          Navigator.of(context).pushReplacementNamed(RouteNames.favorites);
        }
        break;
      case 3:
        if (currentIndex != 3) {
          Navigator.of(context).pushReplacementNamed(RouteNames.profile);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
        selectedItemColor: theme.primaryColor, // Use theme primary color
        unselectedItemColor: isDark ? Colors.white60 : Colors.black45,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (i) => _go(context, i),
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: AppLocalizations.of(context)!.home),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: AppLocalizations.of(context)!.history),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              label: AppLocalizations.of(context)!.favorites),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: AppLocalizations.of(context)!.profile),
        ],
      ),
    );
  }
}
