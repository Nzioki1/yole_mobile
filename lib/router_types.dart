/// Typed arguments used by router navigation.
class TxDetailsArgs {
  final String txId;
  const TxDetailsArgs(this.txId);
}

/// Route names constants
class RouteNames {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String language = '/language';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String kyc = '/kyc';
  static const String transactions = '/transactions';
  static const String favorites = '/favorites';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';

  // KYC Flow Routes
  static const String kycPhone = '/kyc-phone';
  static const String kycOtp = '/kyc-otp';
  static const String kycIdCapture = '/kyc-id-capture';
  static const String kycSelfie = '/kyc-selfie';
  static const String kycSuccess = '/kyc-success';

  // Send Money Flow Routes
  static const String sendMoneyEnterDetails =
      '/send-money-enter-details'; // 1. Enter details + calculate charges + select payment method
  static const String sendMoneyReview =
      '/send-money-review'; // 2. Checkout (review details + fees)
  // sendMoneyPayment REMOVED - payment method selection now done in Enter Details
  static const String sendMoneyCheckout =
      '/send-money-checkout'; // 3. Payment processing (PesaPal/mobile money)
  static const String sendMoneyResult =
      '/send-money-result'; // 4. Result + transaction status
}
