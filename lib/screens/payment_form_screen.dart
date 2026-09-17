import 'package:flutter/material.dart';
import '../services/core_api_service.dart';

/// Universal payment form for all rail types
class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({
    super.key,
    required this.railType,
    this.prefillDestination,
    this.prefillNote,
  });

  final String railType; // W2W, MNO_OUT, BANK_OUT, BILL, AIRTIME
  final String? prefillDestination; // Phone number or wallet ID
  final String? prefillNote; // Optional note/recipient name

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = CoreApiService();
  final _amountController = TextEditingController();
  final _destinationController = TextEditingController();
  final _accountController = TextEditingController();
  final _bankCodeController = TextEditingController();
  
  String _currency = 'USD';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _api.init();
    
    // Prefill from widget arguments if provided
    if (widget.prefillDestination != null) {
      _destinationController.text = widget.prefillDestination!;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _destinationController.dispose();
    _accountController.dispose();
    _bankCodeController.dispose();
    super.dispose();
  }

  String get _railTitle {
    switch (widget.railType) {
      case 'W2W':
        return 'Wallet to Wallet';
      case 'MNO_OUT':
        return 'Mobile Money';
      case 'BANK_OUT':
        return 'Bank Transfer';
      case 'BILL':
        return 'Pay Bill';
      case 'AIRTIME':
        return 'Buy Airtime';
      default:
        return 'Payment';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_railTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount field
                Text(
                  'Amount',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    prefixText: _currency == 'USD' ? '\$ ' : 'FC ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    if (double.tryParse(v) == null) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Currency selector
                Text(
                  'Currency',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _CurrencyChip(
                        label: 'USD',
                        selected: _currency == 'USD',
                        onTap: () => setState(() => _currency = 'USD'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CurrencyChip(
                        label: 'CDF',
                        selected: _currency == 'CDF',
                        onTap: () => setState(() => _currency = 'CDF'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rail-specific fields
                ..._buildRailSpecificFields(theme),

                const SizedBox(height: 32),

                // Continue button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Get Quote',
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
      ),
    );
  }

  List<Widget> _buildRailSpecificFields(ThemeData theme) {
    switch (widget.railType) {
      case 'W2W':
        return [
          Text(
            'Recipient Customer ID',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _destinationController,
            decoration: InputDecoration(
              hintText: 'cust_123',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Customer ID is required'
                : null,
          ),
        ];

      case 'MNO_OUT':
      case 'AIRTIME':
        return [
          Text(
            'Phone Number',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _destinationController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+243 XXX XXX XXX',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Phone number is required'
                : null,
          ),
        ];

      case 'BANK_OUT':
        return [
          Text(
            'Account Number',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountController,
            decoration: InputDecoration(
              hintText: 'Enter account number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Account number is required'
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Bank Code',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bankCodeController,
            decoration: InputDecoration(
              hintText: 'e.g., RAWBANK',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Bank code is required'
                : null,
          ),
        ];

      case 'BILL':
        return [
          Text(
            'Biller Code',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _bankCodeController,
            decoration: InputDecoration(
              hintText: 'e.g., SNEL, REGIDESO',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Biller code is required'
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Account Number',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountController,
            decoration: InputDecoration(
              hintText: 'Your account/meter number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Account number is required'
                : null,
          ),
        ];

      default:
        return [];
    }
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final amount = double.parse(_amountController.text);
      final amountMinor = (amount * 100).toInt().toString();

      // Build metadata based on rail type
      final metadata = <String, dynamic>{};
      
      switch (widget.railType) {
        case 'W2W':
          metadata['toCustomerId'] = _destinationController.text.trim();
          break;
        case 'MNO_OUT':
        case 'AIRTIME':
          metadata['phoneNumber'] = _destinationController.text.trim();
          break;
        case 'BANK_OUT':
          metadata['accountNumber'] = _accountController.text.trim();
          metadata['bankCode'] = _bankCodeController.text.trim();
          break;
        case 'BILL':
          metadata['billerCode'] = _bankCodeController.text.trim();
          metadata['accountNumber'] = _accountController.text.trim();
          break;
      }

      // Get quote
      final quote = await _api.quotePayment(
        type: widget.railType,
        currency: _currency,
        amountMinor: amountMinor,
        metadata: metadata,
      );

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/payment/quote',
          arguments: {
            'quote': quote,
            'railType': widget.railType,
            'currency': _currency,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor.withOpacity(0.1) : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : (theme.brightness == Brightness.dark
                    ? const Color(0xFF2B2F58)
                    : const Color(0xFFE5E7EB)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? theme.primaryColor : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
