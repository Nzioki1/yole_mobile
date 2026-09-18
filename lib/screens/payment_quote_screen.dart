import 'package:flutter/material.dart';
import '../services/core_api_service.dart';
import '../widgets/pin_confirm_sheet.dart';
import '../widgets/premium_summary_widget.dart';

/// Payment quote review and confirmation screen
class PaymentQuoteScreen extends StatefulWidget {
  const PaymentQuoteScreen({super.key});

  @override
  State<PaymentQuoteScreen> createState() => _PaymentQuoteScreenState();
}

class _PaymentQuoteScreenState extends State<PaymentQuoteScreen> {
  final _api = CoreApiService();
  bool _confirming = false;
  List<Map<String, dynamic>> _premiumLineItems = [];
  bool _loadingPremiums = false;
  bool _premiumsLoaded = false;

  @override
  void initState() {
    super.initState();
    _api.init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_premiumsLoaded) {
      _premiumsLoaded = true;
      _loadPremiums();
    }
  }

  Future<void> _loadPremiums() async {
    setState(() => _loadingPremiums = true);

    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      final quote = args['quote'] as Map<String, dynamic>;
      final railType = args['railType'] as String;
      final currency = args['currency'] as String;
      final amountMinor = quote['amountMinor'] as String;

      // Only preview premiums for CDF BILL transactions
      if (currency != 'CDF' || railType != 'BILL') {
        setState(() {
          _loadingPremiums = false;
          _premiumLineItems = [];
        });
        return;
      }

      final lineItems = await _api.previewInsurancePremiums(
        customerId: 'cust_kasee', // TODO: actual customer ID from session
        rail: 'BILL',
        principalMinor: int.parse(amountMinor),
      );

      setState(() {
        _loadingPremiums = false;
        _premiumLineItems = lineItems;
      });
    } catch (e) {
      setState(() {
        _loadingPremiums = false;
        _premiumLineItems = [];
      });
    }
  }

  int _getTotalPremiumMinor() {
    return _premiumLineItems.fold<int>(
      0,
      (sum, item) => sum + (item['premiumMinor'] as int),
    );
  }

  Future<int> _getWalletBalanceMinor(String currency) async {
    try {
      final wallets = await _api.getMyWallets();
      final walletList = wallets['wallets'] as List<dynamic>;
      for (final wallet in walletList) {
        if (wallet['currency'] == currency) {
          return int.tryParse(wallet['availableMinor']?.toString() ?? '0') ?? 0;
        }
      }
    } catch (e) {
      // Ignore error, return 0 to trigger insufficient balance check
    }
    return 0;
  }

  double _getGrandTotal(double originalTotal) {
    final totalPremiumMinor = _getTotalPremiumMinor();
    return originalTotal + (totalPremiumMinor / 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final quote = args['quote'] as Map<String, dynamic>;
    final railType = args['railType'] as String;
    final currency = args['currency'] as String;

    final amountMinor = quote['amountMinor'] as String;
    final feeMinor = quote['feeMinor'] as String;
    final taxMinor = quote['taxMinor'] as String? ?? '0';
    final totalMinor = quote['totalMinor'] as String;

    final amount = (int.tryParse(amountMinor) ?? 0) / 100;
    final fee = (int.tryParse(feeMinor) ?? 0) / 100;
    final tax = (int.tryParse(taxMinor) ?? 0) / 100;
    final total = (int.tryParse(totalMinor) ?? 0) / 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Payment'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00ACAC), Color(0xFF008A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currency == 'USD'
                                ? '\$${total.toStringAsFixed(2)}'
                                : 'FC ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment details
                    Text(
                      'Payment Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Payment Type',
                      value: _getRailLabel(railType),
                    ),
                    _DetailRow(
                      label: 'Amount',
                      value: currency == 'USD'
                          ? '\$${amount.toStringAsFixed(2)}'
                          : 'FC ${amount.toStringAsFixed(2)}',
                    ),
                    _DetailRow(
                      label: 'Fee',
                      value: currency == 'USD'
                          ? '\$${fee.toStringAsFixed(2)}'
                          : 'FC ${fee.toStringAsFixed(2)}',
                    ),
                    if (tax > 0)
                      _DetailRow(
                        label: 'Tax',
                        value: currency == 'USD'
                            ? '\$${tax.toStringAsFixed(2)}'
                            : 'FC ${tax.toStringAsFixed(2)}',
                      ),
                    const Divider(height: 32),
                    _DetailRow(
                      label: 'Total',
                      value: currency == 'USD'
                          ? '\$${total.toStringAsFixed(2)}'
                          : 'FC ${total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),

                    // Insurance premiums
                    if (_loadingPremiums)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      PremiumSummaryWidget(
                        premiumLineItems: _premiumLineItems,
                        currency: currency,
                      ),

                    // Grand total (payment + premiums)
                    if (_premiumLineItems.isNotEmpty) ...[
                      const Divider(height: 32),
                      _DetailRow(
                        label: 'Total to debit',
                        value: currency == 'USD'
                            ? '\$${_getGrandTotal(total).toStringAsFixed(2)}'
                            : 'FC ${_getGrandTotal(total).toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Confirm button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirming ? null : () => _handleConfirm(quote['paymentId'] as String),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _confirming
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Confirm Payment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRailLabel(String railType) {
    switch (railType) {
      case 'W2W':
        return 'Wallet to Wallet';
      case 'MNO_OUT':
        return 'Mobile Money';
      case 'BANK_OUT':
        return 'Bank Transfer';
      case 'BILL':
        return 'Bill Payment';
      case 'AIRTIME':
        return 'Airtime Purchase';
      default:
        return railType;
    }
  }

  Future<void> _handleConfirm(String paymentId) async {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final quote = args['quote'] as Map<String, dynamic>;
    final currency = args['currency'] as String;
    final railType = args['railType'] as String;
    final totalMinor = int.parse(quote['totalMinor'] as String);

    // Calculate grand total including premiums
    final totalPremiumMinor = _getTotalPremiumMinor();
    final grandTotalMinor = totalMinor + totalPremiumMinor;

    // Check wallet balance
    final walletBalanceMinor = await _getWalletBalanceMinor(currency);
    if (walletBalanceMinor < grandTotalMinor) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Insufficient balance. Required: ${(grandTotalMinor / 100).toStringAsFixed(2)} $currency, '
              'Available: ${(walletBalanceMinor / 100).toStringAsFixed(2)} $currency'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if PIN is set
    final hasPin = await _api.hasPin();

    if (!hasPin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set a transaction PIN first. Go to Profile → Settings.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show PIN confirmation sheet
    if (!mounted) return;
    final pin = await PinConfirmSheet.show(
      context,
      title: 'Confirm Payment',
      message: 'Enter your PIN to confirm this payment',
    );

    if (pin == null || !mounted) return;

    setState(() => _confirming = true);

    try {
      // Verify PIN
      final pinValid = await _api.verifyPin(pin: pin);
      if (!pinValid) {
        setState(() => _confirming = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid PIN'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final result = await _api.confirmPayment(paymentId: paymentId);

      // Collect insurance premiums after successful payment
      if (_premiumLineItems.isNotEmpty && currency == 'CDF' && railType == 'BILL') {
        try {
          final amountMinor = quote['amountMinor'] as String;
          await _api.collectInsurancePremiums(
            customerId: 'cust_kasee', // TODO: actual customer ID from session
            rail: 'BILL',
            principalMinor: int.parse(amountMinor),
            parentTransactionId: paymentId,
          );
        } catch (e) {
          // Log premium collection error but don't block payment success flow
          debugPrint('Insurance premium collection error: $e');
        }
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/payment/result',
          arguments: {
            'success': true,
            'payment': result,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/payment/result',
          arguments: {
            'success': false,
            'error': e.toString(),
          },
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(isTotal ? 1.0 : 0.7),
              fontSize: isTotal ? 16 : 15,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: isTotal ? 18 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
