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

      // Calculate principal for premium preview
      final int principalMinor;
      if (currency == 'CDF') {
        // If sending CDF, use amount directly in CDF minor
        principalMinor = (amount * 100).round();
      } else {
        // If sending USD, convert to CDF at 2750 rate for premium calculation only
        principalMinor = (amount * 2750 * 100).round();
      }

      final api = CoreApiService();
      await api.init();
      
      final lineItems = await api.previewInsurancePremiums(
        customerId: 'cust_kasee',
        rail: 'SEND',
        principalMinor: principalMinor,
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

  int _getTotalPremiumMinor() {
    return _premiumLineItems.fold<int>(
      0,
      (sum, item) => sum + (item['premiumMinor'] as int),
    );
  }

  Future<int> _getWalletBalanceMinor(String currency) async {
    try {
      final api = CoreApiService();
      await api.init();
      final wallets = await api.getMyWallets();
      final walletList = wallets['wallets'] as List<dynamic>;
      for (final wallet in walletList) {
        if (wallet['currency'] == currency) {
          return int.tryParse(wallet['availableMinor']?.toString() ?? '0') ?? 0;
        }
      }
    } catch (e) {
      print('Failed to get wallet balance: $e');
    }
    return 0;
  }

  Future<void> _handleContinue(BuildContext context, Map<String, dynamic> args, 
      double feeAmount, double totalAmount) async {
    // Check wallet balance if premiums exist
    if (_premiumLineItems.isNotEmpty) {
      final amount = args['amount'] as double;
      final currency = args['currency'] as String;
      final totalPremiumMinor = _getTotalPremiumMinor();

      if (currency == 'CDF') {
        // If sending CDF, check CDF wallet for (principal + fees + premiums)
        final totalMinor = (totalAmount * 100).round(); // principal + fees in CDF minor
        final grandTotalMinor = totalMinor + totalPremiumMinor;
        
        final cdfBalanceMinor = await _getWalletBalanceMinor('CDF');
        if (cdfBalanceMinor < grandTotalMinor) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Insufficient balance to cover amount and insurance premiums. '
                  'Required: ${(grandTotalMinor / 100).toStringAsFixed(2)} CDF, '
                  'Available: ${(cdfBalanceMinor / 100).toStringAsFixed(2)} CDF'
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } else {
        // If sending USD, check USD wallet for (principal + fees) 
        // AND check CDF wallet for premiums
        final usdTotalMinor = (totalAmount * 100).round();
        final usdBalanceMinor = await _getWalletBalanceMinor('USD');
        
        if (usdBalanceMinor < usdTotalMinor) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Insufficient USD balance. '
                  'Required: ${(usdTotalMinor / 100).toStringAsFixed(2)} USD, '
                  'Available: ${(usdBalanceMinor / 100).toStringAsFixed(2)} USD'
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Also check CDF wallet for premiums
        final cdfBalanceMinor = await _getWalletBalanceMinor('CDF');
        if (cdfBalanceMinor < totalPremiumMinor) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Insufficient CDF balance for insurance premiums. '
                  'Required: ${(totalPremiumMinor / 100).toStringAsFixed(2)} CDF, '
                  'Available: ${(cdfBalanceMinor / 100).toStringAsFixed(2)} CDF'
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    }

    // Balance check passed, proceed to checkout
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

    if (context.mounted) {
      Navigator.pushNamed(
        context,
        RouteNames.sendMoneyCheckout,
        arguments: checkoutArgs,
      );
      print('Navigation call completed');
    }
  }

  Widget _buildContinueButton(ThemeData theme, AppState appState,
      Map<String, dynamic> args, double feeAmount, double totalAmount) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: GradientButton(
            onPressed: () => _handleContinue(context, args, feeAmount, totalAmount),
            child: const Text('Proceed to Payment'),
          ),
        ),
      ],
    );
  }
}
