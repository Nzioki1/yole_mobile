import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/core_api_service.dart';
import '../router_types.dart';
import '../l10n/app_localizations.dart';
import '../widgets/brand/poste_txn_tile.dart';

class TransactionsHistorySimple extends ConsumerStatefulWidget {
  const TransactionsHistorySimple({super.key});

  @override
  ConsumerState<TransactionsHistorySimple> createState() =>
      _TransactionsHistorySimpleState();
}

class _TransactionsHistorySimpleState
    extends ConsumerState<TransactionsHistorySimple> {
  final _api = CoreApiService();
  bool _loading = false;
  List<dynamic> _payments = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payments = await _api.listPayments();
      setState(() => _payments = payments);
    } catch (e) {
      setState(() => _error = e.toString());
      debugPrint('Error loading payments: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _getTimeFromPayment(Map<String, dynamic> payment) {
    final createdAt = payment['createdAt'] as String?;
    if (createdAt != null) {
      try {
        final dateTime = DateTime.parse(createdAt);
        return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }
    return '00:00';
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'POSTED':
        return 'Completed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      default:
        return status;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'W2W':
        return Icons.swap_horiz;
      case 'MNO_IN':
      case 'MNO_OUT':
        return Icons.phone_android;
      case 'BANK_IN':
      case 'BANK_OUT':
        return Icons.account_balance;
      case 'BILL_PAY':
        return Icons.receipt;
      case 'AIRTIME':
        return Icons.phone;
      default:
        return Icons.payment;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'W2W':
        return 'Wallet Transfer';
      case 'MNO_IN':
        return 'Mobile Money Deposit';
      case 'MNO_OUT':
        return 'Mobile Money Withdrawal';
      case 'BANK_IN':
        return 'Bank Deposit';
      case 'BANK_OUT':
        return 'Bank Withdrawal';
      case 'BILL_PAY':
        return 'Bill Payment';
      case 'AIRTIME':
        return 'Airtime Purchase';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading transactions',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadPayments,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    l10n.allTransactions,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            
            // Transactions list
            Expanded(
              child: _payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPayments,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index] as Map<String, dynamic>;
                          final paymentId = payment['id'] as String?;
                          final amountMinor = int.tryParse(payment['amountMinor']?.toString() ?? '0') ?? 0;
                          final amount = amountMinor / 100;
                          final currency = payment['currency'] as String? ?? 'USD';
                          final status = payment['status'] as String? ?? 'PENDING';
                          final type = payment['type'] as String? ?? 'UNKNOWN';
                          final currencySymbol = currency == 'CDF' ? 'FC' : '\$';
                          
                          return PosteTxnTile(
                            time: _getTimeFromPayment(payment),
                            title: _getTypeLabel(type),
                            amount: '-$currencySymbol${amount.toStringAsFixed(2)}',
                            subtitle: _getStatusLabel(status),
                            icon: _getIconForType(type),
                            onTap: paymentId != null
                                ? () => Navigator.of(context).pushNamed(
                                      RouteNames.transactionDetail,
                                      arguments: {'paymentId': paymentId},
                                    )
                                : null,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});
  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paymentId = payment['id'] as String?;
    final amountMinor = int.tryParse(payment['amountMinor']?.toString() ?? '0') ?? 0;
    final amount = amountMinor / 100;
    final currency = payment['currency'] as String? ?? 'USD';
    final status = payment['status'] as String? ?? 'PENDING';
    final type = payment['type'] as String? ?? 'UNKNOWN';
    
    final currencySymbol = currency == 'CDF' ? 'FC' : '\$';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return InkWell(
      onTap: paymentId != null
          ? () => Navigator.of(context).pushNamed(
                RouteNames.transactionDetail,
                arguments: {'paymentId': paymentId},
              )
          : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor,
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
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTypeLabel(type),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$currencySymbol${amount.toStringAsFixed(2)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'POSTED':
        return Colors.green;
      case 'PENDING':
      case 'CONFIRMED':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'POSTED':
        return 'Completed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      default:
        return status;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'W2W':
        return Icons.swap_horiz;
      case 'MNO_IN':
      case 'MNO_OUT':
        return Icons.phone_android;
      case 'BANK_IN':
      case 'BANK_OUT':
        return Icons.account_balance;
      case 'BILL_PAY':
        return Icons.receipt;
      case 'AIRTIME':
        return Icons.phone;
      default:
        return Icons.payment;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'W2W':
        return 'Wallet Transfer';
      case 'MNO_IN':
        return 'Mobile Money Deposit';
      case 'MNO_OUT':
        return 'Mobile Money Withdrawal';
      case 'BANK_IN':
        return 'Bank Deposit';
      case 'BANK_OUT':
        return 'Bank Withdrawal';
      case 'BILL_PAY':
        return 'Bill Payment';
      case 'AIRTIME':
        return 'Airtime Purchase';
      default:
        return type;
    }
  }
}
