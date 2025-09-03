import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../core/utils/validators.dart';
import '../data/models.dart';
import 'transfer_providers.dart';
import 'review_screen.dart';

class SendAmountScreen extends ConsumerStatefulWidget {
  final String recipientId;
  final String recipientName;
  final String recipientPhone;

  const SendAmountScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    required this.recipientPhone,
  });

  @override
  ConsumerState<SendAmountScreen> createState() => _SendAmountScreenState();
}

class _SendAmountScreenState extends ConsumerState<SendAmountScreen> {
  final _amount = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amount.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onAmountChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_amount.text.isNotEmpty) {
        final amount = double.tryParse(_amount.text);
        if (amount != null && amount > 0) {
          ref
              .read(transferProvider.notifier)
              .getQuote(
                _amount.text,
                'USD',
                'CD', // Default recipient country
              );
        }
      }
    });
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 10000) {
      return 'Amount cannot exceed \$10,000';
    }

    return null;
  }

  void _proceedToReview() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amount.text) ?? 0;

      ref
          .read(transferProvider.notifier)
          .createDraft(
            widget.recipientId,
            amount,
            phoneNumber: widget.recipientPhone,
          );

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ReviewScreen()));
    }
  }

  void _showRecipientPicker(BuildContext context) {
    // Navigate to recipients screen to select a different recipient
    Navigator.of(context).pushNamed('/recipients');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transferProvider);
    final notifier = ref.read(transferProvider.notifier);

    return LoadingOverlay(
      isLoading: state.loading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Send Money')),
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
                child: Form(
                  key: _formKey,
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
                                'Recipient',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.recipientName,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                widget.recipientPhone,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Amount',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amount,
                        decoration: const InputDecoration(
                          labelText: 'Enter amount',
                          prefixText: '\$',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateAmount,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),
                      if (state.quote != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transfer Summary',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Amount:'),
                                    Text(
                                      '\$${state.quote!.amount.toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Fees:'),
                                    Text(
                                      '\$${(state.quote!.charges * state.quote!.amount).toStringAsFixed(2)}',
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total:',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    Text(
                                      '\$${state.quote!.totalCost.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: 'Continue',
                          onPressed: state.quote != null
                              ? _proceedToReview
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
