import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/gradient_button.dart';
import '../providers/app_provider.dart';
import '../providers/transaction_provider.dart';
import '../l10n/app_localizations.dart';

enum TransferStatus { success, pending, failed, cancelled }

class SendMoneyResultScreen extends ConsumerStatefulWidget {
  final TransferStatus status;
  final Map<String, dynamic>? transactionDetails;

  const SendMoneyResultScreen({
    super.key,
    this.status = TransferStatus.success,
    this.transactionDetails,
  });

  @override
  ConsumerState<SendMoneyResultScreen> createState() =>
      _SendMoneyResultScreenState();
}

class _SendMoneyResultScreenState extends ConsumerState<SendMoneyResultScreen> {
  @override
  void initState() {
    super.initState();
    _checkTransactionStatus();
  }

  Future<void> _checkTransactionStatus() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    final pspTransactionId = args['pspTransactionId'] as String?;
    if (pspTransactionId != null) {
      await ref
          .read(transactionStatusProvider.notifier)
          .checkStatus(pspTransactionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);
    final transactionStatusState = ref.watch(transactionStatusProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      _buildStatusIcon(theme, appState, transactionStatusState),
                      const SizedBox(height: 24),
                      _buildStatusTitle(
                          theme, appState, transactionStatusState),
                      const SizedBox(height: 16),
                      _buildStatusMessage(
                          theme, appState, transactionStatusState),
                      const SizedBox(height: 32),
                      _buildTransactionDetails(
                          theme, appState, transactionStatusState),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(
                  theme, appState, context, transactionStatusState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme, AppState appState,
      TransactionStatusState transactionStatusState) {
    IconData icon;
    Color color;

    // Use API status if available, otherwise fall back to widget status
    final currentStatus = transactionStatusState.status?.status ??
        widget.status.toString().split('.').last;

    switch (currentStatus.toLowerCase()) {
      case 'success':
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'pending':
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case 'failed':
        icon = Icons.error;
        color = Colors.red;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      default:
        icon = Icons.help;
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

  Widget _buildStatusTitle(ThemeData theme, AppState appState,
      TransactionStatusState transactionStatusState) {
    String title;

    final currentStatus = transactionStatusState.status?.status ?? 'PENDING';

    switch (currentStatus.toLowerCase()) {
      case 'success':
      case 'completed':
        title = 'Transfer completed';
        break;
      case 'pending':
        title = 'Payment processing';
        break;
      case 'failed':
        title = 'Transfer failed';
        break;
      case 'cancelled':
        title = 'Transfer cancelled';
        break;
      default:
        title = 'Transfer status unknown';
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

  Widget _buildStatusMessage(ThemeData theme, AppState appState,
      TransactionStatusState transactionStatusState) {
    String message;

    final status = transactionStatusState.status?.status;
    switch (status) {
      case 'COMPLETED':
        message =
            'Your transfer has been scheduled and will be processed shortly.';
        break;
      case 'PENDING':
        message = 'We\'ll notify you once payment is confirmed.';
        break;
      case 'FAILED':
        message =
            'Your transfer could not be completed. Please try again or contact support.';
        break;
      case 'CANCELLED':
        message = 'Your transfer has been cancelled. No charges were made.';
        break;
      default:
        message = 'Processing your transfer...';
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

  Widget _buildTransactionDetails(ThemeData theme, AppState appState,
      TransactionStatusState transactionStatusState) {
    // Extract PesaPal data
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final pesapalOrderTrackingId = args?['pesapalOrderTrackingId'] as String?;
    final paymentMethod = args?['paymentMethod'] as String? ?? 'mobile_money';

    if (transactionStatusState.status == null &&
        pesapalOrderTrackingId == null) {
      return const SizedBox.shrink();
    }

    final details = transactionStatusState.status;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
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
          if (details != null) ...[
            _buildDetailRow(
                'Amount',
                _formatAmount(details.amount, details.currency ?? 'USD'),
                theme,
                appState),
            _buildDetailRow('Fees',
                _formatAmount(0.0, details.currency ?? 'USD'), theme, appState),
            _buildDetailRow(
                'Total charged',
                _formatAmount(details.amount, details.currency ?? 'USD'),
                theme,
                appState),
            _buildDetailRow('Recipient', 'N/A', theme, appState),
            _buildDetailRow(
                'YOLE Ref', details.orderTrackingId, theme, appState),
            _buildDetailRow(
                'PSP Txn ID', details.orderTrackingId, theme, appState),
          ] else ...[
            // Show basic info from args when details are not available
            _buildDetailRow(
                'Payment Method', paymentMethod.toUpperCase(), theme, appState),
            if (pesapalOrderTrackingId != null)
              _buildDetailRow(
                  'PesaPal Order ID', pesapalOrderTrackingId, theme, appState),
          ],
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

  Widget _buildActionButtons(ThemeData theme, AppState appState,
      BuildContext context, TransactionStatusState transactionStatusState) {
    // Extract PesaPal data for completion button
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final pesapalRedirectUrl = args?['pesapalRedirectUrl'] as String?;
    final paymentMethod = args?['paymentMethod'] as String? ?? 'mobile_money';

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // PesaPal completion button (if applicable)
          if (paymentMethod == 'pesapal' && pesapalRedirectUrl != null) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final url = Uri.parse(pesapalRedirectUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    } else {
                      final l10n = AppLocalizations.of(context)!;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.couldNotOpenPaymentPage),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    final l10n = AppLocalizations.of(context)!;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorOpeningPayment(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Complete Payment in Browser',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Primary action button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: GradientButton(
              onPressed: () {
                // Navigate to home screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
              child: Text(_getPrimaryButtonText(transactionStatusState)),
            ),
          ),

          // Secondary action buttons for failed transfers
          if (transactionStatusState.status?.status == 'FAILED' ||
              transactionStatusState.status?.status == 'CANCELLED') ...[
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

  String _getPrimaryButtonText(TransactionStatusState transactionStatusState) {
    final status = transactionStatusState.status?.status;
    switch (status) {
      case 'COMPLETED':
      case 'PENDING':
        return 'Done';
      case 'FAILED':
      case 'CANCELLED':
        return 'Back to Home';
      default:
        return 'Done';
    }
  }

  String _formatAmount(dynamic amount, String currency) {
    final formattedAmount = amount?.toStringAsFixed(2) ?? '0.00';
    final symbol = currency == 'USD' ? '\$' : '€';
    return '$symbol$formattedAmount $currency';
  }
}
