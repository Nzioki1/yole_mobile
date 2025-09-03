enum KycStatus { kycVerified, kycPending }

class User {
  final String id;
  final String email;
  final KycStatus kycStatus;

  const User({
    required this.id,
    required this.email,
    this.kycStatus = KycStatus.kycPending,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      kycStatus: json['kyc_submitted'] == 0 || json['kyc_validated'] == 0
          ? KycStatus.kycPending
          : KycStatus.kycVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'kyc_submitted': kycStatus == KycStatus.kycPending ? 0 : 1,
      'kyc_validated': kycStatus == KycStatus.kycPending ? 0 : 1,
    };
  }
}

class AuthToken {
  final String value;
  final String? expiration;
  final String? refreshToken;

  const AuthToken(this.value, {this.expiration, this.refreshToken});

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      json['access_token'] ?? '',
      expiration: json['expires_in']?.toString(),
      refreshToken: json['refresh_token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': value,
      'refresh_token': refreshToken,
      'expires_in': expiration,
    };
  }
}

class ValidateKycRequest {
  final String phoneNumber;
  final String otpCode;
  final String idNumber;
  final String? idPhoto;
  final String? passportPhoto;

  const ValidateKycRequest({
    required this.phoneNumber,
    required this.otpCode,
    required this.idNumber,
    this.idPhoto,
    this.passportPhoto,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'phone_number': phoneNumber,
      'otp_code': otpCode,
      'id_number': idNumber,
    };

    if (idPhoto != null) {
      data['id_photo'] = idPhoto;
    }

    if (passportPhoto != null) {
      data['passport_photo'] = passportPhoto;
    }

    return data;
  }
}

class SendSmsOtpRequest {
  final String phoneCode;
  final String phone;

  const SendSmsOtpRequest({required this.phoneCode, required this.phone});

  Map<String, dynamic> toJson() {
    return {'phone_code': phoneCode, 'phone': phone};
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String name;
  final String phoneNumber;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'phone_number': phoneNumber,
    };
  }
}
