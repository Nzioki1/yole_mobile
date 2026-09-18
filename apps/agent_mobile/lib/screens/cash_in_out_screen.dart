import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';
import '../widgets/customer_lookup_field.dart';

class CashInOutScreen extends StatefulWidget {
  const CashInOutScreen({super.key});

  @override
  State<CashInOutScreen> createState() => _CashInOutScreenState();
}

class _CashInOutScreenState extends State<CashInOutScreen> {
  final _api = AgentApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  Map<String, dynamic>? _selectedCustomer;
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
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please look up a customer first'),
          backgroundColor: Colors.red,
        ),
      );
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
        final amount = double.parse(_amountController.text);
        final currencySymbol = _currency == 'CDF' ? 'FC' : '\$';
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _isCashIn ? Icons.arrow_downward : Icons.arrow_upward,
                  color: _isCashIn ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text('${_isCashIn ? "Cash-In" : "Cash-Out"} Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: $currencySymbol${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Customer: ${_selectedCustomer!['firstName']} ${_selectedCustomer!['lastName']}'),
                const Divider(),
                Text(
                  'Journal: ${result['journalId']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Status: ${result['status']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
                setState(() => _isCashIn = newSelection.first);
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
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount *'),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              enabled: _selectedCustomer != null,
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
