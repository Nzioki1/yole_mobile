import 'dart:convert';

/// Biometric unlock payload stored in secure storage
class BiometricUnlockPayload {
  final String email;
  final String password;
  final String transactionPin;

  const BiometricUnlockPayload({
    required this.email,
    required this.password,
    required this.transactionPin,
  });

  /// Create from JSON map
  factory BiometricUnlockPayload.fromJson(Map<String, dynamic> json) {
    return BiometricUnlockPayload(
      email: json['email'] as String,
      password: json['password'] as String,
      transactionPin: json['transactionPin'] as String,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'transactionPin': transactionPin,
    };
  }

  /// Parse from JSON string
  static BiometricUnlockPayload? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return BiometricUnlockPayload.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Encode to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }
}
