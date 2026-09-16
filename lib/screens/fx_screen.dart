import 'package:flutter/material.dart';
import '../services/core_api_service.dart';

class FxScreen extends StatefulWidget {
  const FxScreen({super.key});

  @override
  State<FxScreen> createState() => _FxScreenState();
}

class _FxScreenState extends State<FxScreen> {
  final _api = CoreApiService();
  bool _loading = false;
  List<dynamic> _rates = [];
  final _amountController = TextEditingController(text: '1000');
  String _fromCurrency = 'USD';
  String _toCurrency = 'CDF';

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() => _loading = true);
    try {
      final rates = await _api.getFxRates();
      setState(() => _rates = rates);
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

  Future<void> _convert() async {
    setState(() => _loading = true);
    try {
      final result = await _api.convertCurrency(
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        fromAmountMinor: _amountController.text,
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Conversion Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From: ${result['fromAmountMinor']} $_fromCurrency'),
                Text('To: ${result['toAmountMinor']} $_toCurrency'),
                Text('Rate: ${result['rate']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Currency Exchange')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('FX Rates', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._rates.map((rate) => Card(
                      child: ListTile(
                        title: Text('${rate['fromCurrency']} → ${rate['toCurrency']}'),
                        trailing: Text('${rate['rate']}'),
                      ),
                    )),
                const SizedBox(height: 24),
                const Text('Convert', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _fromCurrency,
                  decoration: const InputDecoration(labelText: 'From Currency'),
                  items: ['USD', 'CDF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _fromCurrency = v!),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _toCurrency,
                  decoration: const InputDecoration(labelText: 'To Currency'),
                  items: ['USD', 'CDF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _toCurrency = v!),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount (minor units)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _convert,
                  child: const Text('Convert'),
                ),
              ],
            ),
    );
  }
}
