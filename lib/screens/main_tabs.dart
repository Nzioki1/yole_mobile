import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import 'transactions_history_screen.dart'; // This file has TransactionsHistorySimple
import 'favorites_screen.dart';
import 'profile_screen.dart';
import '../widgets/yole_bottom_nav.dart';

/// Host for bottom navigation using an IndexedStack (keeps tabs alive & instant).
class MainTabsScreen extends ConsumerStatefulWidget {
  const MainTabsScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  ConsumerState<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends ConsumerState<MainTabsScreen> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
      body: IndexedStack(
        index: _index,
        children: [
          _KeepAlive(child: HomeScreen()),
          _KeepAlive(child: TransactionsHistorySimple()),
          _KeepAlive(child: FavoritesScreen()),
          _KeepAlive(child: ProfileScreen()),
        ],
      ),
      bottomNavigationBar: YoleBottomNav(
        currentIndex: _index,
        onTap: (i) {
          if (i == _index) return;
          setState(() => _index = i);
        },
      ),
    );
  }
}

/// Keeps subtree alive when switching tabs.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});
  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
