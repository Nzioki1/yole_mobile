import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';
import '../services/offline_agent_repository.dart';
import '../widgets/customer_lookup_field.dart';
import '../widgets/pin_input_modal.dart';

class CashInOutScreen extends StatefulWidget {
  const CashInOutScreen({super.key});

  @override
  State<CashInOutScreen> createState() => _CashInOutScreenState();
}

class _CashInOutScreenState extends State<CashInOutScreen> {
  final _api = AgentApiService();
  final _repo = OfflineAgentRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  Map<String, dynamic>? _selectedCustomer;
  String _currency = 'USD';
  bool _isCashIn = true;
  bool _loading = false;
  Map<String, dynamic>? _feePreview;
  Map<String, dynamic>? _todayUsage;
  String? _limitsError;

  @override
  void initState() {
    super.initState();
    _api.init();
    _amountController.addListener(_calculateFeePreview);
    _loadTodayUsage();
  }

  Future<void> _loadTodayUsage() async {
    try {
      final usage = _repo.getTodayUsage();
      setState(() => _todayUsage = usage);
    } catch (e) {
      // Agent not logged in yet, will retry on execute
      debugPrint('Failed to load today usage: $e');
    }
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
    final paymentType = _isCashIn ? 'AGENT_CASH_IN' : 'AGENT_CASH_OUT';

    try {
      final feeResult = _repo.getFee(
        paymentType: paymentType,
        currency: _currency,
        amountMinor: amountMinor,
      );

      final feeMinor = feeResult['feeMinor'] as int;
      final fee = feeMinor / 100;
      final symbol = _currency == 'CDF' ? 'FC' : '\$';

      // Check limits
      final limitsCheck = _repo.isWithinLimits(
        amountMinor: amountMinor,
        currency: _currency,
      );

      // Check insufficient float for cash-in
      String? errorMsg;
      if (_isCashIn) {
        final floatBalances = _repo.getFloatBalances();
        final pockets = floatBalances['pockets'] as List<dynamic>;
        final agentPocket = pockets.firstWhere(
          (p) => p['currency'] == _currency,
          orElse: () => <String, dynamic>{'availableMinor': '0'},
        );
        final availableMinor = int.parse(agentPocket['availableMinor']?.toString() ?? '0');
        final available = availableMinor / 100;

        if (availableMinor < amountMinor) {
          errorMsg = 'Insufficient float. Available: $symbol${available.toStringAsFixed(2)}. Requested: $symbol${amount.toStringAsFixed(2)}.';
        }
      }

      if (errorMsg == null && !(limitsCheck['withinLimits'] as bool)) {
        errorMsg = limitsCheck['reason'] as String?;
      }

      setState(() {
        _feePreview = {
          'amount': amount,
          'fee': fee,
          'feeMinor': feeMinor,
          'symbol': symbol,
          'totalDebit': _isCashIn ? amount : amount + fee,
          'customerReceives': _isCashIn ? amount : 0,
          'customerDebited': _isCashIn ? 0 : amount + fee,
          'agentFloatChange': _isCashIn ? -amount : amount,
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
      final amountMinor = (double.parse(_amountController.text) * 100).toInt().toString();
      
      final result = _isCashIn
          ? await _api.cashIn(
              customerId: _selectedCustomer!['id'],
              amountMinor: amountMinor,
              currency: _currency,
            )
          : await _api.cashOut(
              customerId: _selectedCustomer!['id'],
              amountMinor: amountMinor,
              currency: _currency,
            );

      if (mounted) {
        // Fetch updated balances
        final customerWallet = _repo.getWallet(
          customerId: _selectedCustomer!['id'],
          currency: _currency,
        );
        final agentFloat = _repo.getFloatBalances();

        final amount = double.parse(_amountController.text);
        final feeMinor = int.parse(result['feeMinor']?.toString() ?? '0');
        final fee = feeMinor / 100;
        final currencySymbol = _currency == 'CDF' ? 'FC' : '\$';
        final timestamp = DateTime.now().toUtc().toIso8601String();

        final customerBalanceAfter = int.parse(customerWallet['availableMinor']?.toString() ?? '0') / 100;
        
        // Get agent float for current currency
        final pockets = agentFloat['pockets'] as List<dynamic>;
        final agentPocket = pockets.firstWhere((p) => p['currency'] == _currency);
        final agentFloatAfter = int.parse(agentPocket['availableMinor']?.toString() ?? '0') / 100;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
                  color: _isCashIn ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${_isCashIn ? "Cash-In" : "Cash-Out"} Complete'),
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
                  _buildReceiptRow('Customer', '${_selectedCustomer!['firstName']} ${_selectedCustomer!['lastName']}'),
                  _buildReceiptRow('Phone', _selectedCustomer!['phoneE164'] ?? 'N/A'),
                  const Divider(),
                  _buildReceiptRow('Amount', '$currencySymbol${amount.toStringAsFixed(2)}', bold: true),
                  _buildReceiptRow('Transaction Fee', '$currencySymbol${fee.toStringAsFixed(2)}'),
                  if (_isCashIn)
                    _buildReceiptRow('Customer Credited', '$currencySymbol${amount.toStringAsFixed(2)}', highlight: true)
                  else
                    _buildReceiptRow('Customer Debited', '$currencySymbol${(amount + fee).toStringAsFixed(2)}', highlight: true),
                  const Divider(),
                  _buildReceiptRow('Customer Balance After', '$currencySymbol${customerBalanceAfter.toStringAsFixed(2)}'),
                  _buildReceiptRow('Agent Float After', '$currencySymbol${agentFloatAfter.toStringAsFixed(2)}'),
                  const Divider(),
                  _buildReceiptRow('Journal ID', result['journalId'], small: true),
                  _buildReceiptRow('Timestamp', timestamp, small: true),
                  _buildReceiptRow('Status', result['status'], small: true),
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
                  // Refresh usage after successful transaction
                  _loadTodayUsage();
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
            content: Text('${_isCashIn ? "Cash-in" : "Cash-out"} failed: $errorMsg'),
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
      appBar: AppBar(title: const Text('Cash In / Out')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Cash In'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: false, label: Text('Cash Out'), icon: Icon(Icons.arrow_upward)),
              ],
              selected: {_isCashIn},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isCashIn = newSelection.first;
                  _calculateFeePreview();
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
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: ['USD', 'CDF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) {
                setState(() {
                  _currency = v!;
                  _calculateFeePreview();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount *'),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              enabled: _selectedCustomer != null,
            ),
            if (_todayUsage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Limits',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(),
                      _buildLimitsRow(
                        'CDF Daily',
                        _todayUsage!['totalCdfMinor'] as int,
                        _todayUsage!['dailyLimitCdfMinor'] as int,
                        'FC',
                      ),
                      _buildLimitsRow(
                        'USD Daily',
                        _todayUsage!['totalUsdMinor'] as int,
                        _todayUsage!['dailyLimitUsdMinor'] as int,
                        '\$',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Per-txn max: FC ${(_todayUsage!['perTxnLimitCdfMinor'] as int / 100).toStringAsFixed(2)} / \$${(_todayUsage!['perTxnLimitUsdMinor'] as int / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                        '${_feePreview!['symbol']}${(_feePreview!['fee'] as double).toStringAsFixed(2)}',
                      ),
                      if (_isCashIn) ...[
                        _buildPreviewRow(
                          'Customer Credited',
                          '${_feePreview!['symbol']}${(_feePreview!['customerReceives'] as double).toStringAsFixed(2)}',
                          highlight: true,
                        ),
                        _buildPreviewRow(
                          'Agent Float Change',
                          '${_feePreview!['symbol']}${(_feePreview!['agentFloatChange'] as double).toStringAsFixed(2)}',
                        ),
                      ] else ...[
                        _buildPreviewRow(
                          'Customer Debited',
                          '${_feePreview!['symbol']}${(_feePreview!['customerDebited'] as double).toStringAsFixed(2)}',
                          highlight: true,
                        ),
                        _buildPreviewRow(
                          'Agent Float Change',
                          '+${_feePreview!['symbol']}${(_feePreview!['agentFloatChange'] as double).toStringAsFixed(2)}',
                        ),
                      ],
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
                backgroundColor: _isCashIn ? Colors.green : Colors.orange,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isCashIn ? 'Cash In' : 'Cash Out'),
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

  Widget _buildLimitsRow(String label, int used, int limit, String symbol) {
    final usedAmount = used / 100;
    final limitAmount = limit / 100;
    final percentage = limit > 0 ? (used / limit * 100) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '$symbol${usedAmount.toStringAsFixed(2)} / $symbol${limitAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade300,
            color: percentage > 80
                ? Colors.red
                : percentage > 50
                    ? Colors.orange
                    : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool bold = false, bool highlight = false, bool small = false}) {
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
                color: highlight ? Colors.green.shade700 : (small ? Colors.grey : Colors.black),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
