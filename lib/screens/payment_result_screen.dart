import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Payment result screen (success or failure)
class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final success = args['success'] as bool;
    final payment = args['payment'] as Map<String, dynamic>?;
    final error = args['error'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Result'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              // Result icon
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: success
                      ? const Color(0xFF0C7A53).withOpacity(0.1)
                      : const Color(0xFF912D2D).withOpacity(0.1),
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  size: 60,
                  color: success ? const Color(0xFF0C7A53) : const Color(0xFF912D2D),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                success ? 'Payment Successful!' : 'Payment Failed',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (success && payment != null) ...[
                Text(
                  'Your payment has been processed successfully.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF2B2F58)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Payment ID',
                        value: payment['paymentId'] as String? ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Status',
                        value: payment['status'] as String? ?? 'N/A',
                      ),
                    ],
                  ),
                ),
              ] else if (!success && error != null) ...[
                Text(
                  error,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              // Copy receipt button
              OutlinedButton.icon(
                onPressed: () => _copyReceipt(context, args),
                icon: const Icon(Icons.copy, size: 20),
                label: const Text('Copy Receipt'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyReceipt(BuildContext context, Map<String, dynamic> args) {
    final success = args['success'] as bool? ?? false;
    final paymentId = args['paymentId'] as String? ?? 'N/A';
    final message = args['message'] as String? ?? '';
    final payment = args['payment'] as Map<String, dynamic>?;
    final timestamp = DateTime.now().toLocal().toString().split('.')[0];

    // Build receipt text
    final receiptLines = [
      '━━━━━━━━━━━━━━━━━━━━━━━━',
      '    YOLE PAYMENT RECEIPT',
      '━━━━━━━━━━━━━━━━━━━━━━━━',
      '',
      'Status: ${success ? '✓ SUCCESS' : '✗ FAILED'}',
      'Payment ID: $paymentId',
      'Timestamp: $timestamp',
      '',
    ];

    if (payment != null) {
      final amountMinor = payment['amountMinor'];
      final feeMinor = payment['feeMinor'];
      final taxMinor = payment['taxMinor'];
      final totalMinor = payment['totalMinor'];
      final currency = payment['currency'];
      
      if (amountMinor != null) {
        final amount = (int.tryParse(amountMinor.toString()) ?? 0) / 100;
        receiptLines.add('Amount: ${currency == 'USD' ? '\$' : 'FC '}${amount.toStringAsFixed(2)}');
      }
      if (feeMinor != null) {
        final fee = (int.tryParse(feeMinor.toString()) ?? 0) / 100;
        receiptLines.add('Fee: ${currency == 'USD' ? '\$' : 'FC '}${fee.toStringAsFixed(2)}');
      }
      if (taxMinor != null && int.tryParse(taxMinor.toString()) != 0) {
        final tax = (int.tryParse(taxMinor.toString()) ?? 0) / 100;
        receiptLines.add('Tax: ${currency == 'USD' ? '\$' : 'FC '}${tax.toStringAsFixed(2)}');
      }
      if (totalMinor != null) {
        final total = (int.tryParse(totalMinor.toString()) ?? 0) / 100;
        receiptLines.add('Total: ${currency == 'USD' ? '\$' : 'FC '}${total.toStringAsFixed(2)}');
      }
    } else if (message.isNotEmpty) {
      receiptLines.add(message);
    }

    receiptLines.addAll([
      '',
      '━━━━━━━━━━━━━━━━━━━━━━━━',
      'Thank you for using Yole!',
      '━━━━━━━━━━━━━━━━━━━━━━━━',
    ]);

    final receipt = receiptLines.join('\n');

    Clipboard.setData(ClipboardData(text: receipt));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
