import 'package:flutter/material.dart';
import '../services/core_api_service.dart';
import '../widgets/pin_confirm_sheet.dart';

class CreditApplyScreen extends StatefulWidget {
  final String type;

  const CreditApplyScreen({super.key, required this.type});

  @override
  State<CreditApplyScreen> createState() => _CreditApplyScreenState();
}

class _CreditApplyScreenState extends State<CreditApplyScreen> {
  final _api = CoreApiService();
  final _amountController = TextEditingController();
  bool _loading = false;
  bool _agreeToTerms = false;
  String _currency = 'USD';
  int _termMonths = 3;
  Map<String, dynamic>? _eligibility;

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadEligibility();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadEligibility() async {
    setState(() => _loading = true);
    try {
      final result = await _api.checkCreditEligibility(type: widget.type);
      setState(() => _eligibility = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitApplication() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms and conditions')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final amountMinor = (amount * 100).toInt().toString();

    // Show PIN confirmation
    final pinConfirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PinConfirmSheet(
        title: 'Confirm Loan Application',
        subtitle: 'Enter your PIN to proceed',
        onPinEntered: (pin) {
          Navigator.of(context).pop(true);
        },
      ),
    );

    if (pinConfirmed != true) return;

    setState(() => _loading = true);

    try {
      final result = await _api.requestLoan(
        type: widget.type,
        principalMinor: amountMinor,
        currency: _currency,
        termMonths: _termMonths,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Return to credit screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loan disbursed successfully! ID: ${result['loanId']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEligible = _eligibility?['eligible'] == true;
    final maxAmount = _eligibility?['maxAmountMinor'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatType(widget.type)),
      ),
      body: _loading && _eligibility == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eligibility Banner
                  if (_eligibility != null && !isEligible)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _eligibility?['reason'] ?? 'You are not eligible for this product',
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (isEligible) ...[
                    // Product Info
                    Text(
                      'Loan Details',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Amount Field
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Loan Amount',
                        hintText: 'Enter amount',
                        prefixText: '$_currency ',
                        suffixText: maxAmount != null
                            ? 'Max: ${(int.parse(maxAmount.toString()) / 100).toStringAsFixed(0)}'
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Currency Selector
                    DropdownButtonFormField<String>(
                      value: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: ['USD', 'CDF'].map((curr) {
                        return DropdownMenuItem(value: curr, child: Text(curr));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currency = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Term Selector
                    DropdownButtonFormField<int>(
                      value: _termMonths,
                      decoration: const InputDecoration(
                        labelText: 'Repayment Term',
                        border: OutlineInputBorder(),
                      ),
                      items: [1, 3, 6, 12].map((months) {
                        return DropdownMenuItem(
                          value: months,
                          child: Text('$months ${months == 1 ? 'month' : 'months'}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _termMonths = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Mock Terms
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Conditions (Mock)',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Interest rate: 5% per month (mock)\n'
                            '• Processing fee: 2% of principal\n'
                            '• Late payment penalty: 1% per day\n'
                            '• Instant disbursement to wallet\n'
                            '• Flexible repayment schedule\n'
                            '• Early repayment allowed',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Consent Checkbox
                    CheckboxListTile(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() => _agreeToTerms = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'I agree to the terms and conditions and authorize deduction of repayments from my wallet',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submitApplication,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Application'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _formatType(String type) {
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }
}
