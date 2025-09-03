import 'package:flutter/material.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String? _selectedMethod;
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cards',
      'title': 'Credit/Debit Cards',
      'subtitle': 'Visa, Mastercard, American Express',
      'icon': Icons.credit_card,
      'color': Colors.blue,
      'isAvailable': true,
      'methods': [
        {
          'id': 'visa',
          'name': 'Visa',
          'icon': '💳',
          'color': Colors.blue[800]!,
          'isDefault': true,
        },
        {
          'id': 'mastercard',
          'name': 'Mastercard',
          'icon': '💳',
          'color': Colors.orange[800]!,
          'isDefault': false,
        },
        {
          'id': 'amex',
          'name': 'American Express',
          'icon': '💳',
          'color': Colors.green[800]!,
          'isDefault': false,
        },
      ],
    },
    {
      'id': 'mobile_money',
      'title': 'Mobile Money',
      'subtitle': 'M-Pesa, Airtel Money, Orange Money',
      'icon': Icons.phone_android,
      'color': Colors.green,
      'isAvailable': true,
      'methods': [
        {
          'id': 'mpesa',
          'name': 'M-Pesa',
          'icon': '📱',
          'color': Colors.green[600]!,
          'isDefault': true,
        },
        {
          'id': 'airtel',
          'name': 'Airtel Money',
          'icon': '📱',
          'color': Colors.red[600]!,
          'isDefault': false,
        },
        {
          'id': 'orange',
          'name': 'Orange Money',
          'icon': '📱',
          'color': Colors.orange[600]!,
          'isDefault': false,
        },
      ],
    },
    {
      'id': 'bank_transfer',
      'title': 'Bank Transfer',
      'subtitle': 'Direct bank transfers',
      'icon': Icons.account_balance,
      'color': Colors.purple,
      'isAvailable': true,
      'methods': [
        {
          'id': 'equity',
          'name': 'Equity Bank',
          'icon': '🏦',
          'color': Colors.blue[700]!,
          'isDefault': true,
        },
        {
          'id': 'kcb',
          'name': 'KCB Bank',
          'icon': '🏦',
          'color': Colors.red[700]!,
          'isDefault': false,
        },
        {
          'id': 'coop',
          'name': 'Co-operative Bank',
          'icon': '🏦',
          'color': Colors.green[700]!,
          'isDefault': false,
        },
      ],
    },
    {
      'id': 'crypto',
      'title': 'Cryptocurrency',
      'subtitle': 'Bitcoin, Ethereum, USDT',
      'icon': Icons.currency_bitcoin,
      'color': Colors.orange,
      'isAvailable': false,
      'methods': [
        {
          'id': 'bitcoin',
          'name': 'Bitcoin',
          'icon': '₿',
          'color': Colors.orange[600]!,
          'isDefault': true,
        },
        {
          'id': 'ethereum',
          'name': 'Ethereum',
          'icon': 'Ξ',
          'color': Colors.purple[600]!,
          'isDefault': false,
        },
        {
          'id': 'usdt',
          'name': 'USDT',
          'icon': '💎',
          'color': Colors.green[600]!,
          'isDefault': false,
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPaymentMethod(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Your Payment Method',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select from various secure payment options',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Payment Methods List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                return _buildPaymentMethodCard(method);
              },
            ),
          ),

          // Continue Button
          if (_selectedMethod != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMethod != null
                      ? _continueWithMethod
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Continue with Selected Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];
    final isAvailable = method['isAvailable'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 2,
      color: isSelected ? method['color'].withOpacity(0.1) : null,
      child: InkWell(
        onTap: isAvailable ? () => _selectPaymentMethod(method['id']) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: method['color'], width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: method['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      method['icon'],
                      color: method['color'],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['title'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method['subtitle'],
                          style: TextStyle(
                            fontSize: 14,
                            color: isAvailable ? Colors.grey[600] : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selection Indicator
                  if (isSelected)
                    Icon(Icons.check_circle, color: method['color'], size: 24),

                  // Availability Badge
                  if (!isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Coming Soon',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),

              // Payment Method Options
              if (isAvailable && isSelected) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Available Options:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (method['methods'] as List).map((option) {
                    return _buildPaymentOptionChip(option);
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOptionChip(Map<String, dynamic> option) {
    final isDefault = option['isDefault'] as bool;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDefault ? option['color'].withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDefault ? option['color'] : Colors.grey[300]!,
          width: isDefault ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(option['icon'], style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            option['name'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
              color: isDefault ? option['color'] : Colors.grey[700],
            ),
          ),
          if (isDefault) ...[
            const SizedBox(width: 6),
            Icon(Icons.star, size: 14, color: option['color']),
          ],
        ],
      ),
    );
  }

  void _selectPaymentMethod(String methodId) {
    setState(() {
      _selectedMethod = methodId;
    });
  }

  void _continueWithMethod() {
    if (_selectedMethod != null) {
      // Navigate to the appropriate payment flow
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected: ${_selectedMethod!.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );

      // Here you would navigate to the specific payment flow
      // For now, just go back
      Navigator.of(context).pop();
    }
  }

  void _showAddPaymentMethod() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Payment Method',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildAddMethodOption(
                      'Add Credit/Debit Card',
                      Icons.credit_card,
                      Colors.blue,
                    ),
                    _buildAddMethodOption(
                      'Add Bank Account',
                      Icons.account_balance,
                      Colors.purple,
                    ),
                    _buildAddMethodOption(
                      'Link Mobile Money',
                      Icons.phone_android,
                      Colors.green,
                    ),
                    _buildAddMethodOption(
                      'Add Crypto Wallet',
                      Icons.currency_bitcoin,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMethodOption(String title, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Add $title feature coming soon!'),
              backgroundColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }
}
