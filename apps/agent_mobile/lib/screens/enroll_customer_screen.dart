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
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Customer Enrolled'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer ID: ${result['customerId']}'),
                Text('Wallet ID: ${result['walletId']}'),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _enroll,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enroll Customer'),
            ),
          ],
        ),
      ),
    );
  }
}
