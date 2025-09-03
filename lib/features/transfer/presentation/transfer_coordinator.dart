import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'enhanced_recipient_selection_screen.dart';
import 'enhanced_amount_screen.dart';
import 'pesapal_payment_method_screen.dart';
import 'pesapal_payment_screen.dart';

class TransferCoordinator extends ConsumerStatefulWidget {
  const TransferCoordinator({super.key});

  @override
  ConsumerState<TransferCoordinator> createState() =>
      _TransferCoordinatorState();
}

class _TransferCoordinatorState extends ConsumerState<TransferCoordinator> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  Map<String, dynamic> _transferData = {};

  final List<TransferStep> _steps = [
    TransferStep(
      title: 'Select Recipient',
      subtitle: 'Choose from contacts or enter manually',
      icon: Icons.person,
    ),
    TransferStep(
      title: 'Enter Amount',
      subtitle: 'Specify amount and review fees',
      icon: Icons.attach_money,
    ),
    TransferStep(
      title: 'Payment Method',
      subtitle: 'Select your preferred payment method',
      icon: Icons.payment,
    ),
    TransferStep(
      title: 'Complete Payment',
      subtitle: 'Secure payment via Pesapal',
      icon: Icons.security,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _updateTransferData(Map<String, dynamic> data) {
    setState(() {
      _transferData.addAll(data);
    });
  }

  void _handleRecipientSelected(Map<String, dynamic> recipientData) {
    _updateTransferData(recipientData);
    _nextStep();
  }

  void _handleAmountConfirmed(Map<String, dynamic> amountData) {
    _updateTransferData(amountData);
    _nextStep();
  }

  void _handlePaymentSuccess(Map<String, dynamic> successData) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TransferSuccessScreen(
          transferDetails: {..._transferData, ...successData},
        ),
      ),
    );
  }

  void _handlePaymentFailure(Map<String, dynamic> failureData) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TransferFailureScreen(
          transferDetails: {..._transferData, ...failureData},
        ),
      ),
    );
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
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                EnhancedRecipientSelectionScreen(
                  transferDetails: _transferData,
                ),
                EnhancedAmountScreen(transferDetails: _transferData),
                PesapalPaymentMethodScreen(transferDetails: _transferData),
                PesapalPaymentScreen(paymentDetails: _transferData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Step indicators
          Row(
            children: _steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : isActive
                            ? Colors.blue
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : step.icon,
                        color: isCompleted || isActive
                            ? Colors.white
                            : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive ? Colors.blue : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          // Progress bar
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }
}

class TransferStep {
  final String title;
  final String subtitle;
  final IconData icon;

  const TransferStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

// Success and Failure screens
class TransferSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> transferDetails;

  const TransferSuccessScreen({super.key, required this.transferDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Successful'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transfer Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You have successfully sent \$${transferDetails['total_amount']?.toStringAsFixed(2) ?? '0.00'} to ${transferDetails['recipient_name'] ?? 'Unknown'}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'Back to Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransferFailureScreen extends StatelessWidget {
  final Map<String, dynamic> transferDetails;

  const TransferFailureScreen({super.key, required this.transferDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Failed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transfer Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your transfer to ${transferDetails['recipient_name'] ?? 'Unknown'} could not be completed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${transferDetails['status'] ?? 'Unknown'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/dashboard',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Dashboard'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
