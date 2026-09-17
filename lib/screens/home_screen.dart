import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/core_api_service.dart';

/// Neo-bank home hub with wallet cards and quick actions
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _api = CoreApiService();
  bool _loadingWallets = false;
  List<dynamic> _wallets = [];
  List<dynamic> _recentPayments = [];

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadWallets();
    _loadRecentPayments();
  }

  Future<void> _loadWallets() async {
    setState(() => _loadingWallets = true);
    try {
      final response = await _api.getMyWallets();
      final walletsList = response['wallets'] as List<dynamic>? ?? [];
      
      // Flatten pockets into per-currency display format
      final displayWallets = <Map<String, dynamic>>[];
      for (final wallet in walletsList) {
        final walletId = wallet['id'] as String?;
        final pockets = wallet['pockets'] as List<dynamic>? ?? [];
        
      for (final pocket in pockets) {
        displayWallets.add({
          'walletId': walletId,
          'pocketId': pocket['id'],
          'currency': pocket['currency'],
          'availableMinor': pocket['availableMinor'],
          'ledgerMinor': pocket['ledgerMinor'],
          'blockedMinor': pocket['blockedMinor'],
          'pendingOutMinor': pocket['pendingOutMinor'],
          'pendingInMinor': pocket['pendingInMinor'],
        });
      }
      }
      
      setState(() => _wallets = displayWallets);
    } catch (e) {
      debugPrint('Error loading wallets: $e');
    } finally {
      setState(() => _loadingWallets = false);
    }
  }

  Future<void> _loadRecentPayments() async {
    try {
      final payments = await _api.listPayments();
      setState(() => _recentPayments = payments.take(3).toList());
    } catch (e) {
      debugPrint('Error loading recent payments: $e');
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadWallets(),
      _loadRecentPayments(),
    ]);
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    final authState = ref.watch(authProvider);
    final firstName = authState.user?.name ?? 'Guest';
    
    if (hour >= 5 && hour < 12) {
      return 'Good morning, $firstName 👋';
    } else if (hour >= 12 && hour < 18) {
      return 'Good afternoon, $firstName 👋';
    } else if (hour >= 18 && hour < 22) {
      return 'Good evening, $firstName 👋';
    } else {
      return 'Good night, $firstName 👋';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with greeting, bell, and profile
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _getTimeBasedGreeting(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notifications bell
                    IconButton(
                      onPressed: () => Navigator.of(context).pushNamed(RouteNames.notifications),
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: theme.colorScheme.onSurface,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showProfileOptions(context),
                      child: Hero(
                        tag: 'profile-avatar',
                        child: _Avatar(
                          initials: _getInitials(authState.user?.name, authState.user?.surname),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Wallet cards
                if (_loadingWallets)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_wallets.isEmpty)
                  _EmptyWalletCard()
                else
                  ..._wallets.map((wallet) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _WalletCard(wallet: wallet),
                      )),

                const SizedBox(height: 16),

                // Add money and Withdraw buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/fund'),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text('Add Money'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/withdraw'),
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        label: const Text('Withdraw'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Quick actions grid
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _QuickActionsGrid(),

                const SizedBox(height: 24),

                // Recent activity
                Row(
                  children: [
                    Text(
                      'Recent Activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (_recentPayments.isNotEmpty)
                      GestureDetector(
                        onTap: () => Navigator.of(context)
                            .pushNamed(RouteNames.transactions),
                        child: Text(
                          l10n.viewAll,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_recentPayments.isEmpty)
                  _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No recent transactions',
                  )
                else
                  ..._recentPayments.map((payment) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PaymentItem(payment: payment),
                      )),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? firstName, String? lastName) {
    final first = firstName?.isNotEmpty == true ? firstName![0] : '';
    final last = lastName?.isNotEmpty == true ? lastName![0] : '';
    if (first.isEmpty && last.isEmpty) return 'G';
    return (first + last).toUpperCase();
  }

  void _showProfileOptions(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProfileQuickMenu(),
    );
  }
}

// Wallet Card Widget
class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet});
  final Map<String, dynamic> wallet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = wallet['currency'] as String? ?? 'USD';
    final availableMinor = int.tryParse(wallet['availableMinor']?.toString() ?? '0') ?? 0;
    final blockedMinor = int.tryParse(wallet['blockedMinor']?.toString() ?? '0') ?? 0;
    final pendingOutMinor = int.tryParse(wallet['pendingOutMinor']?.toString() ?? '0') ?? 0;
    final pendingInMinor = int.tryParse(wallet['pendingInMinor']?.toString() ?? '0') ?? 0;
    
    final available = availableMinor / 100;
    final blocked = blockedMinor / 100;
    final pendingOut = pendingOutMinor / 100;
    final pendingIn = pendingInMinor / 100;
    final totalPending = pendingIn - pendingOut;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: currency == 'CDF'
            ? const LinearGradient(
                colors: [Color(0xFF4DA3FF), Color(0xFF7B4DFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF7B4DFF), Color(0xFF4DA3FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '$currency Wallet',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                currency == 'CDF' ? Icons.account_balance : Icons.attach_money,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            currency == 'CDF' ? 'FC ${available.toStringAsFixed(2)}' : '\$${available.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Available Balance',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          // Pending balance row
          if (totalPending != 0)
            Row(
              children: [
                Icon(
                  totalPending > 0 ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.white60,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'Pending: ${currency == 'CDF' ? 'FC' : '\$'}${totalPending.abs().toStringAsFixed(2)} ${totalPending > 0 ? 'in' : 'out'}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          // Blocked balance row
          if (blocked > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.white60,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Blocked: ${currency == 'CDF' ? 'FC' : '\$'}${blocked.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Empty Wallet Card
class _EmptyWalletCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2B2F58)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No wallet balance yet',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Quick Actions Grid
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: [
        _QuickActionButton(
          icon: Icons.send_rounded,
          label: 'Pay / Send',
          color: const Color(0xFF4DA3FF),
          onTap: () => Navigator.of(context).pushNamed('/payment/picker'),
        ),
        _QuickActionButton(
          icon: Icons.receipt_outlined,
          label: 'Bills',
          color: const Color(0xFF7B4DFF),
          onTap: () => Navigator.of(context).pushNamed('/payment/bill'),
        ),
        _QuickActionButton(
          icon: Icons.verified_user_outlined,
          label: 'KYC',
          color: const Color(0xFF0C7A53),
          onTap: () => Navigator.of(context).pushNamed(RouteNames.kyc),
        ),
        _QuickActionButton(
          icon: Icons.credit_card_rounded,
          label: 'Cards',
          color: const Color(0xFFE87C03),
          onTap: () => Navigator.of(context).pushNamed('/cards'),
        ),
        _QuickActionButton(
          icon: Icons.account_balance_outlined,
          label: 'Credit',
          color: const Color(0xFF165BAA),
          onTap: () => Navigator.of(context).pushNamed('/credit'),
        ),
        _QuickActionButton(
          icon: Icons.flight_takeoff_rounded,
          label: 'Remittance',
          color: const Color(0xFF7B1FA2),
          onTap: () => Navigator.of(context).pushNamed(RouteNames.remittance),
        ),
        _QuickActionButton(
          icon: Icons.currency_exchange_rounded,
          label: 'FX',
          color: const Color(0xFF912D2D),
          onTap: () => Navigator.of(context).pushNamed('/fx'),
        ),
      ],
    );
  }
}

// Quick Action Button
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF2B2F58)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Recent Payment Item
class _PaymentItem extends StatelessWidget {
  const _PaymentItem({required this.payment});
  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountMinor = payment['amountMinor'] as String? ?? '0';
    final amount = (int.tryParse(amountMinor) ?? 0) / 100;
    final currency = payment['currency'] as String? ?? 'USD';
    final status = payment['status'] as String? ?? 'PENDING';
    final type = payment['type'] as String? ?? 'UNKNOWN';
    final paymentId = payment['id'] as String?;

    final statusColor = status == 'POSTED'
        ? const Color(0xFF0C7A53)
        : status == 'FAILED'
            ? const Color(0xFF912D2D)
            : const Color(0xFF165BAA);

    return InkWell(
      onTap: paymentId != null
          ? () => Navigator.of(context).pushNamed(
                RouteNames.transactionDetail,
                arguments: {'paymentId': paymentId},
              )
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor.withOpacity(0.1),
            ),
            child: Icon(
              _getIconForType(type),
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLabelForType(type),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'W2W':
        return Icons.swap_horiz_rounded;
      case 'MNO_OUT':
        return Icons.phone_android_rounded;
      case 'BANK_OUT':
        return Icons.account_balance_rounded;
      case 'BILL':
        return Icons.receipt_outlined;
      default:
        return Icons.send_rounded;
    }
  }

  String _getLabelForType(String type) {
    switch (type) {
      case 'W2W':
        return 'Wallet Transfer';
      case 'MNO_OUT':
        return 'Mobile Money';
      case 'BANK_OUT':
        return 'Bank Transfer';
      case 'BILL':
        return 'Bill Payment';
      default:
        return 'Payment';
    }
  }
}

// Empty State Widget
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Avatar Widget
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
        gradient: LinearGradient(colors: [Color(0xFF4DA3FF), Color(0xFF7B4DFF)]),
      ),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Profile Quick Menu (reused from old home)
class _ProfileQuickMenu extends ConsumerWidget {
  const _ProfileQuickMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final userEmail = authState.user?.email ?? 'guest@yole.com';
    final userName = '${authState.user?.name ?? 'Guest'} ${authState.user?.surname ?? ''}';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _Avatar(
                initials: _getInitials(authState.user?.name, authState.user?.surname),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProfileOption(
            icon: Icons.person_outline_rounded,
            title: 'View Full Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(RouteNames.profile);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                _showLogoutConfirmation(context, ref);
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

  String _getInitials(String? firstName, String? lastName) {
    final first = firstName?.isNotEmpty == true ? firstName![0] : '';
    final last = lastName?.isNotEmpty == true ? lastName![0] : '';
    if (first.isEmpty && last.isEmpty) return 'G';
    return (first + last).toUpperCase();
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
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
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
