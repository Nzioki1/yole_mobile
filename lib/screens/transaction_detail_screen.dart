import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/core_api_service.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Transaction/Payment detail screen
class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.paymentId,
  });

  final String paymentId;

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final _api = CoreApiService();
  bool _loading = false;
  Map<String, dynamic>? _payment;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payment = await _api.getPayment(widget.paymentId);
      setState(() => _payment = payment);
    } catch (e) {
      setState(() => _error = e.toString());
      debugPrint('Error loading payment: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _getPaymentTypeLabel(String type) {
    const labels = {
      'W2W': 'Wallet to Wallet',
      'MNO_IN': 'Mobile Money Deposit',
      'MNO_OUT': 'Mobile Money Withdrawal',
      'BANK_IN': 'Bank Deposit',
      'BANK_OUT': 'Bank Withdrawal',
      'BILL_PAY': 'Bill Payment',
      'AIRTIME': 'Airtime Purchase',
    };
    return labels[type] ?? type;
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toUpperCase()) {
      case 'POSTED':
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
      case 'CONFIRMED':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      case 'QUOTED':
        return Colors.blue;
      default:
        return theme.colorScheme.onSurface;
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
      case 'QUOTED':
        return 'Quoted';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          if (_payment != null)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.paymentId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment ID copied')),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(theme)
              : _payment == null
                  ? _buildEmptyState(theme)
                  : RefreshIndicator(
                      onRefresh: _loadPayment,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStatusHeader(theme),
                            const SizedBox(height: 24),
                            _buildAmountCard(theme),
                            const SizedBox(height: 24),
                            _buildDetailsCard(theme),
                            const SizedBox(height: 24),
                            _buildMetadataCard(theme),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              'Failed to load transaction',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPayment,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Text(
        'Transaction not found',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    final status = _payment!['status'] as String? ?? 'UNKNOWN';
    final statusColor = _getStatusColor(status, theme);
    final statusLabel = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              status.toUpperCase() == 'POSTED'
                  ? Icons.check_circle
                  : status.toUpperCase() == 'FAILED'
                      ? Icons.error
                      : Icons.hourglass_empty,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getPaymentTypeLabel(_payment!['type'] as String? ?? ''),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(ThemeData theme) {
    final amountMinor = int.tryParse(_payment!['amountMinor']?.toString() ?? '0') ?? 0;
    final feeMinor = int.tryParse(_payment!['feeMinor']?.toString() ?? '0') ?? 0;
    final taxMinor = int.tryParse(_payment!['taxMinor']?.toString() ?? '0') ?? 0;
    final totalMinor = int.tryParse(_payment!['totalMinor']?.toString() ?? '0') ?? 0;
    final currency = _payment!['currency'] as String? ?? 'USD';

    final amount = amountMinor / 100;
    final fee = feeMinor / 100;
    final tax = taxMinor / 100;
    final total = totalMinor / 100;

    final currencySymbol = currency == 'CDF' ? 'FC' : '\$';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Amount',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${amount.toStringAsFixed(2)}',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          _buildAmountRow('Fee', currencySymbol, fee, Colors.white70),
          if (tax > 0) ...[
            const SizedBox(height: 8),
            _buildAmountRow('Tax', currencySymbol, tax, Colors.white70),
          ],
          const SizedBox(height: 8),
          _buildAmountRow('Total', currencySymbol, total, Colors.white, bold: true),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String symbol, double value, Color color, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            fontSize: bold ? 16 : 14,
          ),
        ),
        Text(
          '$symbol${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(ThemeData theme) {
    final createdAt = _payment!['createdAt'] as String?;
    final updatedAt = _payment!['updatedAt'] as String?;

    DateTime? createdDateTime;
    DateTime? updatedDateTime;
    if (createdAt != null) {
      try {
        createdDateTime = DateTime.parse(createdAt);
      } catch (e) {
        debugPrint('Error parsing createdAt: $e');
      }
    }
    if (updatedAt != null) {
      try {
        updatedDateTime = DateTime.parse(updatedAt);
      } catch (e) {
        debugPrint('Error parsing updatedAt: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(theme, 'Payment ID', widget.paymentId),
          const SizedBox(height: 12),
          _buildDetailRow(theme, 'Type', _getPaymentTypeLabel(_payment!['type'] as String? ?? '')),
          if (_payment!['externalRef'] != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(theme, 'External Reference', _payment!['externalRef'] as String),
          ],
          if (_payment!['journalId'] != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(theme, 'Journal ID', _payment!['journalId'] as String),
          ],
          if (createdDateTime != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              theme,
              'Created',
              '${timeago.format(createdDateTime)} (${_formatDateTime(createdDateTime)})',
            ),
          ],
          if (updatedDateTime != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              theme,
              'Updated',
              '${timeago.format(updatedDateTime)} (${_formatDateTime(updatedDateTime)})',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataCard(ThemeData theme) {
    final metadata = _payment!['metadata'] as Map<String, dynamic>?;
    if (metadata == null || metadata.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...metadata.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDetailRow(theme, entry.key, entry.value.toString()),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
