import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'transfer_providers.dart';
import '../../auth/data/auth_token_store.dart';
import 'card_selection_screen.dart';

class TransferStep1Screen extends ConsumerStatefulWidget {
  const TransferStep1Screen({super.key});

  @override
  ConsumerState<TransferStep1Screen> createState() =>
      _TransferStep1ScreenState();
}

class _TransferStep1ScreenState extends ConsumerState<TransferStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  double _transferAmount = 0.0;
  double _serviceFee = 0.0;
  double _totalAmount = 0.0;

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _calculateCharges() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _transferAmount = amount;
      // Calculate service fee: 2% of transfer amount, minimum $1
      _serviceFee = (amount * 0.02).clamp(1.0, 10.0);
      _totalAmount = _transferAmount + _serviceFee;
    });
  }

  Future<void> _pickContact() async {
    try {
      final hasPermission = await FlutterContacts.requestPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied to access contacts'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        final phones = await contact.phones;
        if (phones.isNotEmpty) {
          setState(() {
            _phoneController.text = phones.first.number;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking contact: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _proceedToSendMoney() async {
    if (!_formKey.currentState!.validate()) return;

    // Check authentication
    final token = await AuthTokenStore.getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be logged in to send money. Please log in again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create transfer draft
      final transferNotifier = ref.read(transferProvider.notifier);
      transferNotifier.createDraft(
        _phoneController.text, // recipientId
        _transferAmount, // amount
        currency: 'USD',
        recipientCountry: 'KE',
        phoneNumber: _phoneController.text,
      );

      // Create real money transfer
      await transferNotifier.createPesapalTestPayment();

      final currentState = ref.read(transferProvider);
      if (currentState.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${currentState.error!.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (currentState.redirect != null) {
        if (currentState.redirect!.redirectUrl == 'card_selection') {
          // Navigate to card selection screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CardSelectionScreen(
                phoneNumber: _phoneController.text,
                transferAmount: _transferAmount,
                serviceFee: _serviceFee,
                totalAmount: _totalAmount,
                availableCards: [
                  {
                    'id': 'card_1',
                    'type': 'Visa',
                    'last4': '1234',
                    'balance': 5000.0,
                    'currency': 'USD',
                    'name': 'Primary Card',
                  },
                  {
                    'id': 'card_2',
                    'type': 'Mastercard',
                    'last4': '5678',
                    'balance': 2500.0,
                    'currency': 'USD',
                    'name': 'Secondary Card',
                  },
                  {
                    'id': 'card_3',
                    'type': 'Visa',
                    'last4': '9012',
                    'balance': 10000.0,
                    'currency': 'USD',
                    'name': 'Business Card',
                  },
                ],
              ),
            ),
          );
        } else {
          // Show success message for other cases
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Money transfer initiated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear success message after 3 seconds and return to dashboard
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(context).pop(); // Go back to dashboard
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An unexpected error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 2, color: Colors.grey[300]),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(height: 2, color: Colors.grey[300]),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '3',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Recipient Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                        hintText: 'Enter recipient phone number',
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _pickContact,
                    icon: const Icon(Icons.contacts),
                    label: const Text('Pick'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Enter amount to send',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (value) => _calculateCharges(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > 1000) {
                    return 'Maximum transfer amount is \$1,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_transferAmount > 0) ...[
                const Text(
                  'Transfer Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Transfer Amount:'),
                          Text(
                            '\$${_transferAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Service Fee:'),
                          Text(
                            '\$${_serviceFee.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${_totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _transferAmount > 0 ? _proceedToSendMoney : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    '💸 Send Money',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
