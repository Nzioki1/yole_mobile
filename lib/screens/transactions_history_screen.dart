import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/status_chip.dart';
import '../l10n/app_localizations.dart';

StatusChipVariant mapStatus(TransactionStatus s) {
  switch (s) {
    case TransactionStatus.success:
      return StatusChipVariant.success;
    case TransactionStatus.processing:
    case TransactionStatus.pending:
      return StatusChipVariant.info;
    case TransactionStatus.failed:
      return StatusChipVariant.error;
    case TransactionStatus.cancelled:
      return StatusChipVariant.warning;
    case TransactionStatus.delivered:
      return StatusChipVariant.success;
  }
}

String statusText(TransactionStatus s, AppLocalizations l10n) {
  switch (s) {
    case TransactionStatus.success:
      return l10n.completed;
    case TransactionStatus.processing:
      return l10n.processing;
    case TransactionStatus.pending:
      return l10n.pending;
    case TransactionStatus.failed:
      return l10n.failed;
    case TransactionStatus.cancelled:
      return l10n.cancelled;
    case TransactionStatus.delivered:
      return l10n.delivered;
  }
}

class TransactionsHistorySimple extends ConsumerWidget {
  const TransactionsHistorySimple({super.key});

  // Mock transactions data - replace with actual data source
  static final List<TransactionModel> _mockTransactions = [
    TransactionModel(
      id: 'tx_001',
      recipientName: 'Marie Koffi',
      counterpart: '+243123456789',
      amount: 100.0,
      currency: 'USD',
      status: TransactionStatus.delivered,
      date: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TransactionModel(
      id: 'tx_002',
      recipientName: 'Jean Mukendi',
      counterpart: '+243987654321',
      amount: 75.0,
      currency: 'EUR',
      status: TransactionStatus.processing,
      date: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    TransactionModel(
      id: 'tx_003',
      recipientName: 'Grace Mbuyi',
      counterpart: '+243456789123',
      amount: 200.0,
      currency: 'USD',
      status: TransactionStatus.delivered,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: 'tx_004',
      recipientName: 'Pierre Kasongo',
      counterpart: '+243789123456',
      amount: 50.0,
      currency: 'EUR',
      status: TransactionStatus.failed,
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildAvatar(String name) {
    final initials = name
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B4DFF), Color(0xFF4DA3FF)],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header - Fixed to use theme colors
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF2B2F58)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2B2F58)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: theme.colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  l10n.allTransactions,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Transaction List - Updated to use theme colors
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockTransactions.length,
              itemBuilder: (context, index) {
                final transaction = _mockTransactions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2B2F58)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: Navigate to transaction details
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _buildAvatar(transaction.recipientName ?? ''),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    transaction.recipientName ?? '',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDate(transaction.timestamp),
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '-\$${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(transaction.status)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _getStatusColor(transaction.status)
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                  child: Text(
                                    statusText(transaction.status, l10n),
                                    style: TextStyle(
                                      color:
                                          _getStatusColor(transaction.status),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.delivered:
      case TransactionStatus.success:
        return const Color(0xFF0C7A53);
      case TransactionStatus.processing:
      case TransactionStatus.pending:
        return const Color(0xFF165BAA);
      case TransactionStatus.failed:
        return const Color(0xFF912D2D);
      case TransactionStatus.cancelled:
        return const Color(0xFFB45309);
    }
  }
}
