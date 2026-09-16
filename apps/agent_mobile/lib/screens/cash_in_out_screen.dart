import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';

class CashInOutScreen extends StatefulWidget {
  const CashInOutScreen({super.key});

  @override
  State<CashInOutScreen> createState() => _CashInOutScreenState();
}

class _CashInOutScreenState extends State<CashInOutScreen> {
  final _api = AgentApiService();
  final _formKey = GlobalKey<FormState>();
  final _customerIdController = TextEditingController();
  final _amountController = TextEditingController();
  String _currency = 'USD';
  bool _isCashIn = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _api.init();
  }

  Future<void> _execute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final amountMinor = (double.parse(_amountController.text) * 100).toInt().toString();
      
      final result = _isCashIn
          ? await _api.cashIn(
              customerId: _customerIdController.text,
              amountMinor: amountMinor,
              currency: _currency,
            )
          : await _api.cashOut(
              customerId: _customerIdController.text,
              amountMinor: amountMinor,
              currency: _currency,
            );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('✅ ${_isCashIn ? "Cash-In" : "Cash-Out"} Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Journal ID: ${result['journalId']}'),
                Text('Status: ${result['status']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
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
                setState(() => _isCashIn = newSelection.first);
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _customerIdController,
              decoration: const InputDecoration(labelText: 'Customer ID *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: ['USD', 'CDF'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount *'),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
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
}
