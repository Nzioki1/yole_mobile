import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/api_providers.dart';
import '../services/core_api_service.dart';
import '../widgets/pin_confirm_sheet.dart';

/// Fund Wallet Screen - Add money via MNO or Bank
class FundWalletScreen extends ConsumerStatefulWidget {
  const FundWalletScreen({super.key});

  @override
  ConsumerState<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends ConsumerState<FundWalletScreen> {
  String _selectedRail = 'MNO_IN';
  String _selectedCurrency = 'CDF';
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _quote;

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _requestQuote() async {
    if (_amountController.text.trim().isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    if (_selectedRail == 'MNO_IN' && _phoneController.text.trim().isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    if (_selectedRail == 'BANK_IN' && _accountController.text.trim().isEmpty) {
      _showError('Please enter an account number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ref.read(coreApiServiceProvider);
      final amountMinor = (double.parse(_amountController.text) * 100).toInt();

      final metadata = <String, dynamic>{};
      if (_selectedRail == 'MNO_IN') {
        metadata['phoneNumber'] = _phoneController.text.trim();
      } else if (_selectedRail == 'BANK_IN') {
        metadata['accountNumber'] = _accountController.text.trim();
      }

      final quote = await api.quotePayment(
        type: _selectedRail,
        currency: _selectedCurrency,
        amountMinor: amountMinor.toString(),
        metadata: metadata,
      );

      setState(() {
        _quote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to get quote: $e');
    }
  }

  Future<void> _confirmPayment() async {
    if (_quote == null) return;

    // Check if PIN is required (for inbound funding, PIN is optional but we'll require it for consistency)
    final api = ref.read(coreApiServiceProvider);
    final hasPin = await api.hasPin();

    if (!hasPin) {
      // First time - prompt to set PIN
      _showSetPinDialog();
      return;
    }

    // Show PIN confirmation sheet
    if (!mounted) return;
    final pin = await PinConfirmSheet.show(
      context,
      title: 'Confirm Funding',
      message: 'Enter your PIN to fund your wallet',
    );

    if (pin == null || !mounted) return;

    setState(() => _isLoading = true);

    try {
      // Verify PIN
      final pinValid = await api.verifyPin(pin: pin);
      if (!pinValid) {
        setState(() => _isLoading = false);
        _showError('Invalid PIN');
        return;
      }

      final idempotencyKey = const Uuid().v4();

      final result = await api.confirmPayment(
        paymentId: _quote!['paymentId'],
        idempotencyKey: idempotencyKey,
      );

      if (!mounted) return;

      // Success - navigate to result screen
      Navigator.of(context).pushReplacementNamed(
        '/payment/result',
        arguments: {
          'success': result['status'] == 'POSTED',
          'paymentId': result['paymentId'],
          'message': result['status'] == 'POSTED'
              ? 'Wallet funded successfully'
              : 'Payment ${result['status'].toString().toLowerCase()}',
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to confirm payment: $e');
    }
  }

  Future<void> _showSetPinDialog() async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Transaction PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please set a 4-6 digit PIN for secure transactions'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN',
                hintText: '4-6 digits',
              ),
            ),
            TextField(
              controller: confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text != confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }
              if (pinController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be at least 4 digits')),
                );
                return;
              }
              try {
                final api = ref.read(coreApiServiceProvider);
                await api.setPin(pin: pinController.text);
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to set PIN: $e')),
                  );
                }
              }
            },
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );

    if (result == true) {
      // PIN set successfully, retry confirm
      _confirmPayment();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Money'),
        elevation: 0,
      ),
      body: _quote == null ? _buildFormView() : _buildQuoteView(),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose funding method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildRailSelector(),
          const SizedBox(height: 24),
          _buildCurrencySelector(),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Amount',
              hintText: 'Enter amount',
              prefixText: _selectedCurrency == 'CDF' ? 'FC ' : '\$ ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedRail == 'MNO_IN')
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Money Number',
                hintText: '+243...',
                border: OutlineInputBorder(),
              ),
            ),
          if (_selectedRail == 'BANK_IN')
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bank Account Number',
                hintText: 'Enter account number',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _requestQuote,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Get Quote', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteView() {
    final amountMinor = int.tryParse(_quote!['amountMinor'] ?? '0') ?? 0;
    final feeMinor = int.tryParse(_quote!['feeMinor'] ?? '0') ?? 0;
    final totalMinor = int.tryParse(_quote!['totalMinor'] ?? '0') ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow('Method', _selectedRail == 'MNO_IN' ? 'Mobile Money' : 'Bank Transfer'),
                  _buildSummaryRow('Currency', _selectedCurrency),
                  _buildSummaryRow('Amount', _formatMinor(amountMinor, _selectedCurrency)),
                  _buildSummaryRow('Fee', _formatMinor(feeMinor, _selectedCurrency)),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Total',
                    _formatMinor(totalMinor, _selectedCurrency),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _isLoading ? null : _confirmPayment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _quote = null);
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Back', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildRailSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildRailOption('MNO_IN', 'Mobile Money', Icons.phone_android),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRailOption('BANK_IN', 'Bank Transfer', Icons.account_balance),
        ),
      ],
    );
  }

  Widget _buildRailOption(String value, String label, IconData icon) {
    final isSelected = _selectedRail == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRail = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Row(
      children: [
        Expanded(
          child: RadioListTile<String>(
            title: const Text('CDF'),
            value: 'CDF',
            groupValue: _selectedCurrency,
            onChanged: (val) => setState(() => _selectedCurrency = val!),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        Expanded(
          child: RadioListTile<String>(
            title: const Text('USD'),
            value: 'USD',
            groupValue: _selectedCurrency,
            onChanged: (val) => setState(() => _selectedCurrency = val!),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinor(int minor, String currency) {
    final major = (minor / 100).toStringAsFixed(2);
    return currency == 'CDF' ? 'FC $major' : '\$$major';
  }
}
