import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/models.dart';
import '../data/transfer_repository.dart';
import '../../../core/network/failure.dart';
import 'dart:async';

class PesapalPaymentScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> paymentDetails;

  const PesapalPaymentScreen({super.key, required this.paymentDetails});

  @override
  ConsumerState<PesapalPaymentScreen> createState() =>
      _PesapalPaymentScreenState();
}

class _PesapalPaymentScreenState extends ConsumerState<PesapalPaymentScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _redirectUrl;
  String? _orderTrackingId;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if we already have redirect URL and order tracking ID
      if (widget.paymentDetails['redirect_url'] != null && 
          widget.paymentDetails['order_tracking_id'] != null) {
        setState(() {
          _redirectUrl = widget.paymentDetails['redirect_url'];
          _orderTrackingId = widget.paymentDetails['order_tracking_id'];
          _isLoading = false;
        });
      } else {
        // Fallback: Create Pesapal order if not already created
        final repository = ref.read(transferRepositoryProvider);
        
        final orderRequest = PesapalOrderRequest(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          currency: 'USD',
          amount: widget.paymentDetails['total_amount'],
          description:
              'Money transfer to ${widget.paymentDetails['recipient_name']}',
          callbackUrl: 'https://yole.com/callback',
          notificationId: 'https://yole.com/ipn',
          billingAddress: 'Nairobi, Kenya',
          phoneNumber: widget.paymentDetails['recipient_phone'],
          email: 'user@yole.com', // This should come from user profile
          firstName: widget.paymentDetails['recipient_name'].split(' ').first,
          lastName: widget.paymentDetails['recipient_name'].split(' ').length > 1
              ? widget.paymentDetails['recipient_name'].split(' ').last
              : '',
          line1: 'Nairobi',
          line2: 'Kenya',
          city: 'Nairobi',
          state: 'Nairobi',
          countryCode: 'KE',
          zipCode: '00100',
        );

        final redirect = await repository.createPesapalOrder(orderRequest);
        
        setState(() {
          _redirectUrl = redirect.redirectUrl;
          _orderTrackingId = redirect.orderTrackingId;
          _isLoading = false;
        });
      }

      // Start polling for status
      _startStatusPolling();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startStatusPolling() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_orderTrackingId == null) return;

    try {
      final repository = ref.read(transferRepositoryProvider);
      final status = await repository.getPesapalOrderStatus(_orderTrackingId!);

      if (status == 'COMPLETED') {
        _statusCheckTimer?.cancel();
        _handlePaymentSuccess();
      } else if (status == 'FAILED' || status == 'CANCELLED') {
        _statusCheckTimer?.cancel();
        _handlePaymentFailure(status);
      }
    } catch (e) {
      // Continue polling even if status check fails
      print('Status check failed: $e');
    }
  }

  void _handlePaymentSuccess() {
    Navigator.of(context).pushReplacementNamed(
      '/transfer/success',
      arguments: {
        ...widget.paymentDetails,
        'order_tracking_id': _orderTrackingId,
        'status': 'COMPLETED',
      },
    );
  }

  void _handlePaymentFailure(String status) {
    Navigator.of(context).pushReplacementNamed(
      '/transfer/failure',
      arguments: {
        ...widget.paymentDetails,
        'order_tracking_id': _orderTrackingId,
        'status': status,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing payment...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment Error'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Payment Initialization Failed',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Try Again',
                  onPressed: _initializePayment,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Payment summary
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
                      '\$${widget.paymentDetails['total_amount'].toStringAsFixed(2)}',
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
                      widget.paymentDetails['recipient_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Order ID:'),
                    Text(
                      _orderTrackingId ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // WebView for Pesapal payment
          Expanded(
            child: WebViewWidget(
              controller: _webViewController = WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onPageStarted: (String url) {
                      setState(() {
                        _isProcessing = true;
                      });
                    },
                    onPageFinished: (String url) {
                      setState(() {
                        _isProcessing = false;
                      });

                      // Check if this is a callback URL
                      if (url.contains('callback') || url.contains('success')) {
                        _handlePaymentSuccess();
                      } else if (url.contains('cancel') ||
                          url.contains('failure')) {
                        _handlePaymentFailure('CANCELLED');
                      }
                    },
                    onNavigationRequest: (NavigationRequest request) {
                      // Handle navigation requests
                      if (request.url.contains('callback')) {
                        _handlePaymentSuccess();
                        return NavigationDecision.prevent;
                      }
                      return NavigationDecision.navigate;
                    },
                  ),
                )
                ..loadRequest(Uri.parse(_redirectUrl!)),
            ),
          ),

          // Bottom section with payment methods info
          Container(
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
                const Text(
                  'Secure Payment via Pesapal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your payment is secured by Pesapal\'s encryption',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _statusCheckTimer?.cancel();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.grey[800],
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Help',
                        onPressed: _showHelpDialog,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to complete your payment:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('1. Choose your preferred payment method'),
            Text('2. Enter your payment details securely'),
            Text('3. Confirm the transaction'),
            Text('4. Wait for confirmation'),
            SizedBox(height: 16),
            Text(
              'Supported payment methods:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Mobile Money (M-Pesa, Airtel Money)'),
            Text('• Bank Transfer'),
            Text('• Credit/Debit Cards'),
            Text('• Cash Deposit'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Provider for transfer repository
final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  throw UnimplementedError(
    'Provide TransferRepository via override at app start',
  );
});
