import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'transfer_providers.dart';
import 'webview_screen.dart';

class ConfirmationScreen extends ConsumerStatefulWidget {
  final String orderTrackingId;
  final String redirectUrl;

  const ConfirmationScreen({
    super.key,
    required this.orderTrackingId,
    required this.redirectUrl,
  });

  @override
  ConsumerState<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends ConsumerState<ConfirmationScreen> {
  String? _transactionStatus;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _checkTransactionStatus();
  }

  Future<void> _checkTransactionStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final status = await ref
          .read(transferProvider.notifier)
          .getTransactionStatus(widget.orderTrackingId);
      setState(() {
        _transactionStatus = status;
        _isCheckingStatus = false;
      });
    } catch (e) {
      setState(() {
        _transactionStatus = 'Unknown';
        _isCheckingStatus = false;
      });
    }
  }

  void _openPaymentGateway() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WebViewScreen(url: widget.redirectUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Transfer Initiated',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your transfer has been successfully initiated',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              'Reference ID',
                              widget.orderTrackingId,
                            ),
                            _buildInfoRow('Timestamp', _formatDateTime(now)),
                            _buildInfoRow(
                              'Status',
                              _transactionStatus ?? 'Processing',
                            ),
                            if (_isCheckingStatus)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Next Steps',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You will be redirected to complete the payment process',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Complete Payment',
                    onPressed: _openPaymentGateway,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SecondaryButton(
                    label: 'Return to Home',
                    onPressed: () {
                      ref.read(transferProvider.notifier).reset();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
