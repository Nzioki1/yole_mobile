import 'package:flutter/material.dart';
import '../services/offline_agent_repository.dart';

/// Reusable customer lookup widget.
///
/// Accepts phone (E.164) or customer ID, displays customer info on success.
class CustomerLookupField extends StatefulWidget {
  const CustomerLookupField({
    super.key,
    required this.onCustomerSelected,
  });

  final void Function(Map<String, dynamic>? customer) onCustomerSelected;

  @override
  State<CustomerLookupField> createState() => _CustomerLookupFieldState();
}

class _CustomerLookupFieldState extends State<CustomerLookupField> {
  final _controller = TextEditingController();
  final _repo = OfflineAgentRepository.instance;
  Map<String, dynamic>? _customer;
  String? _error;
  bool _loading = false;

  Future<void> _lookup() async {
    setState(() {
      _loading = true;
      _error = null;
      _customer = null;
    });

    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please enter phone or customer ID';
      });
      widget.onCustomerSelected(null);
      return;
    }

    try {
      final customer = _repo.findCustomerByPhoneOrId(query);
      setState(() {
        _customer = customer;
        _loading = false;
      });
      widget.onCustomerSelected(customer);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
      widget.onCustomerSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Customer Phone or ID *',
                  hintText: '+243... or cust_...',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                onChanged: (_) {
                  if (_customer != null || _error != null) {
                    setState(() {
                      _customer = null;
                      _error = null;
                    });
                    widget.onCustomerSelected(null);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _loading ? null : _lookup,
              child: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Lookup'),
            ),
          ],
        ),
        if (_customer != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_customer!['firstName']} ${_customer!['lastName']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'KYC: ${_customer!['kycStatus']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _customer!['kycStatus'] == 'APPROVED'
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _customer!['kycStatus'] == 'APPROVED'
                                    ? '✓ Verified'
                                    : '⊗ Pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/enroll');
                    },
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Enroll Customer'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
