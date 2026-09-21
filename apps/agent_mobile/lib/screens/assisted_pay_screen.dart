import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';
import '../services/offline_agent_repository.dart';
import '../widgets/customer_lookup_field.dart';
import '../widgets/pin_input_modal.dart';
import '../constants/kinshasa_billers.dart';

class AssistedPayScreen extends StatefulWidget {
  const AssistedPayScreen({super.key});

  @override
  State<AssistedPayScreen> createState() => _AssistedPayScreenState();
}

class _AssistedPayScreenState extends State<AssistedPayScreen> {
  final _api = AgentApiService();
  final _repo = OfflineAgentRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  
  Map<String, dynamic>? _selectedCustomer;
  bool _isBillMode = true;
  Map<String, dynamic>? _selectedBiller;
  bool _loading = false;
  Map<String, dynamic>? _feePreview;
  String? _limitsError;

  @override
  void initState() {
    super.initState();
    _api.init();
    _amountController.addListener(_calculateFeePreview);
  }

  void _calculateFeePreview() {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || _selectedCustomer == null) {
      setState(() {
        _feePreview = null;
        _limitsError = null;
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() {
        _feePreview = null;
        _limitsError = null;
      });
      return;
    }

    final amountMinor = (amount * 100).toInt();
    final paymentType = _isBillMode ? 'AGENT_ASSISTED_BILL' : 'AGENT_ASSISTED_AIRTIME';

    try {
      final feeResult = _repo.getFee(
        paymentType: paymentType,
        currency: 'CDF',
        amountMinor: amountMinor,
      );

      final feeMinor = feeResult['feeMinor'] as int;
      final fee = feeMinor / 100;
      final totalDebit = amount + fee;

      // Check insufficient float
      final floatBalances = _repo.getFloatBalances();
      final pockets = floatBalances['pockets'] as List<dynamic>;
      final cdfPocket = pockets.firstWhere(
        (p) => p['currency'] == 'CDF',
        orElse: () => <String, dynamic>{'availableMinor': '0'},
      );
      final availableMinor = int.parse(cdfPocket['availableMinor']?.toString() ?? '0');
      final available = availableMinor / 100;
      final floatAfter = available - totalDebit;

      String? errorMsg;
      if (availableMinor < (totalDebit * 100).toInt()) {
        errorMsg = 'Insufficient float. Need FC ${totalDebit.toStringAsFixed(2)}, have FC ${available.toStringAsFixed(2)}';
      }

      setState(() {
        _feePreview = {
          'amount': amount,
          'fee': fee,
          'feeMinor': feeMinor,
          'totalDebit': totalDebit,
          'floatAfter': floatAfter,
        };
        _limitsError = errorMsg;
      });
    } catch (e) {
      setState(() {
        _feePreview = null;
        _limitsError = null;
      });
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_calculateFeePreview);
    _amountController.dispose();
    _accountNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _execute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please look up a customer first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isBillMode && _selectedBiller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a biller'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_limitsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_limitsError!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Show PIN modal for validation
    final pinValid = await showPinModal(context);
    if (!pinValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN validation failed. Transaction cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final amountMinor = (double.parse(_amountController.text) * 100).toInt();
      
      final result = await _api.payForCustomer(
        customerId: _selectedCustomer!['id'],
        kind: _isBillMode ? 'BILL' : 'AIRTIME',
        amountMinor: amountMinor,
        billerCode: _isBillMode ? _selectedBiller!['code'] : null,
        accountNumber: _isBillMode ? _accountNumberController.text.trim() : null,
        phoneNumber: _isBillMode ? null : _phoneController.text.trim(),
      );

      if (mounted) {
        final amount = double.parse(_amountController.text);
        final feeMinor = result['feeMinor'] as int;
        final fee = feeMinor / 100;
        final totalDebit = amount + fee;
        final floatAfter = (result['floatCdfMinorAfter'] as int) / 100;
        final timestamp = result['postedAt'] as String;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _isBillMode ? Icons.receipt_long : Icons.phone_android,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_isBillMode ? 'Bill Payment Complete' : 'Airtime Purchase Complete'),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RECEIPT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 8),
                  _buildReceiptRow('For Customer', '${_selectedCustomer!['firstName']} ${_selectedCustomer!['lastName']}'),
                  _buildReceiptRow('Phone', _selectedCustomer!['phoneE164'] ?? 'N/A'),
                  const Divider(),
                  if (_isBillMode) ...[
                    _buildReceiptRow('Biller', _selectedBiller!['name']),
                    _buildReceiptRow('Account', _accountNumberController.text.trim()),
                  ] else ...[
                    _buildReceiptRow('Phone Topped Up', _phoneController.text.trim()),
                  ],
                  const Divider(),
                  _buildReceiptRow('Amount', 'FC ${amount.toStringAsFixed(2)}', bold: true),
                  _buildReceiptRow('Fee', 'FC ${fee.toStringAsFixed(2)}'),
                  _buildReceiptRow('Total', 'FC ${totalDebit.toStringAsFixed(2)}', bold: true),
                  const Divider(),
                  _buildReceiptRow('Float Left', 'FC ${floatAfter.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildReceiptRow('Journal', result['journalId'], small: true),
                  _buildReceiptRow('Time', timestamp, small: true),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon')),
                  );
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share Receipt'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $errorMsg'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay for Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Bill'), icon: Icon(Icons.receipt_long)),
                ButtonSegment(value: false, label: Text('Airtime'), icon: Icon(Icons.phone_android)),
              ],
              selected: {_isBillMode},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isBillMode = newSelection.first;
                  _selectedBiller = null;
                  _accountNumberController.clear();
                  _phoneController.clear();
                  _amountController.clear();
                  _feePreview = null;
                  _limitsError = null;
                });
              },
            ),
            const SizedBox(height: 24),
            CustomerLookupField(
              onCustomerSelected: (customer) {
                setState(() => _selectedCustomer = customer);
              },
            ),
            const SizedBox(height: 16),
            if (_isBillMode) ...[
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _selectedBiller,
                decoration: const InputDecoration(labelText: 'Biller *'),
                items: kKinshasaBillers.map((biller) => DropdownMenuItem(
                  value: biller,
                  child: Text(biller['name'] as String),
                )).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedBiller = v;
                    if (v != null) {
                      _accountNumberController.text = v['demoAccountNumber'] as String;
                    }
                  });
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(labelText: 'Account Number *'),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                enabled: _selectedBiller != null,
              ),
            ] else ...[
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone to Top Up *',
                  hintText: '+243...',
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (CDF) *',
                hintText: 'e.g. 50.00',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              enabled: _selectedCustomer != null,
            ),
            if (_feePreview != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(),
                      _buildPreviewRow(
                        'Transaction Fee',
                        'FC ${(_feePreview!['fee'] as double).toStringAsFixed(2)}',
                      ),
                      _buildPreviewRow(
                        'Total Debit',
                        'FC ${(_feePreview!['totalDebit'] as double).toStringAsFixed(2)}',
                        highlight: true,
                      ),
                      _buildPreviewRow(
                        'Float After',
                        'FC ${(_feePreview!['floatAfter'] as double).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_limitsError != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _limitsError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _execute,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.green.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool bold = false, bool small = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: small ? 10 : 14,
                color: small ? Colors.grey : Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: small ? 10 : 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: small ? Colors.grey : Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
