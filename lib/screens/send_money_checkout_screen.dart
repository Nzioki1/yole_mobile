import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/gradient_button.dart';
import '../router_types.dart';
import '../services/pesapal_service.dart';
import '../models/transaction_request_model.dart';
import '../utils/payment_validator.dart';
import '../providers/api_providers.dart';

class SendMoneyCheckoutScreen extends ConsumerStatefulWidget {
  const SendMoneyCheckoutScreen({super.key});

  @override
  ConsumerState<SendMoneyCheckoutScreen> createState() =>
      _SendMoneyCheckoutScreenState();
}

class _SendMoneyCheckoutScreenState
    extends ConsumerState<SendMoneyCheckoutScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _paymentStatus;
  bool _hasInitialized = false; // Add flag to prevent multiple calls
  final PesaPalService _pesaPalService = PesaPalService();

  // didChangeDependencies removed in favor of build-time initialization

  Future<void> _initializeCheckout() async {
    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      print('=== CHECKOUT INITIALIZATION START ===');
      print('Args received: $args');
      print('Args type: ${args.runtimeType}');
      print('Args keys: ${args?.keys.toList()}');

      // Validate all required fields
      if (args == null || args.isEmpty) {
        print('ERROR: Arguments are NULL or EMPTY');
        throw Exception('No transaction data provided');
      }

      // Defensive extraction and type normalization
      final dynamic amountValue = args['amount'] ?? args['sendingAmount'];
      final double? amount = amountValue is int
          ? amountValue.toDouble()
          : amountValue is double
              ? amountValue
              : null;

      final String? recipientPhone = (args['recipientPhone'] as String?) ??
          (args['phoneNumber'] as String?);
      final String? recipientCountry =
          (args['recipientCountry'] as String?) ?? (args['country'] as String?);
      final String? paymentMethod =
          (args['paymentMethod'] as String?) ?? 'mobile_money';
      final String? recipient = args['recipient'] as String?;

      print('=== CHECKOUT VALIDATION (PARSED) ===');
      print('Amount (parsed): $amount');
      print('Phone: $recipientPhone');
      print('Country: $recipientCountry');
      print('Payment Method: $paymentMethod');
      print('Recipient: $recipient');

      // Get user email from storage
      final userProfile =
          await ref.read(storageServiceProvider).getUserProfile();
      if (userProfile == null || userProfile.email.isEmpty) {
        throw Exception('User email not found. Please login again.');
      }

      // Validate all payment data
      final validations = PaymentValidator.validatePaymentData(
        amount: amount,
        phone: recipientPhone,
        country: recipientCountry,
        email: userProfile.email,
        paymentMethod: paymentMethod,
        recipient: recipient,
      );

      final firstError = PaymentValidator.getFirstError(validations);
      if (firstError != null) {
        throw Exception(firstError);
      }

      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      if (paymentMethod == 'mobile_money') {
        await _processMobileMoneyPayment({
          ...args,
          'amount': amount,
          'recipientPhone': recipientPhone,
          'recipientCountry': recipientCountry,
        });
      } else {
        await _processPesaPalPayment({
          ...args,
          'amount': amount,
          'recipientPhone': recipientPhone,
          'recipientCountry': recipientCountry,
        }, userProfile.email);
      }
    } catch (e, stackTrace) {
      print('\n═══════════════════════════════════════════════');
      print('❌ CHECKOUT ERROR CAUGHT');
      print('═══════════════════════════════════════════════');
      print('Error Type: ${e.runtimeType}');
      print('Error: $e');
      print('Stack Trace:');
      print(stackTrace);
      print('═══════════════════════════════════════════════\n');

      // Extract user-friendly error message
      String errorMessage;
      if (e.toString().contains('PesaPalException')) {
        errorMessage = e.toString().replaceAll('PesaPalException: ', '');
      } else if (e.toString().contains('Exception')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = errorMessage;
      });
    }
  }

  Future<void> _processMobileMoneyPayment(Map<String, dynamic> args) async {
    print('Processing mobile money payment...');

    // Normalize phone for backend: remove + sign and ensure only digits
    // Backend expects exactly 12 digits (no + prefix)
    String phoneNumber = args['recipientPhone'] as String? ?? '';
    phoneNumber =
        phoneNumber.replaceAll(RegExp(r'[^\d]'), ''); // Remove all non-digits

    print('Original phone: ${args['recipientPhone']}');
    print('Normalized phone (digits only): $phoneNumber');

    // Call Yole API directly without PesaPal
    await ref.read(sendMoneyProvider.notifier).sendMoney(
          sendingAmount: args['amount'] as double,
          recipientCountry: args['recipientCountry'] as String? ?? 'CD',
          phoneNumber: phoneNumber,
        );

    final sendMoneyState = ref.read(sendMoneyProvider);
    if (sendMoneyState.response == null) {
      throw Exception('Failed to process payment');
    }

    print('Mobile money payment successful');

    // Navigate directly to result screen
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        RouteNames.sendMoneyResult,
        arguments: {
          ...args,
          'status': 'success',
          'yoleReference': sendMoneyState.response!.reference,
          'yoleTransactionId': sendMoneyState.response!.transactionId,
          'paymentMethod': 'mobile_money',
        },
      );
    }
  }

  Future<void> _processPesaPalPayment(
      Map<String, dynamic> args, String userEmail) async {
    print('\n═══════════════════════════════════════════════');
    print('💰 PROCESSING PESAPAL PAYMENT');
    print('═══════════════════════════════════════════════');
    print('User Email: $userEmail');
    print('Payment Args: $args');

    // Step 1: Create YOLE transaction
    print('\n📍 PRE-STEP: Creating YOLE transaction...');
    setState(() {
      _paymentStatus = 'Creating transaction...';
    });

    try {
      await ref.read(sendMoneyProvider.notifier).sendMoney(
            sendingAmount: args['amount'] as double,
            recipientCountry: args['recipientCountry'] as String,
            phoneNumber: args['recipientPhone'] as String,
          );

      final sendMoneyState = ref.read(sendMoneyProvider);
      if (sendMoneyState.response == null) {
        print('❌ PRE-STEP FAILED: YOLE transaction creation returned null');
        throw Exception('Failed to create YOLE transaction');
      }

      print('✅ PRE-STEP SUCCESS: YOLE transaction created');
      print('   Transaction ID: ${sendMoneyState.response!.transactionId}');
      print('   Reference: ${sendMoneyState.response!.reference}');

      // Step 2: Submit to PesaPal
      setState(() {
        _paymentStatus = 'Initializing payment gateway...';
      });

      final transaction = TransactionRequest.fromArguments({
        ...args,
        'yoleTransactionId': sendMoneyState.response!.transactionId,
        'yoleReference': sendMoneyState.response!.reference,
      });

      print('\n📍 MAIN STEP: Submitting to PesaPal...');
      final orderResponse = await _pesaPalService.submitOrderRequest(
        transaction: transaction,
        userEmail: userEmail,
      );

      print('\n✅ MAIN STEP SUCCESS: PesaPal order submitted');
      print('═══════════════════════════════════════════════');
      print('Order Tracking ID: ${orderResponse.orderTrackingId}');
      print('Merchant Reference: ${orderResponse.merchantReference}');
      print('Redirect URL: ${orderResponse.redirectUrl}');
      print('═══════════════════════════════════════════════\n');

      // Step 3: Navigate to result (no WebView)
      if (mounted) {
    Navigator.pushReplacementNamed(
      context,
      RouteNames.sendMoneyResult,
      arguments: {
            ...args,
            'status': 'pending',
            'yoleReference': sendMoneyState.response!.reference,
            'yoleTransactionId': sendMoneyState.response!.transactionId,
            'pesapalOrderTrackingId': orderResponse.orderTrackingId,
            'pesapalRedirectUrl': orderResponse.redirectUrl,
            'paymentMethod': 'pesapal',
      },
    );
  }
    } catch (e, stackTrace) {
      print('\n❌ PRE-STEP or MAIN STEP FAILED');
      print('Error: $e');
      print('Stack: $stackTrace');
      rethrow; // Re-throw to be caught by outer catch
    }
  }

  void _retryPayment() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    _initializeCheckout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);

    // Initialize on first build when route and arguments are ready
    if (!_hasInitialized) {
      _hasInitialized = true;
      print('=== CHECKOUT FIRST BUILD - Scheduling init ===');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCheckout();
      });
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme, appState),
              Expanded(
                child: _hasError
                    ? _buildErrorState(theme, appState)
                    : _isLoading
                        ? _buildLoadingState(theme, appState)
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              'Secure checkout • Powered by Pesapal',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.appBarTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, AppState appState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            _paymentStatus ?? 'Processing payment...',
            style: TextStyle(
              color: appState.isDark ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, AppState appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: appState.isDark ? Colors.red[300] : Colors.red[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Failed',
              style: TextStyle(
                color: appState.isDark ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                color: appState.isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GradientButton(
                  height: 48,
                  borderRadius: 12,
                  onPressed: _retryPayment,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color:
                          appState.isDark ? Colors.white54 : Colors.grey[400]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      color: appState.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
