import 'package:flutter/material.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'transaction_confirmation_screen.dart';

class CardSelectionScreen extends StatefulWidget {
  final String phoneNumber;
  final double transferAmount;
  final double serviceFee;
  final double totalAmount;
  final List<Map<String, dynamic>> availableCards;

  const CardSelectionScreen({
    super.key,
    required this.phoneNumber,
    required this.transferAmount,
    required this.serviceFee,
    required this.totalAmount,
    required this.availableCards,
  });

  @override
  State<CardSelectionScreen> createState() => _CardSelectionScreenState();
}

class _CardSelectionScreenState extends State<CardSelectionScreen> {
  String? _selectedCardId;
  bool _isProcessing = false;
  bool _isCompleted = false;

  void _selectCard(String cardId) {
    setState(() {
      _selectedCardId = cardId;
    });
  }

  Future<void> _processPayment() async {
    if (_selectedCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a card first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isProcessing = false;
      _isCompleted = true;
    });

    // Navigate to transaction confirmation screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TransactionConfirmationScreen(
            phoneNumber: widget.phoneNumber,
            transferAmount: widget.transferAmount,
            serviceFee: widget.serviceFee,
            totalAmount: widget.totalAmount,
            selectedCard: widget.availableCards.firstWhere(
              (card) => card['id'] == _selectedCardId,
            ),
            transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Card'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transfer Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transfer Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recipient:'),
                        Text(widget.phoneNumber),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount:'),
                        Text('\$${widget.transferAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Service Fee:'),
                        Text('\$${widget.serviceFee.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${widget.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Card Selection
            const Text(
              'Select Payment Card',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: widget.availableCards.length,
                itemBuilder: (context, index) {
                  final card = widget.availableCards[index];
                  final isSelected = _selectedCardId == card['id'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isSelected ? Colors.blue[50] : null,
                    child: InkWell(
                      onTap: () => _selectCard(card['id']),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Card Icon
                            Container(
                              width: 50,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _getCardColor(card['type']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  card['type'] == 'Visa' ? 'VISA' : 'MC',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Card Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('**** **** **** ${card['last4']}'),
                                  Text(
                                    'Balance: \$${card['balance'].toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selection Indicator
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
              ),
            ),

            const SizedBox(height: 24),

            // Process Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCardId != null && !_isProcessing
                    ? _processPayment
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(width: 12),
                          Text('Processing Payment...'),
                        ],
                      )
                    : const Text(
                        '💳 Complete Payment',
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
    );
  }

  Color _getCardColor(String cardType) {
    switch (cardType) {
      case 'Visa':
        return Colors.blue[800]!;
      case 'Mastercard':
        return Colors.orange[800]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
