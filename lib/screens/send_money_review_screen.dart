import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/gradient_button.dart';
import '../l10n/app_localizations.dart';
import '../router_types.dart';
import '../widgets/premium_summary_widget.dart';
import '../services/core_api_service.dart';

class SendMoneyReviewScreen extends ConsumerStatefulWidget {
  const SendMoneyReviewScreen({super.key});

  @override
  ConsumerState<SendMoneyReviewScreen> createState() =>
      _SendMoneyReviewScreenState();
}

class _SendMoneyReviewScreenState extends ConsumerState<SendMoneyReviewScreen> {
  bool _hasLoadedFees = false;
  List<Map<String, dynamic>> _premiumLineItems = [];
  bool _loadingPremiums = false;

  @override
  void initState() {
    super.initState();
    print('=== REVIEW SCREEN INIT START ===');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedFees) {
      _hasLoadedFees = true;
      _loadFees();
      _loadPremiums();
    }
  }

  Future<void> _loadFees() async {
    print('=== REVIEW SCREEN _loadFees called ===');
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    print('Review screen args: $args');

    if (args == null) {
      print('ERROR: Review screen args are NULL - returning');
      return;
    }

    final calculatedCharges = args['calculatedCharges'] as double?;
    print('Pre-calculated charges from Enter Details: $calculatedCharges');

    // Don't call API - just use pre-calculated charges
    // If charges are null, display will show 0.0
    return;
  }

  Future<void> _loadPremiums() async {
    setState(() => _loadingPremiums = true);

    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args == null) {
        setState(() {
          _loadingPremiums = false;
          _premiumLineItems = [];
        });
        return;
      }

      final amount = args['amount'] as double;
      final currency = args['currency'] as String;

      // Premiums only for USD (Send Money typically uses USD)
      // Convert USD amount to CDF for premium calculation
      // In offline demo, assume 1 USD = 2750 CDF exchange rate
      final principalCdfMinor = (amount * 2750 * 100).round();

      final api = CoreApiService();
      await api.init();
      
      final lineItems = await api.previewInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'SEND',
        principalMinor: principalCdfMinor,
      );

      setState(() {
        _loadingPremiums = false;
        _premiumLineItems = lineItems;
      });
    } catch (e) {
      print('Failed to load premiums: $e');
      setState(() {
        _loadingPremiums = false;
        _premiumLineItems = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('=== REVIEW SCREEN build called ===');
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);
    final chargesState = ref.watch(chargesProvider);
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      print('ERROR: Review screen args NULL in build - popping back');
      Navigator.pop(context);
      return const SizedBox.shrink();
    }

    print('Review screen building with args');
    final amount = args['amount'] as double;
    final currency = args['currency'] as String;
    final recipient = args['recipient'] as String;
    final note = args['note'] as String?;

    // Always use pre-calculated charges, never from chargesProvider
    final calculatedCharges = args['calculatedCharges'] as double?;
    final calculatedTotal = args['totalAmount'] as double?;
    final feeAmount = calculatedCharges ?? 0.0;
    final totalAmount = calculatedTotal ?? amount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme, appState),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      _buildReviewCard(
                          theme, appState, amount, currency, recipient, note),
                      const SizedBox(height: 24),
                      _buildFeesSection(theme, appState, amount, currency,
                          feeAmount, totalAmount, chargesState),
                      
                      // Insurance premiums
                      if (_loadingPremiums)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_premiumLineItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PremiumSummaryWidget(
                            premiumLineItems: _premiumLineItems,
                            currency: 'CDF',
                          ),
                        ),
                      
                      // Grand total (if premiums exist)
                      if (_premiumLineItems.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total to debit',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'FC ${_getGrandTotal(totalAmount).toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 48),
                      _buildContinueButton(
                          theme, appState, args, feeAmount, totalAmount),
                    ],
                  ),
                ),
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
              'Review & Fees',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.appBarTheme.titleTextStyle?.color ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Edit',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ThemeData theme, AppState appState, double amount,
      String currency, String recipient, String? note) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer Details',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
              'Amount',
              '${currency == 'USD' ? '\$' : '€'}${amount.toStringAsFixed(2)} $currency',
              theme,
              appState),
          _buildDetailRow('Recipient', recipient, theme, appState),
          if (note != null && note.isNotEmpty) ...[
            _buildDetailRow('Note', note, theme, appState),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, ThemeData theme, AppState appState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeesSection(
      ThemeData theme,
      AppState appState,
      double amount,
      String currency,
      double feeAmount,
      double totalAmount,
      ChargesState chargesState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fees & Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (chargesState.error != null || chargesState.isLoading)
                TextButton(
                  onPressed: chargesState.isLoading ? null : _loadFees,
                  child: Text(
                    chargesState.isLoading ? 'Loading...' : 'Refresh fees',
                    style: TextStyle(
                      color: appState.isDark
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (chargesState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (chargesState.error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      chargesState.error!,
                      style: TextStyle(
                        color:
                            appState.isDark ? Colors.red[300] : Colors.red[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadFees,
                      child: Text(AppLocalizations.of(context)!.retry),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildFeeRow(
                'Amount',
                '${currency == 'USD' ? '\$' : '€'}${amount.toStringAsFixed(2)} $currency',
                theme,
                appState),
            _buildFeeRow(
                'Fees',
                '${currency == 'USD' ? '\$' : '€'}${feeAmount.toStringAsFixed(2)} $currency',
                theme,
                appState),
            const Divider(),
            _buildFeeRow(
                'Total charged',
                '${currency == 'USD' ? '\$' : '€'}${totalAmount.toStringAsFixed(2)} $currency',
                theme,
                appState,
                isTotal: true),
            const SizedBox(height: 8),
            Text(
              'Fees provided by Poste Finance Fees API',
              style: TextStyle(
                color: appState.isDark ? Colors.white54 : Colors.grey[500],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeRow(
      String label, String value, ThemeData theme, AppState appState,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  double _getGrandTotal(double originalTotal) {
    final totalPremiumMinor = _premiumLineItems.fold<int>(
      0,
      (sum, item) => sum + (item['premiumMinor'] as int),
    );
    // Original total is in USD, premiums in CDF — convert USD to CDF for grand total
    final originalTotalCdf = originalTotal * 2750;
    return originalTotalCdf + (totalPremiumMinor / 100);
  }

  Widget _buildContinueButton(ThemeData theme, AppState appState,
      Map<String, dynamic> args, double feeAmount, double totalAmount) {
    // Check insufficient balance if premiums exist
    bool hasInsufficientBalance = false;
    String? balanceError;
    
    if (_premiumLineItems.isNotEmpty) {
      final grandTotal = _getGrandTotal(totalAmount);
      // Get wallet balance from appState (assumed to be in CDF)
      // For now, assume sufficient balance (real balance check would query wallet)
      // In production, check: appState.walletBalance < grandTotal
      // hasInsufficientBalance = appState.walletBalance < grandTotal;
      // if (hasInsufficientBalance) {
      //   balanceError = 'Insufficient balance to cover amount and insurance premiums';
      // }
    }
    
    return Column(
      children: [
        if (balanceError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      balanceError,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          height: 48,
          child: GradientButton(
            onPressed: hasInsufficientBalance ? null : () {
              // Logging for debugging navigation arguments
              print('=== REVIEW: NAVIGATE TO CHECKOUT ===');
              print('Base args: $args');
              print('Fee amount: $feeAmount');
              print('Total amount: $totalAmount');

              final checkoutArgs = {
                ...args,
                'feeAmount': feeAmount,
                'totalAmount': totalAmount,
                'premiumLineItems': _premiumLineItems,
              };

              print('Checkout args to send: $checkoutArgs');
              print('Checkout args keys: ${checkoutArgs.keys.toList()}');

              // Navigate to payment processing (checkout)
              Navigator.pushNamed(
                context,
                RouteNames.sendMoneyCheckout,
                arguments: checkoutArgs,
              );
              print('Navigation call completed');
            },
            child: const Text('Proceed to Payment'),
          ),
        ),
      ],
    );
  }
}
