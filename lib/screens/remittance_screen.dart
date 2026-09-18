import 'package:flutter/material.dart';
import '../services/core_api_service.dart';
import '../services/offline_demo_repository.dart';
import '../widgets/pin_confirm_sheet.dart';
import '../router_types.dart';

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
  String? _selectedRecipient;

  // Demo recipients for offline mode - international mix
  static const List<Map<String, String>> _demoRecipients = [
    {'id': 'rcpt_001', 'name': 'Marie Tshala', 'country': 'DRC', 'currency': 'CDF'},
    {'id': 'rcpt_002', 'name': 'Papa Wemba', 'country': 'DRC', 'currency': 'CDF'},
    {'id': 'rcpt_003', 'name': 'James Kamau', 'country': 'Kenya', 'currency': 'KES'},
    {'id': 'rcpt_004', 'name': 'Sarah Nakato', 'country': 'Uganda', 'currency': 'UGX'},
    {'id': 'rcpt_005', 'name': 'Pierre Dubois', 'country': 'France', 'currency': 'EUR'},
    {'id': 'rcpt_006', 'name': 'John Smith', 'country': 'USA', 'currency': 'USD'},
    {'id': 'rcpt_007', 'name': 'Luc Bertrand', 'country': 'Belgium', 'currency': 'EUR'},
    {'id': 'rcpt_008', 'name': 'Thabo Mbeki', 'country': 'South Africa', 'currency': 'ZAR'},
  ];

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

    // Validate recipient selected
    if (_selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recipient'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show PIN confirmation - use correct pattern
    final pin = await PinConfirmSheet.show(
      context,
      title: 'Confirm Remittance',
      message: 'Enter your PIN to send money abroad',
    );

    if (pin == null || !mounted) return;

    // Verify PIN (offline demo accepts 123456)
    if (CoreApiService.offlineDemo) {
      if (pin != OfflineDemoRepository.demoPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid PIN. Demo PIN is ${OfflineDemoRepository.demoPin}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      // Live mode would verify PIN via API
      final pinValid = await widget.api.verifyPin(pin: pin);
      if (!pinValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid PIN'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() => _loading = true);

    try {
      // Note: Backend doesn't have outbound confirm yet
      final quoteId = _quote!['quoteId'] ?? _quote!['id'] ?? 'N/A';
      final sendAmountMinor = int.tryParse(_quote!['sendAmountMinor']?.toString() ?? '0') ?? 0;
      final sendAmount = (sendAmountMinor / 100).toStringAsFixed(2);
      
      // Get recipient details
      final recipient = _demoRecipients.firstWhere(
        (r) => r['id'] == _selectedRecipient,
        orElse: () => {'name': 'Unknown', 'country': 'Unknown', 'currency': _currency},
      );

      if (mounted) {
        setState(() => _loading = false);
        
        // Show confirmation dialog
        await _showConfirmationDialog(
          context,
          sendAmount: sendAmount,
          currency: _currency,
          recipientName: recipient['name']!,
          recipientCountry: recipient['country']!,
          referenceId: quoteId,
        );


      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteNames.home,
          (route) => false,
        );
      }
        
        // Reset form
        setState(() {
          _quote = null;
          _selectedRecipient = null;
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

  Future<void> _showConfirmationDialog(
    BuildContext context, {
    required String sendAmount,
    required String currency,
    required String recipientName,
    required String recipientCountry,
    required String referenceId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Money Sent!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your international remittance has been successfully sent.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            _ConfirmationRow(label: 'Amount Sent', value: '$currency $sendAmount'),
            const SizedBox(height: 12),
            _ConfirmationRow(label: 'Recipient', value: recipientName),
            const SizedBox(height: 12),
            _ConfirmationRow(label: 'Destination', value: recipientCountry),
            const SizedBox(height: 12),
            _ConfirmationRow(label: 'Reference ID', value: referenceId),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Recipient will receive the money within 24 hours',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
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

          // Recipient Selector
          Text(
            'Send To',
            style: widget.theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedRecipient,
            decoration: const InputDecoration(
              hintText: 'Select recipient',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('-- Select Recipient --'),
              ),
              ..._demoRecipients.map((recipient) {
                return DropdownMenuItem<String>(
                  value: recipient['id'],
                  child: Text('${recipient['name']} (${recipient['country']})'),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedRecipient = value;
                _quote = null; // Reset quote when recipient changes
              });
            },
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

class _ConfirmationRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmationRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
