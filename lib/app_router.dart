import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

// Route name constants
import 'router_types.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/kyc_screen.dart';
import 'screens/kyc_phone_screen.dart';
import 'screens/kyc_otp_screen.dart';
import 'screens/kyc_id_capture_screen.dart';
import 'screens/kyc_selfie_screen.dart';
import 'screens/kyc_success_screen.dart';
import 'screens/send_money_enter_details_screen.dart';
import 'screens/send_money_review_screen.dart';
// import 'screens/send_money_payment_screen.dart'; // REMOVED - redundant payment selection screen
import 'screens/send_money_checkout_screen.dart';
import 'screens/send_money_result_screen.dart';
import 'screens/cards_screen.dart';
import 'screens/card_issue_screen.dart';
import 'screens/card_detail_screen.dart';
import 'screens/credit_screen.dart';
import 'screens/credit_apply_screen.dart';
import 'screens/credit_loan_detail_screen.dart';
import 'screens/remittance_screen.dart';
import 'screens/fx_screen.dart';
import 'screens/payment_rail_picker_screen.dart';
import 'screens/payment_form_screen.dart';
import 'screens/payment_quote_screen.dart';
import 'screens/payment_result_screen.dart';
import 'screens/fund_wallet_screen.dart';
import 'screens/withdraw_screen.dart';
import 'screens/language_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/transaction_detail_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/savings_create_goal_screen.dart';
import 'screens/savings_goal_detail_screen.dart';
import 'screens/insurance_screen.dart';
import 'screens/budget_screen.dart';

// Tab host that keeps tabs alive for instant switching
import 'screens/main_tabs.dart'; // ensure you have lib/screens/main_tabs.dart

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Entry
      case '/':
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      // Onboarding
      case RouteNames.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      // Auth
      case RouteNames.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(
            postLoginRoute: RouteNames.home,
            signUpRoute: RouteNames.register,
            forgotPasswordRoute: RouteNames.forgotPassword,
          ),
        );

      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const CreateAccountScreen());

      case RouteNames.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case RouteNames.emailVerification:
        return MaterialPageRoute(
            builder: (_) => const EmailVerificationScreen());

      /// Tabs — all tab routes are hosted inside MainTabsScreen so switching is INSTANT.
      case RouteNames.home:
        return MaterialPageRoute(
            builder: (_) => const MainTabsScreen(initialIndex: 0));

      case RouteNames.transactions: // History
        return MaterialPageRoute(
            builder: (_) => const MainTabsScreen(initialIndex: 1));

      case RouteNames.favorites:
        return MaterialPageRoute(
            builder: (_) => const MainTabsScreen(initialIndex: 2));

      case RouteNames.profile:
        // Route to the 4th tab to maintain a single tab host
        return MaterialPageRoute(
            builder: (_) => const MainTabsScreen(initialIndex: 3));

      // KYC Flow Routes
      case RouteNames.kyc:
        return MaterialPageRoute(builder: (_) => const KYCScreen());

      case RouteNames.kycPhone:
        return MaterialPageRoute(builder: (_) => const KYCPhoneScreen());

      case RouteNames.kycOtp:
        return MaterialPageRoute(builder: (_) => const KYCOTPScreen());

      case RouteNames.kycIdCapture:
        return MaterialPageRoute(builder: (_) => const KYCIdCaptureScreen());

      case RouteNames.kycSelfie:
        return MaterialPageRoute(builder: (_) => const KYCSelfieScreen());

      case RouteNames.kycSuccess:
        return MaterialPageRoute(builder: (_) => const KYCSuccessScreen());

      // Send Money Flow Routes
      case RouteNames.sendMoneyEnterDetails:
        return MaterialPageRoute(
            builder: (_) => const SendMoneyEnterDetailsScreen());

      case RouteNames.sendMoneyReview:
        return MaterialPageRoute(
          settings: settings, // Pass the settings with arguments
          builder: (_) => const SendMoneyReviewScreen(),
        );

      // REMOVED: sendMoneyPayment route - payment selection now done in Enter Details

      case RouteNames.sendMoneyCheckout:
        return MaterialPageRoute(
          builder: (_) => const SendMoneyCheckoutScreen(),
          settings: settings, // ensure arguments are preserved
        );

      case RouteNames.sendMoneyResult:
        return MaterialPageRoute(builder: (_) => const SendMoneyResultScreen());

      // Neo-bank features
      case '/cards':
        return MaterialPageRoute(builder: (_) => const CardsScreen());

      case '/credit':
        return MaterialPageRoute(builder: (_) => const CreditScreen());

      case '/fx':
        return MaterialPageRoute(builder: (_) => const FxScreen());

      // Fund wallet (Add money)
      case '/fund':
        return MaterialPageRoute(builder: (_) => const FundWalletScreen());

      // Withdraw (cash out)
      case '/withdraw':
        return MaterialPageRoute(builder: (_) => const WithdrawScreen());

      // Multi-rail payment flow
      case '/payment/picker':
        return MaterialPageRoute(builder: (_) => const PaymentRailPickerScreen());

      case '/payment/w2w':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PaymentFormScreen(
            railType: 'W2W',
            prefillDestination: args?['destination'] as String?,
            prefillNote: args?['note'] as String?,
          ),
        );

      case '/payment/mno':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PaymentFormScreen(
            railType: 'MNO_OUT',
            prefillDestination: args?['destination'] as String?,
            prefillNote: args?['note'] as String?,
          ),
        );

      case '/payment/bank':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PaymentFormScreen(
            railType: 'BANK_OUT',
            prefillDestination: args?['destination'] as String?,
            prefillNote: args?['note'] as String?,
          ),
        );

      case '/payment/bill':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PaymentFormScreen(
            railType: 'BILL',
            prefillDestination: args?['destination'] as String?,
            prefillNote: args?['note'] as String?,
          ),
        );

      case '/payment/airtime':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => PaymentFormScreen(
            railType: 'AIRTIME',
            prefillDestination: args?['destination'] as String?,
            prefillNote: args?['note'] as String?,
          ),
        );

      case '/payment/quote':
        return MaterialPageRoute(
          builder: (_) => const PaymentQuoteScreen(),
          settings: settings,
        );

      case '/payment/result':
        return MaterialPageRoute(
          builder: (_) => const PaymentResultScreen(),
          settings: settings,
        );

      // Optional futures
      case RouteNames.language:
        return MaterialPageRoute(builder: (_) => const LanguageScreen());

      case RouteNames.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case RouteNames.transactionDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final paymentId = args?['paymentId'] as String?;
        if (paymentId == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Payment ID required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(paymentId: paymentId),
        );

      case RouteNames.creditApply:
        final args = settings.arguments as Map<String, dynamic>?;
        final type = args?['type'] as String?;
        if (type == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Credit type required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CreditApplyScreen(type: type),
        );

      case RouteNames.creditDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final loanId = args?['loanId'] as String?;
        if (loanId == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Loan ID required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CreditLoanDetailScreen(loanId: loanId),
        );

      case RouteNames.cardIssue:
        return MaterialPageRoute(builder: (_) => const CardIssueScreen());

      case RouteNames.cardDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final cardId = args?['cardId'] as String?;
        if (cardId == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Card ID required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CardDetailScreen(cardId: cardId),
        );

      case RouteNames.remittance:
        return MaterialPageRoute(builder: (_) => const RemittanceScreen());

      // Poste Finance Products
      case RouteNames.savings:
        return MaterialPageRoute(builder: (_) => const SavingsScreen());

      case RouteNames.savingsCreateGoal:
        return MaterialPageRoute(
            builder: (_) => const SavingsCreateGoalScreen());

      case RouteNames.savingsGoalDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final goalId = args?['goalId'] as String?;
        if (goalId == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Goal ID required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => SavingsGoalDetailScreen(goalId: goalId),
        );

      case RouteNames.insurance:
        return MaterialPageRoute(builder: (_) => const InsuranceScreen());

      case RouteNames.budget:
        return MaterialPageRoute(builder: (_) => const BudgetScreen());

      // Fallback
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
                child: Text(AppLocalizations.of(context)!.routeNotFound)),
          ),
        );
    }
  }
}
