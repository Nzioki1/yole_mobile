/// Response model for authentication APIs
class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserProfile user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int? ?? 3600,
      user: json['user'] != null
          ? UserProfile.fromJson(json['user'] as Map<String, dynamic>)
          : _createDefaultUser(json),
    );
  }

  static UserProfile _createDefaultUser(Map<String, dynamic> json) {
    // Create a default user profile when API doesn't return user data
    // This happens in the login response
    return UserProfile(
      id: '0',
      email: '',
      name: '',
      surname: '',
      country: '',
      phone: null,
      avatar: null,
      isEmailVerified: false,
      isPhoneVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }

  /// Check if token is expired
  bool get isExpired {
    // Assuming token was issued at creation time
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
    return DateTime.now().isAfter(expiryTime);
  }

  @override
  String toString() {
    return 'AuthResponse(accessToken: ${accessToken.substring(0, 10)}..., tokenType: $tokenType, expiresIn: $expiresIn)';
  }
}

/// User profile model for authentication
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String surname;
  final String country;
  final String? phone;
  final String? avatar;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.surname,
    required this.country,
    this.phone,
    this.avatar,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? json['sub']?.toString() ?? '0',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      country: json['country'] as String? ?? '',
      phone: json['phone'] as String? ?? json['phone_number'] as String?,
      avatar: json['avatar'] as String?,
      isEmailVerified: json['is_email_verified'] as bool? ??
          (json['email_verified_at'] != null),
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'surname': surname,
      'country': country,
      'phone': phone,
      'avatar': avatar,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$name $surname';

  /// Check if user data is valid (not default empty user)
  bool get isValid {
    // Check if user has meaningful data (not the default empty user)
    return id != '0' && 
           email.isNotEmpty && 
           (name.isNotEmpty || surname.isNotEmpty);
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, fullName: $fullName)';
  }
}
