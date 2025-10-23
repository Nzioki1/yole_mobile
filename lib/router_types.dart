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
}
