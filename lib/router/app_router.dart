import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/kyc_verification_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/balance_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/transfer/presentation/transfer_details_screen.dart';
import '../features/transfer/presentation/recipient_selection_screen.dart';
import '../features/transfer/presentation/transfer_confirmation_screen.dart';
// SendMoneyScreen import removed - using step-based flow instead

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      try {
        final authState = ProviderScope.containerOf(context).read(authProvider);
        print(
          '🔍 AppRouter: Redirect check - isAuthenticated: ${authState.isAuthenticated}, loading: ${authState.loading}, location: ${state.matchedLocation}',
        );

        // Don't redirect if still loading
        if (authState.loading) {
          print('🔍 AppRouter: Still loading, no redirect');
          return null;
        }

        // If not authenticated and not on auth pages, redirect to login (but allow KYC verification)
        if (!authState.isAuthenticated &&
            !state.matchedLocation.startsWith('/login') &&
            !state.matchedLocation.startsWith('/signup') &&
            !state.matchedLocation.startsWith('/kyc-verification')) {
          print('🔍 AppRouter: Redirecting to login - not authenticated');
          return '/login';
        }

        // If authenticated and on auth pages, redirect to home (but allow KYC verification)
        if (authState.isAuthenticated &&
            (state.matchedLocation.startsWith('/login') ||
                state.matchedLocation.startsWith('/signup')) &&
            !state.matchedLocation.startsWith('/kyc-verification')) {
          print('🔍 AppRouter: Redirecting to home - already authenticated');
          return '/home';
        }

        print('🔍 AppRouter: No redirect needed');
        return null;
      } catch (e) {
        // If there's any error reading the provider, redirect to login as fallback
        print(
          '🔍 AppRouter: Router redirect error: $e - redirecting to login as fallback',
        );
        return '/login';
      }
    },
    errorBuilder: (context, state) {
      print('🔍 AppRouter: Error building route: ${state.error}');
      return const Scaffold(
        body: Center(child: Text('Route not found or error occurred')),
      );
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/kyc-verification',
        name: 'kyc_verification',
        builder: (context, state) => const KYCVerificationScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const DashboardScreen(),
      ),
      // Send money is handled by the dashboard navigation to TransferStep1Screen
      // No separate route needed
      GoRoute(
        path: '/balance',
        name: 'balance',
        builder: (context, state) => const BalanceScreen(),
      ),
      GoRoute(
        path: '/transfer-details',
        name: 'transfer_details',
        builder: (context, state) => const TransferDetailsScreen(),
      ),
      GoRoute(
        path: '/transfer-recipient',
        name: 'recipient_selection',
        builder: (context, state) {
          final transferDetails = state.extra as Map<String, dynamic>;
          return RecipientSelectionScreen(transferDetails: transferDetails);
        },
      ),
      GoRoute(
        path: '/transfer-confirmation',
        name: 'transfer_confirmation',
        builder: (context, state) {
          final transferData = state.extra as Map<String, dynamic>;
          return TransferConfirmationScreen(transferData: transferData);
        },
      ),
    ],
  );
}
