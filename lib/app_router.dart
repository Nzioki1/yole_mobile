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

      // Optional futures
      case RouteNames.language:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar:
                AppBar(title: Text(AppLocalizations.of(context)!.comingSoon)),
            body: Center(child: Text('${settings.name} not implemented yet')),
          ),
        );

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
