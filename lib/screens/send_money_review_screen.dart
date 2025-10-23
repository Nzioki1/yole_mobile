import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';

class SendMoneyReviewScreen extends ConsumerStatefulWidget {
  const SendMoneyReviewScreen({super.key});

  @override
  ConsumerState<SendMoneyReviewScreen> createState() =>
      _SendMoneyReviewScreenState();
}

class _SendMoneyReviewScreenState extends ConsumerState<SendMoneyReviewScreen> {
  bool _isLoadingFees = false;
  double _feeAmount = 0.0;
  String? _feesError;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() {
      _isLoadingFees = true;
      _feesError = null;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock fees calculation
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final amount = args['amount'] as double;
        _feeAmount = amount * 0.025; // 2.5% fee
      }

      setState(() {
        _isLoadingFees = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFees = false;
        _feesError = 'We couldn\'t load fees. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final appState = ref.watch(appProvider);
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      Navigator.pop(context);
      return const SizedBox.shrink();
    }

    final amount = args['amount'] as double;
    final currency = args['currency'] as String;
    final recipient = args['recipient'] as String;
    final note = args['note'] as String?;
    final totalAmount = amount + _feeAmount;

    return Scaffold(
      backgroundColor: appState.isDark ? null : Colors.white,
      body: Container(
        decoration: appState.isDark
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B0F19), Color(0xFF19173D)],
                ),
              )
            : null,
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
                      _buildFeesSection(
                          theme, appState, amount, currency, totalAmount),
                      const SizedBox(height: 48),
                      _buildContinueButton(theme, appState, args),
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
              color: appState.isDark ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              'Review & Fees',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: appState.isDark ? Colors.white : Colors.black,
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
                color: appState.isDark
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF3B82F6),
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
        color:
            appState.isDark ? Colors.white.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appState.isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transfer Details',
            style: theme.textTheme.titleMedium?.copyWith(
              color: appState.isDark ? Colors.white : Colors.black,
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
                color: appState.isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: appState.isDark ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeesSection(ThemeData theme, AppState appState, double amount,
      String currency, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            appState.isDark ? Colors.white.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appState.isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[200]!,
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
              if (_feesError != null || _isLoadingFees)
                TextButton(
                  onPressed: _isLoadingFees ? null : _loadFees,
                  child: Text(
                    _isLoadingFees ? 'Loading...' : 'Refresh fees',
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
          if (_isLoadingFees)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_feesError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _feesError!,
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
                      child: Text(l10n.retry),
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
                '${currency == 'USD' ? '\$' : '€'}${_feeAmount.toStringAsFixed(2)} $currency',
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
              color: appState.isDark ? Colors.white70 : Colors.grey[600],
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: appState.isDark ? Colors.white : Colors.black,
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(
      ThemeData theme, AppState appState, Map<String, dynamic> args) {
    final canContinue = !_isLoadingFees && _feesError == null;

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: canContinue
            ? () {
                // Navigate to payment method selection
                Navigator.pushNamed(
                  context,
                  '/send-money-payment',
                  arguments: {
                    ...args,
                    'feeAmount': _feeAmount,
                    'totalAmount': args['amount'] + _feeAmount,
                  },
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canContinue ? const Color(0xFF3B82F6) : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
