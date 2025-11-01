import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/global_locale_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeState = ref.watch(themeProvider);
    final isDarkMode = themeState.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              pinned: true,
              expandedHeight: 160,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              title: Text(
                l10n.profile,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 24),

                // User Profile Card
                _UserProfileCard(isDarkMode: isDarkMode),
                const SizedBox(height: 32),

                // Preferences Section
                _SectionHeader(title: l10n.preferences, isDarkMode: isDarkMode),
                _ProfileTile(
                  icon: Icons.dark_mode_rounded,
                  title: l10n.darkMode,
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (value) =>
                        ref.read(themeProvider.notifier).setThemeMode(value),
                    activeColor: const Color(0xFF4DA3FF),
                  ),
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),
                _ProfileTile(
                  icon: Icons.language_rounded,
                  title: l10n.language,
                  subtitle: _getCurrentLanguageName(ref),
                  onTap: () => _showLanguageOptions(context, ref),
                  isDarkMode: isDarkMode,
                ),
                _ProfileTile(
                  icon: Icons.currency_exchange_rounded,
                  title: l10n.defaultCurrency,
                  subtitle: 'USD',
                  onTap: () => _showCurrencyOptions(context, ref),
                  isDarkMode: isDarkMode,
                ),
                _ProfileTile(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.notifications,
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),

                // Account Section
                _SectionHeader(title: l10n.account, isDarkMode: isDarkMode),
                _ProfileTile(
                  icon: Icons.person_outline_rounded,
                  title: l10n.personalInformation,
                  onTap: () => _showPersonalInfo(context),
                  isDarkMode: isDarkMode,
                ),
                _ProfileTile(
                  icon: Icons.phone_rounded,
                  title: l10n.phoneNumber,
                  onTap: () => _showPhoneNumber(context),
                  isDarkMode: isDarkMode,
                ),
                _ProfileTile(
                  icon: Icons.email_outlined,
                  title: l10n.emailAddress,
                  onTap: () => _showEmailAddress(context),
                  isDarkMode: isDarkMode,
                ),

                // Security Section
                _SectionHeader(title: l10n.security, isDarkMode: isDarkMode),
                _ProfileTile(
                  icon: Icons.lock_outline_rounded,
                  title: l10n.changePassword,
                  onTap: () => _showChangePassword(context),
                  isDarkMode: isDarkMode,
                ),
                _ProfileTile(
                  icon: Icons.fingerprint_rounded,
                  title: l10n.biometricLogin,
                  trailing: Switch(
                    value: true,
                    onChanged: (_) {},
                    activeColor: const Color(0xFF4DA3FF),
                  ),
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),
                _ProfileTile(
                  icon: Icons.security_outlined,
                  title: l10n.twoFactorAuthentication,
                  trailing: Switch(
                    value: false,
                    onChanged: (_) {},
                    activeColor: const Color(0xFF4DA3FF),
                  ),
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),

                // Support Section
                _SectionHeader(title: l10n.support, isDarkMode: isDarkMode),
                _ProfileTile(
                  icon: Icons.help_outline_rounded,
                  title: l10n.helpCenter,
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),
                _ProfileTile(
                  icon: Icons.description_outlined,
                  title: l10n.termsConditions,
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),
                _ProfileTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacyPolicy,
                  onTap: () {},
                  isDarkMode: isDarkMode,
                ),

                // Logout
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showLogoutConfirmation(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.logOut,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  /// Get current language display name based on locale
  String _getCurrentLanguageName(WidgetRef ref) {
    final currentLocale = ref.watch(currentLocaleProvider);
    if (currentLocale.languageCode == 'en') {
      return 'English';
    } else if (currentLocale.languageCode == 'fr') {
      return 'Français';
    }
    return 'English';
  }

  // Dialog methods for various options
  void _showLanguageOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(currentLocaleProvider);
    final localeService = ref.read(globalLocaleServiceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.selectLanguage,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
                title: 'English',
                isSelected: currentLocale.languageCode == 'en',
                onTap: () {
                  localeService.setLanguage('en');
                  Navigator.pop(context);
                }),
            _LanguageOption(
                title: l10n.french,
                isSelected: currentLocale.languageCode == 'fr',
                onTap: () {
                  localeService.setLanguage('fr');
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }

  void _showCurrencyOptions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.selectCurrency,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CurrencyOption(
                symbol: '\$',
                code: 'USD',
                name: l10n.usDollar,
                isSelected: true,
                onTap: () => Navigator.pop(context)),
            _CurrencyOption(
                symbol: '€',
                code: 'EUR',
                name: l10n.euro,
                isSelected: false,
                onTap: () => Navigator.pop(context)),
            _CurrencyOption(
                symbol: '£',
                code: 'GBP',
                name: l10n.britishPound,
                isSelected: false,
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showPersonalInfo(BuildContext context) {
    // TODO: Implement personal info screen
  }

  void _showPhoneNumber(BuildContext context) {
    // TODO: Implement phone number screen
  }

  void _showEmailAddress(BuildContext context) {
    // TODO: Implement email address screen
  }

  void _showChangePassword(BuildContext context) {
    // TODO: Implement change password screen
  }

  /// Perform logout and navigate to login screen - optimized for speed
  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    // Clear state immediately for fast response
    ref.read(authProvider.notifier).logout();

    // Navigate immediately without waiting for async operations
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false, // Remove all previous routes
      );
    }
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF11163A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.logOut,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.areYouSureLogOut,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  final bool isDarkMode;

  const _UserProfileCard({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF11163A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                isDarkMode ? const Color(0xFF2B2F58) : const Color(0xFFE5E7EB)),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF4DA3FF), Color(0xFF7B4DFF)],
              ),
            ),
            child: const Center(
              child: Text(
                'JD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'John Doe',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'john.doe@email.com',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+1 (555) 123-4567',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Edit profile
            },
            icon: Icon(Icons.edit_outlined, color: const Color(0xFF4DA3FF)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDarkMode;

  const _SectionHeader({required this.title, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white60 : Colors.black54,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isDarkMode;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF11163A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isDarkMode ? const Color(0xFF2B2F58) : const Color(0xFFE5E7EB)),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: ListTile(
        leading:
            Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black54),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                ),
              )
            : null,
        trailing: trailing ??
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: isDarkMode ? Colors.white30 : Colors.black26),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing:
          isSelected ? const Icon(Icons.check, color: Color(0xFF4DA3FF)) : null,
      onTap: onTap,
    );
  }
}

class _CurrencyOption extends StatelessWidget {
  final String symbol;
  final String code;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyOption({
    required this.symbol,
    required this.code,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('$symbol $code'),
      subtitle: Text(name),
      trailing:
          isSelected ? const Icon(Icons.check, color: Color(0xFF4DA3FF)) : null,
      onTap: onTap,
    );
  }
}
