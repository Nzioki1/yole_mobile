import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PesapalPaymentService {
  static const String _baseUrl =
      'https://cybqa.pesapal.com/PesapalIframe/PesapalIframe3/TestPayments';

  /// Test card details for different scenarios
  static const Map<String, Map<String, String>> testCards = {
    'visa_success': {
      'number': '4761739010100010',
      'expiry': '07/28',
      'cvv': '123',
      'type': 'Visa Card',
      'description': 'Visa Test Card - Success',
    },
    'mastercard_success': {
      'number': '5200000000000114',
      'expiry': '07/28',
      'cvv': '123',
      'type': 'MasterCard',
      'description': 'MasterCard Test Card - Success',
    },
    'amex_success': {
      'number': '340000000003961',
      'expiry': '07/28',
      'cvv': '1234',
      'type': 'Amex Card',
      'description': 'AMEX Test Card - Success',
    },
    'visa_3dsecure': {
      'number': '4000000000001091',
      'expiry': '07/28',
      'cvv': '123',
      'type': 'Visa Card',
      'description': 'Visa Test Card - 3D Secure',
    },
    'mastercard_3dsecure': {
      'number': '5200000000000007',
      'expiry': '07/28',
      'cvv': '123',
      'type': 'MasterCard',
      'description': 'MasterCard Test Card - 3D Secure',
    },
    'visa_failure': {
      'number': '4000000000001018',
      'expiry': '07/28',
      'cvv': '123',
      'type': 'Visa Card',
      'description': 'Visa Test Card - Failure',
    },
  };

  /// Initialize payment with Pesapal
  static Future<Map<String, dynamic>> initializePayment({
    required String amount,
    required String currency,
    required String phoneNumber,
    required String reference,
    required String description,
  }) async {
    try {
      // For test purposes, we'll simulate the payment initialization
      // In a real implementation, this would make an API call to Pesapal

      final paymentData = {
        'amount': amount,
        'currency': currency,
        'phone_number': phoneNumber,
        'reference': reference,
        'description': description,
        'payment_url': _baseUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      return {
        'success': true,
        'data': paymentData,
        'message': 'Payment initialized successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to initialize payment',
      };
    }
  }

  /// Process payment with selected test card
  static Future<Map<String, dynamic>> processPayment({
    required String amount,
    required String currency,
    required String phoneNumber,
    required String reference,
    required String cardType,
  }) async {
    try {
      final card = testCards[cardType];
      if (card == null) {
        throw Exception('Invalid card type selected');
      }

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Determine payment result based on card type
      bool isSuccess = !cardType.contains('failure');
      bool requires3DSecure = cardType.contains('3dsecure');

      final result = {
        'success': isSuccess,
        'card_type': card['type'],
        'card_number': card['number'],
        'amount': amount,
        'currency': currency,
        'phone_number': phoneNumber,
        'reference': reference,
        'transaction_id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'status': isSuccess ? 'completed' : 'failed',
        'requires_3d_secure': requires3DSecure,
        'processed_at': DateTime.now().toIso8601String(),
      };

      if (isSuccess) {
        result['message'] = 'Payment processed successfully';
      } else {
        result['message'] = 'Payment failed - insufficient funds';
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Payment processing failed',
      };
    }
  }

  /// Show payment method selection dialog
  static Future<String?> showPaymentMethodDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPaymentOption(
                context,
                'Card Payment',
                Icons.credit_card,
                'Pay with credit/debit card',
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                context,
                'Mobile Money',
                Icons.phone_android,
                'Pay with mobile money',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Show test card selection dialog
  static Future<String?> showTestCardDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Test Card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: testCards.entries.map((entry) {
                final card = entry.value;
                return ListTile(
                  leading: Icon(
                    _getCardIcon(card['type']!),
                    color: _getCardColor(card['type']!),
                  ),
                  title: Text(card['description']!),
                  subtitle: Text('${card['number']} • ${card['expiry']}'),
                  onTap: () => Navigator.of(context).pop(entry.key),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  /// Build payment option widget
  static Widget _buildPaymentOption(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
  ) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// Get card icon based on type
  static IconData _getCardIcon(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa card':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex card':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }

  /// Get card color based on type
  static Color _getCardColor(String cardType) {
    switch (cardType.toLowerCase()) {
      case 'visa card':
        return Colors.blue;
      case 'mastercard':
        return Colors.orange;
      case 'amex card':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
