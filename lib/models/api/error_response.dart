/// Error response model for API errors
class ErrorResponse {
  final String message;
  final int? code;
  final Map<String, dynamic>? errors;
  final String? type;
  final DateTime? timestamp;

  const ErrorResponse({
    required this.message,
    this.code,
    this.errors,
    this.type,
    this.timestamp,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      message: json['message'] as String,
      code: json['code'] as int?,
      errors: json['errors'] as Map<String, dynamic>?,
      type: json['type'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'code': code,
      'errors': errors,
      'type': type,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  /// Get formatted error message
  String get formattedMessage {
    if (errors != null && errors!.isNotEmpty) {
      final errorList = <String>[];
      errors!.forEach((key, value) {
        if (value is List) {
          errorList.addAll(value.cast<String>());
        } else if (value is String) {
          errorList.add(value);
        }
      });
      if (errorList.isNotEmpty) {
        return errorList.join(', ');
      }
    }
    return message;
  }

  /// Check if error is validation error
  bool get isValidationError => type == 'validation_error' || errors != null;

  /// Check if error is authentication error
  bool get isAuthError => code == 401 || type == 'authentication_error';

  /// Check if error is authorization error
  bool get isAuthorizationError => code == 403 || type == 'authorization_error';

  @override
  String toString() {
    return 'ErrorResponse(message: $message, code: $code, type: $type)';
  }
}





