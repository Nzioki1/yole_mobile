import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/models.dart';
import '../data/transfer_repository.dart';
import 'pesapal_payment_screen.dart';
import 'dart:async';

class PesapalPaymentMethodScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> transferDetails;

  const PesapalPaymentMethodScreen({super.key, required this.transferDetails});

  @override
  ConsumerState<PesapalPaymentMethodScreen> createState() =>
      _PesapalPaymentMethodScreenState();
}

class _PesapalPaymentMethodScreenState
    extends ConsumerState<PesapalPaymentMethodScreen> {
  List<PesapalPaymentMethod> _paymentMethods = [];
  PesapalPaymentMethod? _selectedMethod;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(transferRepositoryProvider);
      final methods = await repository.getPesapalPaymentMethods();

      setState(() {
        _paymentMethods = methods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load payment methods: $e';
        _isLoading = false;
        // Fallback to default methods
        _paymentMethods = _getDefaultPaymentMethods();
      });
    }
  }

  List<PesapalPaymentMethod> _getDefaultPaymentMethods() {
    return [
      const PesapalPaymentMethod(
        id: 'mpesa',
        name: 'M-Pesa',
        description: 'Pay using M-Pesa mobile money',
        icon: 'https://pesapal.com/icons/mpesa.png',
        isActive: true,
      ),
      const PesapalPaymentMethod(
        id: 'airtel',
        name: 'Airtel Money',
        description: 'Pay using Airtel Money',
        icon: 'https://pesapal.com/icons/airtel.png',
        isActive: true,
      ),
      const PesapalPaymentMethod(
        id: 'card',
        name: 'Credit/Debit Card',
        description: 'Pay using Visa, Mastercard, or other cards',
        icon: 'https://pesapal.com/icons/card.png',
        isActive: true,
      ),
      const PesapalPaymentMethod(
        id: 'bank',
        name: 'Bank Transfer',
        description: 'Pay using bank transfer',
        icon: 'https://pesapal.com/icons/bank.png',
        isActive: true,
      ),
    ];
  }

  void _selectPaymentMethod(PesapalPaymentMethod method) {
    setState(() {
      _selectedMethod = method;
    });
  }

  void _proceedToPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Add selected payment method to transfer details
      final paymentDetails = {
        ...widget.transferDetails,
        'payment_method': _selectedMethod!.id,
        'payment_method_name': _selectedMethod!.name,
      };

      // Create Pesapal order directly here
      final repository = ref.read(transferRepositoryProvider);
      
      final orderRequest = PesapalOrderRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        currency: 'USD',
        amount: widget.transferDetails['total_amount'],
        description: 'Money transfer to ${widget.transferDetails['recipient_name']} via ${_selectedMethod!.name}',
        callbackUrl: 'https://yole.com/callback',
        notificationId: 'https://yole.com/ipn',
        billingAddress: 'Nairobi, Kenya',
        phoneNumber: widget.transferDetails['recipient_phone'],
        email: 'user@yole.com', // This should come from user profile
        firstName: widget.transferDetails['recipient_name'].split(' ').first,
        lastName: widget.transferDetails['recipient_name'].split(' ').length > 1
            ? widget.transferDetails['recipient_name'].split(' ').last
            : '',
        line1: 'Nairobi',
        line2: 'Kenya',
        city: 'Nairobi',
        state: 'Nairobi',
        countryCode: 'KE',
        zipCode: '00100',
      );

      // Create Pesapal order
      final redirect = await repository.createPesapalOrder(orderRequest);
      
      // Add redirect URL to payment details
      final finalPaymentDetails = {
        ...paymentDetails,
        'redirect_url': redirect.redirectUrl,
        'order_tracking_id': redirect.orderTrackingId,
      };

      // Navigate to Pesapal payment screen
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) =>
                  PesapalPaymentScreen(paymentDetails: finalPaymentDetails),
            ),
          )
          .then((_) {
            setState(() {
              _isProcessing = false;
            });
          });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create payment order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Payment Method'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.error.withOpacity(.1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Transfer summary
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${widget.transferDetails['total_amount']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recipient:'),
                      Text(
                        widget.transferDetails['recipient_name'] ?? 'Unknown',
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
                        '\$${widget.transferDetails['service_fee']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment methods list
            Expanded(child: _buildPaymentMethodsList()),

            // Bottom section
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    if (_paymentMethods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No payment methods available',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPaymentMethods,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _paymentMethods.length,
      itemBuilder: (context, index) {
        final method = _paymentMethods[index];
        final isSelected = _selectedMethod?.id == method.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isSelected ? Colors.blue[50] : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => _selectPaymentMethod(method),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Payment method icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _buildPaymentMethodIcon(method),
                  ),
                  const SizedBox(width: 16),

                  // Payment method details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodIcon(PesapalPaymentMethod method) {
    // Return appropriate icon based on payment method
    IconData iconData;
    Color iconColor;

    switch (method.id.toLowerCase()) {
      case 'mpesa':
        iconData = Icons.phone_android;
        iconColor = Colors.green;
        break;
      case 'airtel':
        iconData = Icons.phone_android;
        iconColor = Colors.red;
        break;
      case 'card':
        iconData = Icons.credit_card;
        iconColor = Colors.blue;
        break;
      case 'bank':
        iconData = Icons.account_balance;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.payment;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor, size: 24);
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedMethod != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedMethod!.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: _isProcessing ? 'Processing...' : 'Continue to Payment',
              onPressed: _selectedMethod != null && !_isProcessing
                  ? _proceedToPayment
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your payment will be processed securely via Pesapal',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
