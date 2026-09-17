import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/core_api_service.dart';
import '../widgets/pin_confirm_sheet.dart';

class FxScreen extends StatefulWidget {
  const FxScreen({super.key});

  @override
  State<FxScreen> createState() => _FxScreenState();
}

class _FxScreenState extends State<FxScreen> {
  final _api = CoreApiService();
  bool _loading = true;
  List<dynamic> _rates = [];
  final _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'CDF';
  Map<String, dynamic>? _conversionPreview;
  Map<String, dynamic>? _conversionResult;

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() => _loading = true);
    try {
      final rates = await _api.getFxRates();
      setState(() => _rates = rates);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading rates: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _previewConversion() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
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

    if (_fromCurrency == _toCurrency) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select different currencies')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Get the specific rate
      final rateInfo = _rates.firstWhere(
        (r) => r['fromCurrency'] == _fromCurrency && r['toCurrency'] == _toCurrency,
        orElse: () => null,
      );

      final rate = rateInfo?['rate'] ?? 1.0;
      final fromAmountMinor = (amount * 100).toInt();
      final toAmountMinor = (fromAmountMinor * rate).toInt();

      setState(() {
        _conversionPreview = {
          'fromCurrency': _fromCurrency,
          'toCurrency': _toCurrency,
          'fromAmountMinor': fromAmountMinor,
          'toAmountMinor': toAmountMinor,
          'rate': rate,
        };
        _conversionResult = null;
      });
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

  Future<void> _confirmConversion() async {
    if (_conversionPreview == null) return;

    // Show PIN confirmation (debiting from wallet)
    final pinConfirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PinConfirmSheet(
        title: 'Confirm Currency Exchange',
        message: 'Enter your PIN to convert funds',
        onPinEntered: (pin) async {
          return true; // PIN verified in the sheet
        },
      ),
    );

    if (pinConfirmed != true) return;

    setState(() => _loading = true);

    try {
      final result = await _api.convertCurrency(
        fromCurrency: _conversionPreview!['fromCurrency'],
        toCurrency: _conversionPreview!['toCurrency'],
        fromAmountMinor: _conversionPreview!['fromAmountMinor'].toString(),
      );

      setState(() {
        _conversionResult = result;
        _conversionPreview = null;
        _amountController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Currency conversion completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversion failed: $e'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Exchange'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRates,
          ),
        ],
      ),
      body: _loading && _rates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRates,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exchange Rates Card
                    _buildRatesCard(theme),
                    const SizedBox(height: 24),

                    // Conversion Form
                    _buildConversionForm(theme),
                    const SizedBox(height: 24),

                    // Conversion Preview
                    if (_conversionPreview != null) _buildPreviewCard(theme),

                    // Conversion Result Receipt
                    if (_conversionResult != null) _buildReceiptCard(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRatesCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Current Exchange Rates',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_rates.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No rates available', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._rates.map((rate) {
                final from = rate['fromCurrency'];
                final to = rate['toCurrency'];
                final rateValue = rate['rate'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              from,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              to,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        rateValue.toStringAsFixed(4),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildConversionForm(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Convert Currency',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // From Currency
            DropdownButtonFormField<String>(
              value: _fromCurrency,
              decoration: const InputDecoration(
                labelText: 'From Currency',
                border: OutlineInputBorder(),
              ),
              items: ['USD', 'CDF'].map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _fromCurrency = v!;
                  _conversionPreview = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // To Currency
            DropdownButtonFormField<String>(
              value: _toCurrency,
              decoration: const InputDecoration(
                labelText: 'To Currency',
                border: OutlineInputBorder(),
              ),
              items: ['USD', 'CDF'].map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (v) {
                setState(() {
                  _toCurrency = v!;
                  _conversionPreview = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$_fromCurrency ',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _conversionPreview = null),
            ),
            const SizedBox(height: 16),

            // Preview Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _previewConversion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Preview Conversion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final fromAmount = (_conversionPreview!['fromAmountMinor'] / 100).toStringAsFixed(2);
    final toAmount = (_conversionPreview!['toAmountMinor'] / 100).toStringAsFixed(2);
    final rate = _conversionPreview!['rate'];
    final fromCurr = _conversionPreview!['fromCurrency'];
    final toCurr = _conversionPreview!['toCurrency'];

    return Card(
      elevation: 2,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversion Preview',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _ConversionRow(label: 'From', value: '$fromCurr $fromAmount'),
            _ConversionRow(label: 'Exchange Rate', value: rate.toStringAsFixed(4)),
            const Divider(height: 24),
            _ConversionRow(
              label: 'You Receive',
              value: '$toCurr $toAmount',
              bold: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _conversionPreview = null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _confirmConversion,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(ThemeData theme) {
    final fromAmount = (int.parse(_conversionResult!['fromAmountMinor'].toString()) / 100).toStringAsFixed(2);
    final toAmount = (int.parse(_conversionResult!['toAmountMinor'].toString()) / 100).toStringAsFixed(2);
    final rate = _conversionResult!['rate'];
    final fromCurr = _conversionResult!['fromCurrency'];
    final toCurr = _conversionResult!['toCurrency'];
    final journalId = _conversionResult!['journalId'] ?? 'N/A';

    return Card(
      elevation: 2,
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 12),
                Text(
                  'Conversion Complete',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _ConversionRow(label: 'Converted From', value: '$fromCurr $fromAmount'),
            _ConversionRow(label: 'Exchange Rate', value: rate.toStringAsFixed(4)),
            _ConversionRow(label: 'Received', value: '$toCurr $toAmount', bold: true),
            const Divider(height: 24),
            _ConversionRow(
              label: 'Transaction ID',
              value: journalId,
              mono: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: journalId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaction ID copied')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy ID'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _conversionResult = null),
                    child: const Text('New Conversion'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool mono;

  const _ConversionRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              fontSize: bold ? 16 : 14,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}
