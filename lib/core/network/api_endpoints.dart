// Auto-generated API endpoints configuration
// Generated from Postman collection

class ApiEndpoints {
  static const String baseUrl = 'https://yolepesa.masterpiecefusion.com/api/';
  static const String acceptHeader = 'application/x.yole.v1+json';
  static const String apiKey = '8dmPM4Yhv-zSfAXuQmu)hyrBkq(NHTPQ9uvWqhLt_Wka*zQpLY';

  // auth endpoints
  static const String LOGIN = '/login';
  static const String REGISTER = '/register';
  static const String REFRESH_TOKEN = '/refresh-token';
  static const String FORGOT_PASSWORD = '/password/forgot';
  static const String EMAIL_VERIFICATION = '/email/verification-notification';
  static const String LOGOUT = '/logout';
  static const String ME = '/me';

  // kyc endpoints
  static const String VALIDATE_KYC = '/validate-kyc';
  static const String SEND_SMS_OTP = '/sms/send-otp';

  // transfers endpoints
  static const String GET_CHARGES = '/charges';
  static const String GET_SERVICE_CHARGE = '/yole-charges';
  static const String SEND_MONEY = '/send-money';
  static const String TRANSACTION_STATUS = '/transaction/status';

  // transactions endpoints
  static const String GET_TRANSACTIONS = '/transactions';

  // countries endpoints
  static const String GET_COUNTRIES = '/countries';

  // system endpoints
  static const String STATUS = '/status';

}
