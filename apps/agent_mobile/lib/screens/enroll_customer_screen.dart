import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';

class EnrollCustomerScreen extends StatefulWidget {
  const EnrollCustomerScreen({super.key});

  @override
  State<EnrollCustomerScreen> createState() => _EnrollCustomerScreenState();
}

class _EnrollCustomerScreenState extends State<EnrollCustomerScreen> {
  final _api = AgentApiService();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Password1!');
  final _idNumberController = TextEditingController();
  String? _idType;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _api.init();
  }

  Future<void> _enroll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final result = await _api.enrollCustomer(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        password: _passwordController.text,
        phoneE164: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        idNumber: _idNumberController.text.isNotEmpty ? _idNumberController.text : null,
        idType: _idType,
      );

      if (mounted) {
        final customerId = result['customerId'] as String? ?? 'N/A';
        final wallets = result['wallets'] as List<dynamic>? ?? [];
        final cdfWalletId = wallets.isNotEmpty ? wallets[0] as String? : null;
        final usdWalletId = wallets.length > 1 ? wallets[1] as String? : null;
        final kycStatus = result['kycStatus'] as String? ?? 'PENDING';
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Customer Enrolled'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer ID (for cash-in/W2W):',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: SelectableText(
                    customerId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Name: ${_firstNameController.text} ${_lastNameController.text}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (cdfWalletId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'CDF Wallet: $cdfWalletId (FC 0.00)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (usdWalletId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'USD Wallet: $usdWalletId (\$0.00)',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'KYC Status: $kycStatus',
                  style: TextStyle(
                    fontSize: 12,
                    color: kycStatus == 'PENDING_REVIEW' ? Colors.orange : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enroll failed: $e'),
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
      appBar: AppBar(title: const Text('Enroll Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone (+243...)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password *'),
              obscureText: true,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _idNumberController,
              decoration: const InputDecoration(labelText: 'ID Number (Optional)'),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _idType,
              decoration: const InputDecoration(labelText: 'ID Type (Optional)'),
              items: const [
                DropdownMenuItem(value: 'NATIONAL_ID', child: Text('National ID')),
                DropdownMenuItem(value: 'PASSPORT', child: Text('Passport')),
                DropdownMenuItem(value: 'DRIVERS_LICENSE', child: Text('Driver\'s License')),
              ],
              onChanged: (v) {
                setState(() => _idType = v);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _enroll,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enroll Customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
