enum KycStatus {
  kycVerified,
  kycPending,
}

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
  
  const AuthToken(this.value, {this.expiration});

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      json['access_token'] ?? '',
      expiration: json['expires_in']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': value,
      'expires_in': expiration,
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
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