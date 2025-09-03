// Auto-generated form fields configuration
// Generated from Postman collection

class FormFields {
  // register form fields
  static const Map<String, String> register = {
    'email': 'email',
    'name': 'name',
    'surname': 'surname',
    'password': 'password',
    'password_confirmation': 'password_confirmation',
    'country': 'country',
  };

  // login form fields
  static const Map<String, String> login = {
    'email': 'email',
    'password': 'password',
  };

  // forgot_password form fields
  static const Map<String, String> forgot_password = {
    'email': 'email',
  };

  // send_sms_otp form fields
  static const Map<String, String> send_sms_otp = {
    'phone_code': 'phone_code',
    'phone': 'phone',
  };

  // validate_kyc form fields
  static const Map<String, String> validate_kyc = {
    'phone_number': 'phone_number',
    'otp_code': 'otp_code',
    'id_number': 'id_number',
    'id_photo': 'id_photo',
    'passport_photo': 'passport_photo',
  };

  // get_charges form fields
  static const Map<String, String> get_charges = {
    'amount': 'amount',
    'currency': 'currency',
    'recipient_country': 'recipient_country',
  };

  // send_money form fields
  static const Map<String, String> send_money = {
    'sending_amount': 'sending_amount',
    'recipient_country': 'recipient_country',
    'phone_number': 'phone_number',
  };

  // transaction_status form fields
  static const Map<String, String> transaction_status = {
    'order_tracking_id': 'order_tracking_id',
  };

}
