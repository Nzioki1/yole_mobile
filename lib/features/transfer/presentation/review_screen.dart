import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/error_banner.dart';
import 'transfer_providers.dart';
import 'confirmation_screen.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transferProvider);
    final notifier = ref.read(transferProvider.notifier);
    final draft = state.draft;
    final quote = state.quote;

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Transfer')),
        body: const Center(
          child: Text('No transfer draft found. Please go back and try again.'),
        ),
      );
    }

    return LoadingOverlay(
      isLoading: state.isSubmitting,
      child: Scaffold(
        appBar: AppBar(title: const Text('Review Transfer')),
        body: Column(
          children: [
            if (state.error != null) 
              ErrorBanner(
                message: state.error!.message,
                onDismiss: () => notifier.clearError(),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transfer Details',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('Recipient ID', draft.recipientId),
                            _buildDetailRow('Phone Number', draft.phoneNumber),
                            _buildDetailRow('Country', draft.recipientCountry),
                            const Divider(),
                            _buildDetailRow('Amount', '\$${draft.amount.toStringAsFixed(2)}'),
                            _buildDetailRow('Currency', draft.currency),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (quote != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fees & Charges',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow('Transfer Amount', '\$${quote.amount.toStringAsFixed(2)}'),
                              _buildDetailRow('Service Fee', '\$${(quote.charges * quote.amount).toStringAsFixed(2)}'),
                              _buildDetailRow('Exchange Rate', '1 USD = ${quote.exchangeRate.toStringAsFixed(4)}'),
                              const Divider(),
                              _buildDetailRow(
                                'Total Cost',
                                '\$${quote.totalCost.toStringAsFixed(2)}',
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Confirm Transfer',
                        onPressed: state.isSubmitting ? null : () async {
                          await notifier.createTransfer();
                          if (context.mounted && state.redirect != null) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => ConfirmationScreen(
                                  orderTrackingId: state.redirect!.orderTrackingId,
                                  redirectUrl: state.redirect!.redirectUrl,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}