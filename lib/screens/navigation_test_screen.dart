import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yole_mobile/l10n/app_localizations.dart';
import '../providers/app_provider.dart';

/// Navigation Test Screen - Helps test all routes and UI/UX flows
class NavigationTestScreen extends ConsumerWidget {
  const NavigationTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appState = ref.watch(appProvider);

    return Scaffold(
      backgroundColor: appState.isDark ? const Color(0xFF0B0F19) : Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.navigationTest),
        backgroundColor: appState.isDark ? const Color(0xFF0B0F19) : Colors.white,
        foregroundColor: appState.isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test All Navigation Routes',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: appState.isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(context, 'Authentication Flow', [
              _buildRouteButton(context, 'Splash Screen', '/splash'),
              _buildRouteButton(context, 'Welcome Screen', '/welcome'),
              _buildRouteButton(context, 'Login Screen', '/login'),
              _buildRouteButton(context, 'Create Account', '/register'),
              _buildRouteButton(context, 'Email Verification', '/email-verification'),
              _buildRouteButton(context, 'Forgot Password', '/forgot-password'),
            ]),
            const SizedBox(height: 24),
            _buildSection(context, 'KYC Flow', [
              _buildRouteButton(context, 'KYC Screen', '/kyc'),
              _buildRouteButton(context, 'KYC Phone', '/kyc-phone'),
              _buildRouteButton(context, 'KYC OTP', '/kyc-otp'),
              _buildRouteButton(context, 'KYC ID Capture', '/kyc-id-capture'),
              _buildRouteButton(context, 'KYC Selfie', '/kyc-selfie'),
              _buildRouteButton(context, 'KYC Success', '/kyc-success'),
              _buildRouteButton(context, 'KYC Error', '/kyc-error'),
            ]),
            const SizedBox(height: 24),
            _buildSection(context, 'Main App', [
              _buildRouteButton(context, 'Home Screen', '/home'),
              _buildRouteButton(context, 'Profile Screen', '/profile'),
              _buildRouteButton(context, 'Favorites Screen', '/favorites'),
              _buildRouteButton(context, 'Transactions History', '/transactions'),
            ]),
            const SizedBox(height: 24),
            _buildSection(context, 'Send Money Flow', [
              _buildRouteButton(context, 'Enter Details', '/send-money-enter-details'),
              _buildRouteButton(context, 'Review & Fees', '/send-money-review'),
              _buildRouteButton(context, 'Payment Method', '/send-money-payment'),
              _buildRouteButton(context, 'PSP Checkout', '/send-money-checkout'),
              _buildRouteButton(context, 'Result Success', '/send-money-result', {
                'status': 'success',
                'yoleReference': 'YOLE123456789',
                'pspTransactionId': 'PSP123456789',
              }),
              _buildRouteButton(context, 'Result Failed', '/send-money-result', {
                'status': 'failed',
                'yoleReference': 'YOLE123456789',
                'pspTransactionId': 'PSP123456789',
              }),
            ]),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(AppLocalizations.of(context)!.goToHome),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildRouteButton(BuildContext context, String title, String route, [Map<String, dynamic>? arguments]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (arguments != null) {
              Navigator.pushNamed(context, route, arguments: arguments);
            } else {
              Navigator.pushNamed(context, route);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[100],
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            alignment: Alignment.centerLeft,
          ),
          child: Text(title),
        ),
      ),
    );
  }
}
