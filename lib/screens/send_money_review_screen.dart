import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/gradient_button.dart';
import '../l10n/app_localizations.dart';
import '../router_types.dart';

class SendMoneyReviewScreen extends ConsumerStatefulWidget {
  const SendMoneyReviewScreen({super.key});

  @override
  ConsumerState<SendMoneyReviewScreen> createState() =>
      _SendMoneyReviewScreenState();
}

class _SendMoneyReviewScreenState extends ConsumerState<SendMoneyReviewScreen> {
  bool _hasLoadedFees = false;

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
                    color: appState.isDark ? Colors.white : Colors.black,
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
              'Fees provided by Yole Fees API',
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

  Widget _buildContinueButton(ThemeData theme, AppState appState,
      Map<String, dynamic> args, double feeAmount, double totalAmount) {
    return SizedBox(
      height: 48,
      child: GradientButton(
        onPressed: () {
          // Logging for debugging navigation arguments
          print('=== REVIEW: NAVIGATE TO CHECKOUT ===');
          print('Base args: $args');
          print('Fee amount: $feeAmount');
          print('Total amount: $totalAmount');

          final checkoutArgs = {
            ...args,
            'feeAmount': feeAmount,
            'totalAmount': totalAmount,
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
    );
  }
}
