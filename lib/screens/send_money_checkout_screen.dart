import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../l10n/app_localizations.dart';

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

  @override
  void initState() {
    super.initState();
    _simulateCheckout();
  }

  void _simulateCheckout() {
    // Simulate loading checkout page
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Simulate success for demo
          _navigateToResult();
        });
      }
    });
  }

  void _navigateToResult() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    Navigator.pushReplacementNamed(
      context,
      '/send-money-result',
      arguments: {
        ...?args,
        'status': 'success',
        'yoleReference': 'YOLE${DateTime.now().millisecondsSinceEpoch}',
        'pspTransactionId': 'PSP${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final appState = ref.watch(appProvider);

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
                child: _buildCheckoutContent(theme, appState),
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
        color: appState.isDark ? Colors.white.withOpacity(0.1) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: appState.isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
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
              'Secure checkout • Powered by Pesapal',
              style: theme.textTheme.titleMedium?.copyWith(
                color: appState.isDark ? Colors.white : Colors.black,
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

  Widget _buildCheckoutContent(ThemeData theme, AppState appState) {
    if (_hasError) {
      return _buildErrorState(theme, appState);
    }

    if (_isLoading) {
      return _buildLoadingState(theme, appState);
    }

    return _buildCheckoutInterface(theme, appState);
  }

  Widget _buildCheckoutInterface(ThemeData theme, AppState appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 64,
              color: appState.isDark ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 24),
            Text(
              'Pesapal Checkout',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: appState.isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This is a demo checkout interface.\nIn production, this would integrate with Pesapal.',
              style: TextStyle(
                color: appState.isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _navigateToResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Complete Payment (Demo)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, AppState appState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 16),
          Text(
            'Connecting to Pesapal…',
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
              'Couldn\'t load Pesapal.',
              style: TextStyle(
                color: appState.isDark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again.',
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _isLoading = true;
                    });
                    _simulateCheckout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    // Open in browser - implement if needed
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.openingInBrowser)),
                    );
                  },
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
                    'Open in browser',
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
