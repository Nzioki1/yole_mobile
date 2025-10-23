import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router_types.dart';
import '../providers/favorites_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/language_toggle.dart';
import '../providers/global_locale_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(currentLocaleProvider);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor, // THEME: Dynamic background
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.goodAfternoon,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme
                                .colorScheme.onSurface, // THEME: Dynamic text
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      LanguageToggle(
                        isDark: isDark,
                        fontSize: 14,
                        textColor: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showProfileOptions(context),
                        child: const Hero(
                          tag: 'profile-avatar',
                          child: _Avatar(initials: 'JD'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Transactions This Week',
                          value: '0',
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          title: 'Total Sent This Week',
                          value: r'$0',
                          icon: Icons.send_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Primary CTA
                  _PrimaryCTA(label: l10n.sendMoney),
                  const SizedBox(height: 24),

                  // Favorites preview
                  _FavoritesPreview(),
                  const SizedBox(height: 24),

                  // Recent transactions header
                  Row(
                    children: [
                      Text(
                        l10n.recentTransactions,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme
                              .colorScheme.onSurface, // THEME: Dynamic text
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context)
                            .pushNamed(RouteNames.transactions),
                        child: Text(
                          l10n.viewAll,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor, // THEME: Primary color
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sample items
                  _TxListItem(
                      name: 'Marie Kabila',
                      amount: '-\$100.00',
                      status: 'Delivered',
                      statusColor: const Color(0xFF0C7A53),
                      date: 'Jan 10'),
                  const SizedBox(height: 10),
                  _TxListItem(
                      name: 'Joseph Mumba',
                      amount: '-€50.00',
                      status: 'Processing',
                      statusColor: const Color(0xFF165BAA),
                      date: 'Jan 10'),
                  const SizedBox(height: 10),
                  _TxListItem(
                      name: 'Grace Tshisekedi',
                      amount: '-\$200.00',
                      status: 'Failed',
                      statusColor: const Color(0xFF912D2D),
                      date: 'Jan 9'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color, // THEME: Dynamic background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProfileQuickMenu(),
    );
  }
}

// Profile Quick Menu
class _ProfileQuickMenu extends StatelessWidget {
  const _ProfileQuickMenu();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface
                  .withOpacity(0.2), // THEME: Dynamic
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // User info
          Row(
            children: [
              const _Avatar(initials: 'JD'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Doe',
                      style: TextStyle(
                        color:
                            theme.colorScheme.onSurface, // THEME: Dynamic text
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'john.doe@email.com',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withOpacity(0.7), // THEME: Dynamic
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions
          _ProfileOption(
            icon: Icons.person_outline_rounded,
            title: 'View Full Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(RouteNames.profile);
            },
          ),
          _ProfileOption(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _ProfileOption(
            icon: Icons.security_outlined,
            title: 'Security',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _ProfileOption(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Log Out'),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color, // THEME: Dynamic background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: TextStyle(
              color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7)),
      title: Text(title, style: TextStyle(color: theme.colorScheme.onSurface)),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ——— Widgets used on Home ———

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      width: 36,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            LinearGradient(colors: [Color(0xFF4DA3FF), Color(0xFF7B4DFF)]),
      ),
      child: Text(
        initials,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color, // THEME: Dynamic card background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2B2F58)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              const Spacer(),
              Icon(Icons.north_east_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  size: 16),
            ],
          ),
          Text(
            value,
            style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 26,
                fontWeight: FontWeight.w800),
          ),
          Text(
            title,
            style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCTA extends StatelessWidget {
  const _PrimaryCTA({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF4DA3FF), Color(0xFF7B4DFF)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesPreview extends ConsumerWidget {
  const _FavoritesPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = ref.watch(favoritesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Favorites',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.favorites),
              child: Text(
                'Manage',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Text('No favorites yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6)))
        else
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final c = items[i];
                return _FavoritePill(
                  initials: c.initials,
                  label: c.label,
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.favorites),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FavoritePill extends StatelessWidget {
  const _FavoritePill(
      {required this.initials, required this.label, required this.onTap});
  final String initials;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 36,
                width: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Color(0xFF7B4DFF), Color(0xFF4DA3FF)]),
                ),
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxListItem extends StatelessWidget {
  const _TxListItem({
    required this.name,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.date,
  });

  final String name;
  final String amount;
  final String status;
  final Color statusColor;
  final String date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2B2F58)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          // avatar
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [Color(0xFF7B4DFF), Color(0xFF4DA3FF)]),
            ),
            child: Text(
              name
                  .split(' ')
                  .map((p) => p.isNotEmpty ? p[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          // name + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Text(date,
                        style: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                )
              ],
            ),
          ),
          // amount + badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(.6)),
                ),
                child: Text(status,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.w700)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
