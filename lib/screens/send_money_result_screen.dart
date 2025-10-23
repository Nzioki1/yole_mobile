import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';

enum TransferStatus { success, pending, failed, cancelled }

class SendMoneyResultScreen extends ConsumerWidget {
  final TransferStatus status;
  final Map<String, dynamic>? transactionDetails;

  const SendMoneyResultScreen({
    super.key,
    required this.status,
    this.transactionDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);

    return Scaffold(
      backgroundColor: appState.isDark ? null : Colors.white,
      body: Container(
        decoration: appState.isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0F19), Color(0xFF19173D)],
                ),
              )
            : null,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _buildStatusIcon(theme, appState),
                      const SizedBox(height: 24),
                      _buildStatusTitle(theme, appState),
                      const SizedBox(height: 16),
                      _buildStatusMessage(theme, appState),
                      const SizedBox(height: 32),
                      _buildTransactionDetails(theme, appState),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(theme, appState, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme, AppState appState) {
    IconData icon;
    Color color;

    switch (status) {
      case TransferStatus.success:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case TransferStatus.pending:
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case TransferStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case TransferStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 40,
        color: color,
      ),
    );
  }

  Widget _buildStatusTitle(ThemeData theme, AppState appState) {
    String title;

    switch (status) {
      case TransferStatus.success:
        title = 'Transfer scheduled';
        break;
      case TransferStatus.pending:
        title = 'Payment processing';
        break;
      case TransferStatus.failed:
        title = 'Transfer failed';
        break;
      case TransferStatus.cancelled:
        title = 'Transfer cancelled';
        break;
    }

    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: appState.isDark ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatusMessage(ThemeData theme, AppState appState) {
    String message;

    switch (status) {
      case TransferStatus.success:
        message =
            'Your transfer has been scheduled and will be processed shortly.';
        break;
      case TransferStatus.pending:
        message = 'We\'ll notify you once payment is confirmed.';
        break;
      case TransferStatus.failed:
        message =
            'Your transfer could not be completed. Please try again or contact support.';
        break;
      case TransferStatus.cancelled:
        message = 'Your transfer has been cancelled. No charges were made.';
        break;
    }

    return Text(
      message,
      style: TextStyle(
        color: appState.isDark ? Colors.white70 : Colors.grey[600],
        fontSize: 16,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTransactionDetails(ThemeData theme, AppState appState) {
    if (transactionDetails == null) {
      return const SizedBox.shrink();
    }

    final details = transactionDetails!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            appState.isDark ? Colors.white.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appState.isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: theme.textTheme.titleMedium?.copyWith(
              color: appState.isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
              'Amount',
              _formatAmount(details['amount'], details['currency']),
              theme,
              appState),
          _buildDetailRow(
              'Fees',
              _formatAmount(details['feeAmount'], details['currency']),
              theme,
              appState),
          _buildDetailRow(
              'Total charged',
              _formatAmount(details['totalAmount'], details['currency']),
              theme,
              appState),
          _buildDetailRow(
              'Recipient', details['recipient'] ?? 'N/A', theme, appState),
          _buildDetailRow(
              'YOLE Ref', details['yoleReference'] ?? 'N/A', theme, appState),
          _buildDetailRow('PSP Txn ID', details['pspTransactionId'] ?? 'N/A',
              theme, appState),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, ThemeData theme, AppState appState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: appState.isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: appState.isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      ThemeData theme, AppState appState, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Primary action button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to home screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _getPrimaryButtonText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // Secondary action buttons for failed transfers
          if (status == TransferStatus.failed ||
              status == TransferStatus.cancelled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate back to enter details
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/send-money-enter-details',
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: appState.isDark
                            ? Colors.white54
                            : Colors.grey[400]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try again',
                      style: TextStyle(
                        color: appState.isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate back to payment method selection
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/send-money-payment',
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: appState.isDark
                            ? Colors.white54
                            : Colors.grey[400]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Change method',
                      style: TextStyle(
                        color: appState.isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getPrimaryButtonText() {
    switch (status) {
      case TransferStatus.success:
      case TransferStatus.pending:
        return 'Done';
      case TransferStatus.failed:
      case TransferStatus.cancelled:
        return 'Back to Home';
    }
  }

  String _formatAmount(dynamic amount, String currency) {
    final formattedAmount = amount?.toStringAsFixed(2) ?? '0.00';
    final symbol = currency == 'USD' ? '\$' : '€';
    return '$symbol$formattedAmount $currency';
  }
}

