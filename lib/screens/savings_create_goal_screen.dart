import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/core_api_service.dart';

class SavingsCreateGoalScreen extends StatefulWidget {
  const SavingsCreateGoalScreen({super.key});

  @override
  State<SavingsCreateGoalScreen> createState() =>
      _SavingsCreateGoalScreenState();
}

class _SavingsCreateGoalScreenState extends State<SavingsCreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = CoreApiService();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _autoDepositController = TextEditingController();

  String _selectedCurrency = 'CDF';
  bool _autoDepositEnabled = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _api.init();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _autoDepositController.dispose();
    super.dispose();
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _creating = true);

    try {
      final targetAmount = double.parse(_targetController.text);
      final targetMinor = (targetAmount * 100).toInt();

      String? autoDepositMinor;
      if (_autoDepositEnabled && _autoDepositController.text.isNotEmpty) {
        final autoAmount = double.parse(_autoDepositController.text);
        autoDepositMinor = (autoAmount * 100).toInt().toString();
      }

      await _api.createSavingsGoal(
        name: _nameController.text.trim(),
        targetMinor: targetMinor.toString(),
        currency: _selectedCurrency,
        autoDepositEnabled: _autoDepositEnabled,
        autoDepositMinor: autoDepositMinor,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Savings goal created successfully!'),
            backgroundColor: Color(0xFF00ACAC),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create goal: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Savings Goal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Set Your Savings Goal',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a savings goal to track your progress.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Goal Name',
                hintText: 'e.g. Emergency fund, Vacation, New phone',
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a goal name';
                }
                if (value.trim().length < 2) {
                  return 'Goal name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetController,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a target amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: InputDecoration(
                labelText: 'Currency',
                prefixIcon: const Icon(Icons.currency_exchange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'CDF', child: Text('CDF (Congolese Franc)')),
                DropdownMenuItem(value: 'USD', child: Text('USD (US Dollar)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCurrency = value);
                }
              },
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Auto-Deposit',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: _autoDepositEnabled,
                          activeColor: const Color(0xFF00ACAC),
                          onChanged: (value) {
                            setState(() => _autoDepositEnabled = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automatically deposit a fixed amount regularly.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    if (_autoDepositEnabled) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _autoDepositController,
                        decoration: InputDecoration(
                          labelText: 'Auto-Deposit Amount',
                          hintText: '0.00',
                          prefixIcon: const Icon(Icons.autorenew),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (_autoDepositEnabled) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an auto-deposit amount';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Please enter a valid amount greater than 0';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Note: Auto-deposit is a demo feature and will not execute automatically.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating ? null : _createGoal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ACAC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _creating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Goal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
