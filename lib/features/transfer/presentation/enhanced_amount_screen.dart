import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../data/models.dart';
import '../data/transfer_repository.dart';
import '../../../core/network/failure.dart';
import 'pesapal_payment_method_screen.dart';
import 'dart:async';

class EnhancedAmountScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> transferDetails;

  const EnhancedAmountScreen({super.key, required this.transferDetails});

  @override
  ConsumerState<EnhancedAmountScreen> createState() =>
      _EnhancedAmountScreenState();
}

class _EnhancedAmountScreenState extends ConsumerState<EnhancedAmountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  double _transferAmount = 0.0;
  double _serviceFee = 0.0;
  double _totalAmount = 0.0;
  bool _isLoading = false;
  bool _isCalculatingFees = false;
  String? _errorMessage;
  Quote? _quote;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onAmountChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _calculateCharges();
    });
  }

  Future<void> _calculateCharges() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (amount <= 0) {
      setState(() {
        _transferAmount = 0.0;
        _serviceFee = 0.0;
        _totalAmount = 0.0;
        _quote = null;
      });
      return;
    }

    setState(() {
      _isCalculatingFees = true;
      _errorMessage = null;
    });

    try {
      // Get quote from API
      final repository = ref.read(transferRepositoryProvider);
      final quote = await repository.quoteTransfer(
        amount.toString(),
        'USD',
        'CD', // Default to Congo
      );

      setState(() {
        _transferAmount = amount;
        _serviceFee = quote.charges;
        _totalAmount = quote.totalCost;
        _quote = quote;
        _isCalculatingFees = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isCalculatingFees = false;
        // Fallback to local calculation
        _transferAmount = amount;
        _serviceFee = (amount * 0.02).clamp(1.0, 10.0);
        _totalAmount = _transferAmount + _serviceFee;
      });
    }
  }

  void _proceedToPaymentMethod() {
    if (!_formKey.currentState!.validate()) return;

    if (_transferAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentDetails = {
      ...widget.transferDetails,
      'amount': _transferAmount,
      'service_fee': _serviceFee,
      'total_amount': _totalAmount,
      'note': _noteController.text,
      'quote': _quote,
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            PesapalPaymentMethodScreen(transferDetails: paymentDetails),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transfer Amount'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.error.withOpacity(.1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipient info
                      _buildRecipientInfo(),
                      const SizedBox(height: 24),

                      // Amount input
                      _buildAmountInput(),
                      const SizedBox(height: 16),

                      // Optional note
                      _buildNoteInput(),
                      const SizedBox(height: 24),

                      // Transfer summary
                      if (_transferAmount > 0) _buildTransferSummary(),
                    ],
                  ),
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientInfo() {
    final recipientName = widget.transferDetails['recipient_name'] ?? 'Unknown';
    final recipientPhone = widget.transferDetails['recipient_phone'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(
              recipientName.isNotEmpty ? recipientName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sending to',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  recipientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  recipientPhone,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount to Send',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount (\$)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.attach_money),
            suffixIcon: _isCalculatingFees
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            if (amount > 1000) {
              return 'Maximum transfer amount is \$1,000';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Note (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Add a note for this transfer',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildTransferSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Transfer Amount',
            '\$${_transferAmount.toStringAsFixed(2)}',
          ),
          _buildSummaryRow(
            'Service Fee',
            '\$${_serviceFee.toStringAsFixed(2)}',
          ),
          const Divider(),
          _buildSummaryRow(
            'Total Amount',
            '\$${_totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
          if (_quote != null) ...[
            const SizedBox(height: 8),
            Text(
              'Exchange Rate: 1 USD = ${_quote!.exchangeRate.toStringAsFixed(2)} ${_quote!.currency}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_transferAmount > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready to send \$${_totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Continue to Payment',
              onPressed: _transferAmount > 0 ? _proceedToPaymentMethod : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Provider for transfer repository
final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  throw UnimplementedError(
    'Provide TransferRepository via override at app start',
  );
});
