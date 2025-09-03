import 'package:flutter/material.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class TransactionConfirmationScreen extends StatefulWidget {
  final String phoneNumber;
  final double transferAmount;
  final double serviceFee;
  final double totalAmount;
  final Map<String, dynamic> selectedCard;
  final String transactionId;

  const TransactionConfirmationScreen({
    super.key,
    required this.phoneNumber,
    required this.transferAmount,
    required this.serviceFee,
    required this.totalAmount,
    required this.selectedCard,
    required this.transactionId,
  });

  @override
  State<TransactionConfirmationScreen> createState() =>
      _TransactionConfirmationScreenState();
}

class _TransactionConfirmationScreenState
    extends State<TransactionConfirmationScreen> {
  bool _isReturning = false;

  @override
  void initState() {
    super.initState();
    // Auto-return to dashboard after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isReturning) {
        _returnToDashboard();
      }
    });
  }

  void _returnToDashboard() {
    setState(() {
      _isReturning = true;
    });

    print('🔍 TransactionConfirmation: Attempting to return to dashboard');

    try {
      // Try to pop all routes and return to the root
      if (Navigator.of(context).canPop()) {
        print('🔍 TransactionConfirmation: Can pop, popping all routes');
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        print('🔍 TransactionConfirmation: Cannot pop, using pushReplacement');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
      print('🔍 TransactionConfirmation: Navigation completed');
    } catch (e) {
      print('🔍 TransactionConfirmation: Navigation error: $e');
      // Fallback: try to pop to root
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Confirmed'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Success Icon and Message
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Success Message
                      const Text(
                        'Payment Successful!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your money transfer has been completed',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Transaction Details Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Transaction Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Transaction ID
                              _buildDetailRow(
                                'Transaction ID',
                                widget.transactionId,
                              ),
                              const SizedBox(height: 8),

                              // Recipient
                              _buildDetailRow('Recipient', widget.phoneNumber),
                              const SizedBox(height: 8),

                              // Amount
                              _buildDetailRow(
                                'Amount',
                                '\$${widget.transferAmount.toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 8),

                              // Service Fee
                              _buildDetailRow(
                                'Service Fee',
                                '\$${widget.serviceFee.toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 8),

                              // Total
                              _buildDetailRow(
                                'Total',
                                '\$${widget.totalAmount.toStringAsFixed(2)}',
                                isTotal: true,
                              ),
                              const SizedBox(height: 16),

                              // Payment Method
                              _buildDetailRow(
                                'Payment Method',
                                '${widget.selectedCard['type']} ****${widget.selectedCard['last4']}',
                              ),
                              const SizedBox(height: 8),

                              // Date and Time
                              _buildDetailRow(
                                'Date & Time',
                                DateTime.now().toString().substring(0, 19),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Return to Dashboard Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isReturning ? null : _returnToDashboard,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isReturning
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(width: 12),
                            Text('Returning to Dashboard...'),
                          ],
                        )
                      : const Text(
                          '🏠 Return to Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}
