import 'package:flutter/material.dart';
import '../services/core_api_service.dart';

class CardIssueScreen extends StatefulWidget {
  const CardIssueScreen({super.key});

  @override
  State<CardIssueScreen> createState() => _CardIssueScreenState();
}

class _CardIssueScreenState extends State<CardIssueScreen> {
  final _api = CoreApiService();
  bool _loading = true;
  bool _issuing = false;
  List<dynamic> _wallets = [];
  String? _selectedPocketId;
  String? _selectedCurrency;
  final _dailyLimitController = TextEditingController(text: '500');
  final _monthlyLimitController = TextEditingController(text: '5000');

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadWallets();
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _monthlyLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getWallets();
      final wallets = data['wallets'] as List<dynamic>? ?? [];
      setState(() => _wallets = wallets);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wallets: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _issueCard() async {
    if (_selectedPocketId == null || _selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet pocket')),
      );
      return;
    }

    final dailyLimit = double.tryParse(_dailyLimitController.text);
    final monthlyLimit = double.tryParse(_monthlyLimitController.text);

    if (dailyLimit == null || dailyLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid daily limit')),
      );
      return;
    }

    if (monthlyLimit == null || monthlyLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly limit')),
      );
      return;
    }

    setState(() => _issuing = true);

    try {
      final result = await _api.issueCard(
        walletPocketId: _selectedPocketId!,
        currency: _selectedCurrency!,
        dailyLimitMinor: (dailyLimit * 100).toInt().toString(),
        monthlyLimitMinor: (monthlyLimit * 100).toInt().toString(),
      );

      if (mounted) {
        Navigator.of(context).pop(); // Return to cards list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Card issued successfully! ID: ${result['cardId']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to issue card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _issuing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Virtual Card'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            'Virtual cards are linked to your wallet and deduct from your available balance',
                            style: TextStyle(color: Colors.blue[900], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wallet Selection
                  Text(
                    'Select Wallet',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_wallets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No wallets found', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ..._buildPocketSelectors(),

                  const SizedBox(height: 24),

                  // Daily Limit
                  Text(
                    'Daily Limit',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dailyLimitController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: _selectedCurrency != null ? '$_selectedCurrency ' : '',
                      hintText: 'Enter daily spending limit',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Monthly Limit
                  Text(
                    'Monthly Limit',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _monthlyLimitController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: _selectedCurrency != null ? '$_selectedCurrency ' : '',
                      hintText: 'Enter monthly spending limit',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Issue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _issuing ? null : _issueCard,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _issuing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Issue Card'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildPocketSelectors() {
    final List<Widget> widgets = [];
    for (final wallet in _wallets) {
      final pockets = wallet['pockets'] as List<dynamic>? ?? [];
      for (final pocket in pockets) {
        final pocketId = pocket['id'];
        final currency = pocket['currency'];
        final available = (int.parse(pocket['availableMinor'].toString()) / 100);
        final isSelected = _selectedPocketId == pocketId;

        widgets.add(
          Card(
            elevation: isSelected ? 4 : 1,
            color: isSelected ? Colors.blue[50] : null,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedPocketId = pocketId;
                  _selectedCurrency = currency;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Radio<String>(
                      value: pocketId,
                      groupValue: _selectedPocketId,
                      onChanged: (value) {
                        setState(() {
                          _selectedPocketId = value;
                          _selectedCurrency = currency;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currency,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Available: ${available.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 8));
      }
    }
    return widgets;
  }
}
