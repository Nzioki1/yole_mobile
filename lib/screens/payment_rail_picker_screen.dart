import 'package:flutter/material.dart';

/// Payment rail picker for multi-rail payments
class PaymentRailPickerScreen extends StatelessWidget {
  const PaymentRailPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Payment Method'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'How would you like to pay?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            _RailOption(
              icon: Icons.swap_horiz_rounded,
              title: 'Wallet to Wallet',
              subtitle: 'Send to another Poste Finance wallet instantly',
              color: const Color(0xFF4DA3FF),
              onTap: () => Navigator.pushNamed(context, '/payment/w2w'),
            ),
            const SizedBox(height: 12),
            _RailOption(
              icon: Icons.phone_android_rounded,
              title: 'Mobile Money',
              subtitle: 'Send to a mobile money account',
              color: const Color(0xFF7B4DFF),
              onTap: () => Navigator.pushNamed(context, '/payment/mno'),
            ),
            const SizedBox(height: 12),
            _RailOption(
              icon: Icons.account_balance_rounded,
              title: 'Bank Transfer',
              subtitle: 'Send to a bank account',
              color: const Color(0xFF0C7A53),
              onTap: () => Navigator.pushNamed(context, '/payment/bank'),
            ),
            const SizedBox(height: 12),
            _RailOption(
              icon: Icons.receipt_outlined,
              title: 'Bills & Utilities',
              subtitle: 'Pay bills and utilities',
              color: const Color(0xFFE87C03),
              onTap: () => Navigator.pushNamed(context, '/payment/bill'),
            ),
            const SizedBox(height: 12),
            _RailOption(
              icon: Icons.phone_iphone_rounded,
              title: 'Airtime',
              subtitle: 'Buy airtime for any network',
              color: const Color(0xFF165BAA),
              onTap: () => Navigator.pushNamed(context, '/payment/airtime'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailOption extends StatelessWidget {
  const _RailOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
