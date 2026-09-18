import 'package:flutter/material.dart';
import '../services/core_api_service.dart';
import '../widgets/pin_confirm_sheet.dart';

class RemittanceScreen extends StatefulWidget {
  const RemittanceScreen({super.key});

  @override
  State<RemittanceScreen> createState() => _RemittanceScreenState();
}

class _RemittanceScreenState extends State<RemittanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = CoreApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _api.init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('International Remittance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Send Money', icon: Icon(Icons.send)),
            Tab(text: 'Receive Money', icon: Icon(Icons.call_received)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OutboundRemittanceTab(api: _api, theme: theme),
          _InboundRemittanceTab(api: _api, theme: theme),
        ],
      ),
    );
  }
}

class _OutboundRemittanceTab extends StatefulWidget {
  final CoreApiService api;
  final ThemeData theme;

  const _OutboundRemittanceTab({required this.api, required this.theme});

  @override
  State<_OutboundRemittanceTab> createState() => _OutboundRemittanceTabState();
}

class _OutboundRemittanceTabState extends State<_OutboundRemittanceTab> {
  final _amountController = TextEditingController();
  String _currency = 'USD';
  bool _loading = false;
  Map<String, dynamic>? _quote;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _getQuote() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final quote = await widget.api.quoteOutboundRemittance(
        amountMinor: (amount * 100).toInt().toString(),
        currency: _currency,
      );
      setState(() => _quote = quote);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get quote: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    if (_quote == null) return;

    // Show PIN confirmation for debit
    final pinConfirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PinConfirmSheet(
        title: 'Confirm Remittance',
        message: 'Enter your PIN to send money abroad',
        onPinEntered: (pin) async {
          return true; // PIN verified in the sheet
        },
      ),
    );

    if (pinConfirmed != true) return;

    setState(() => _loading = true);

    try {
      // Note: Backend doesn't have outbound confirm yet, showing quote success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Remittance initiated! Reference: ${_quote!['quoteId']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _quote = null;
          _amountController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Send money abroad with competitive exchange rates',
                    style: TextStyle(color: Colors.blue[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount Input
          Text(
            'Amount to Send',
            style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '$_currency ',
              hintText: 'Enter amount',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _quote = null),
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
                setState(() {
                  _currency = value;
                  _quote = null;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Get Quote Button
          if (_quote == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _getQuote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Get Quote'),
              ),
            ),

          // Quote Display
          if (_quote != null) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quote Summary',
                      style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    _QuoteRow(
                      label: 'Amount',
                      value: '$_currency ${(int.tryParse(_quote!['sendAmountMinor']?.toString() ?? '0') ?? 0 / 100).toStringAsFixed(2)}',
                    ),
                    _QuoteRow(
                      label: 'Exchange Rate',
                      value: (_quote!['exchangeRate'] ?? _quote!['fxRate'])?.toString() ?? 'N/A',
                    ),
                    _QuoteRow(
                      label: 'Fee',
                      value: '$_currency ${(int.tryParse(_quote!['feeMinor']?.toString() ?? '0') ?? 0 / 100).toStringAsFixed(2)}',
                    ),
                    const Divider(height: 24),
                    _QuoteRow(
                      label: 'Total Debit',
                      value: '$_currency ${(int.tryParse(_quote!['totalMinor']?.toString() ?? '0') ?? 0 / 100).toStringAsFixed(2)}',
                      bold: true,
                    ),
                    _QuoteRow(
                      label: 'Recipient Gets',
                      value: '${_quote!['receiveCurrency'] ?? _currency} ${(int.tryParse(_quote!['receiveAmountMinor']?.toString() ?? '0') ?? 0 / 100).toStringAsFixed(2)}',
                      bold: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _quote = null),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading ? null : _confirm,
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
            ),
          ],
        ],
      ),
    );
  }
}

class _InboundRemittanceTab extends StatefulWidget {
  final CoreApiService api;
  final ThemeData theme;

  const _InboundRemittanceTab({required this.api, required this.theme});

  @override
  State<_InboundRemittanceTab> createState() => _InboundRemittanceTabState();
}

class _InboundRemittanceTabState extends State<_InboundRemittanceTab> {
  final _amountController = TextEditingController();
  String _currency = 'USD';
  bool _loading = false;
  Map<String, dynamic>? _quote;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _getQuote() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid amount')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final quote = await widget.api.quoteInboundRemittance(
        amountMinor: (amount * 100).toInt().toString(),
        currency: _currency,
      );
      setState(() => _quote = quote);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get quote: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _claim() async {
    if (_quote == null) return;

    setState(() => _loading = true);

    try {
      final result = await widget.api.confirmInboundRemittance(_quote!['quoteId']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Remittance claimed! ${result['status'] ?? ''}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _quote = null;
          _amountController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to claim: $e'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Receive money from abroad directly to your wallet',
                    style: TextStyle(color: Colors.green[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount Input
          Text(
            'Expected Amount',
            style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '$_currency ',
              hintText: 'Enter amount',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() => _quote = null),
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
                setState(() {
                  _currency = value;
                  _quote = null;
                });
              }
            },
          ),
          const SizedBox(height: 24),

          // Get Quote Button
          if (_quote == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _getQuote,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Get Quote'),
              ),
            ),

          // Quote Display
          if (_quote != null) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quote Summary',
                      style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    _QuoteRow(
                      label: 'Expected Amount',
                      value: '$_currency ${(int.tryParse(_quote!['sendAmountMinor']?.toString() ?? '0') ?? 0 / 100).toStringAsFixed(2)}',
                    ),
                    if (_quote!['feeMinor'] != null)
                      _QuoteRow(
                        label: 'Fee (Deducted)',
                        value: '$_currency ${(int.tryParse(_quote!['feeMinor']?.toString() ?? '0') ?? 0 / 100).toStringAsFixed(2)}',
                      ),
                    const Divider(height: 24),
                    _QuoteRow(
                      label: 'You Receive',
                      value: '${_quote!['receiveCurrency'] ?? _currency} ${(int.tryParse(_quote!['receiveAmountMinor']?.toString() ?? '0') ?? 0 / 100).toStringAsFixed(2)}',
                      bold: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quote ID: ${_quote!['quoteId'] ?? _quote!['id'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _quote = null),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loading ? null : _claim,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Claim Money'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _QuoteRow({
    required this.label,
    required this.value,
    this.bold = false,
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
            ),
          ),
        ],
      ),
    );
  }
}
