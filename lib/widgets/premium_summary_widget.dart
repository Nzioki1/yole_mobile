import 'package:flutter/material.dart';

/// Reusable widget to display insurance premium line items and total
class PremiumSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> premiumLineItems;
  final String currency;

  const PremiumSummaryWidget({
    super.key,
    required this.premiumLineItems,
    this.currency = 'CDF',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (premiumLineItems.isEmpty) return const SizedBox.shrink();

    final totalPremiumMinor = premiumLineItems.fold<int>(
      0,
      (sum, item) => sum + (item['premiumMinor'] as int),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Insurance premiums',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...premiumLineItems.map((item) {
          final productNameFr = item['productNameFr'] as String;
          final premiumMinor = item['premiumMinor'] as int;
          final premium = premiumMinor / 100;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    productNameFr,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '+ ${premium.toStringAsFixed(2)} $currency',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total premiums',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(totalPremiumMinor / 100).toStringAsFixed(2)} $currency',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
