import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/api_providers.dart';
import '../widgets/pin_confirm_sheet.dart';

/// Withdraw Screen - Send money out to MNO or Bank
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  String _selectedRail = 'MNO_OUT';
  String _selectedCurrency = 'CDF';
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _quote;
  Map<String, dynamic>? _walletData;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    try {
      final api = ref.read(coreApiServiceProvider);
      final data = await api.getMyWallets();
      if (mounted) {
        setState(() => _walletData = data);
      }
    } catch (e) {
      // Wallet loading failed - non-blocking
    }
  }

  int _getAvailableBalance(String currency) {
    if (_walletData == null) return 0;
    final wallets = _walletData!['wallets'] as List?;
    if (wallets == null || wallets.isEmpty) return 0;

    for (final wallet in wallets) {
      final pockets = wallet['pockets'] as List?;
      if (pockets == null) continue;
      for (final pocket in pockets) {
        if (pocket['currency'] == currency) {
          final availableMinor = pocket['availableMinor'];
          return int.tryParse(availableMinor?.toString() ?? '0') ?? 0;
        }
      }
    }
    return 0;
  }

  Future<void> _requestQuote() async {
    if (_amountController.text.trim().isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    if (_selectedRail == 'MNO_OUT' && _phoneController.text.trim().isEmpty) {
      _showError('Please enter a phone number');
      return;
    }

    if (_selectedRail == 'BANK_OUT' && _accountController.text.trim().isEmpty) {
      _showError('Please enter an account number');
      return;
    }

    final amountMinor = (double.parse(_amountController.text) * 100).toInt();
    final availableMinor = _getAvailableBalance(_selectedCurrency);

    if (amountMinor <= 0) {
      _showError('Amount must be greater than zero');
      return;
    }

    // Check if sufficient funds (rough check - server will validate precisely)
    if (amountMinor > availableMinor) {
      _showError('Insufficient funds in $_selectedCurrency wallet');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = ref.read(coreApiServiceProvider);

      final metadata = <String, dynamic>{};
      if (_selectedRail == 'MNO_OUT') {
        metadata['phoneE164'] = _phoneController.text.trim();
      } else if (_selectedRail == 'BANK_OUT') {
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

    // Check if PIN is set
    final api = ref.read(coreApiServiceProvider);
    final hasPin = await api.hasPin();

    if (!hasPin) {
      _showError('Please set a transaction PIN first. Go to Profile → Settings.');
      return;
    }

    // Show PIN confirmation sheet
    if (!mounted) return;
    final pin = await PinConfirmSheet.show(
      context,
      title: 'Confirm Withdrawal',
      message: 'Enter your PIN to withdraw funds',
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

      final result = await api.confirmPayment(
        paymentId: _quote!['paymentId'],
      );

      if (!mounted) return;

      // Success - navigate to result screen
      Navigator.of(context).pushReplacementNamed(
        '/payment/result',
        arguments: {
          'success': result['status'] == 'POSTED',
          'paymentId': result['paymentId'],
          'message': result['status'] == 'POSTED'
              ? 'Withdrawal successful'
              : 'Payment ${result['status'].toString().toLowerCase()}',
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to confirm withdrawal: $e');
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
        title: const Text('Withdraw Money'),
        elevation: 0,
      ),
      body: _quote == null ? _buildFormView() : _buildQuoteView(),
    );
  }

  Widget _buildFormView() {
    final availableMinor = _getAvailableBalance(_selectedCurrency);
    final available = (availableMinor / 100).toStringAsFixed(2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance display
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedCurrency == 'CDF' ? 'FC $available' : '\$$available',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Withdraw to',
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
          if (_selectedRail == 'MNO_OUT')
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Recipient Phone Number',
                hintText: '+243...',
                border: OutlineInputBorder(),
              ),
            ),
          if (_selectedRail == 'BANK_OUT')
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Recipient Account Number',
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
    final taxMinor = int.tryParse(_quote!['taxMinor']?.toString() ?? '0') ?? 0;
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
                    'Withdrawal Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow('Method', _selectedRail == 'MNO_OUT' ? 'Mobile Money' : 'Bank Transfer'),
                  _buildSummaryRow('Currency', _selectedCurrency),
                  _buildSummaryRow(
                    'Recipient Gets',
                    _formatMinor(amountMinor, _selectedCurrency),
                  ),
                  _buildSummaryRow('Fee', _formatMinor(feeMinor, _selectedCurrency)),
                  if (taxMinor > 0)
                    _buildSummaryRow('Tax', _formatMinor(taxMinor, _selectedCurrency)),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Total (from your wallet)',
                    _formatMinor(totalMinor, _selectedCurrency),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will deduct ${_formatMinor(totalMinor, _selectedCurrency)} from your wallet',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
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
                : const Text('Confirm Withdrawal', style: TextStyle(fontSize: 16)),
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
          child: _buildRailOption('MNO_OUT', 'Mobile Money', Icons.phone_android),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRailOption('BANK_OUT', 'Bank Transfer', Icons.account_balance),
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
