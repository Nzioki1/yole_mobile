/// Payment validation utility for comprehensive data validation
class PaymentValidator {
  /// Validate payment amount
  static String? validateAmount(double? amount) {
    if (amount == null || amount <= 0) {
      return 'Amount must be greater than zero';
    }
    if (amount < 1.0) {
      return 'Minimum amount is \$1.00';
    }
    if (amount > 10000.0) {
      return 'Maximum amount is \$10,000.00';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }
    if (!phone.startsWith('+')) {
      return 'Phone must include country code (e.g., +243...)';
    }
    if (phone.length < 10) {
      return 'Phone number is too short';
    }
    if (phone.length > 20) {
      return 'Phone number is too long';
    }
    // Basic format validation
    if (!RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(phone)) {
      return 'Invalid phone number format';
    }
    return null;
  }

  /// Validate Congo phone number (must start with +243 and have exactly 9 digits after)
  static String? validateCongoPhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }

    // Remove any spaces or formatting
    final cleaned = phone.trim();

    // Check if phone starts with +243
    if (!cleaned.startsWith('+243')) {
      return 'Phone number must start with +243 (Congo country code). Please correct the country code.';
    }

    // Extract digits after +243
    final digitsAfterCode = cleaned.substring(4); // Skip "+243"

    // Check if there are exactly 9 digits
    if (!RegExp(r'^\d{9}$').hasMatch(digitsAfterCode)) {
      if (digitsAfterCode.length < 9) {
        return 'Phone number must have exactly 9 digits after +243. Current: ${digitsAfterCode.length} digits.';
      } else {
        return 'Phone number must have exactly 9 digits after +243. Current: ${digitsAfterCode.length} digits.';
      }
    }

    return null; // Valid
  }

  /// Validate country code
  static String? validateCountry(String? country) {
    if (country == null || country.isEmpty) {
      return 'Country is required';
    }
    if (country.length != 2) {
      return 'Country code must be 2 characters (e.g., KE, CD)';
    }
    return null;
  }

  /// Validate email address
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required for payment processing';
    }
    if (!email.contains('@')) {
      return 'Invalid email address';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      return 'Invalid email format';
    }
    return null;
  }

  /// Validate payment method
  static String? validatePaymentMethod(String? paymentMethod) {
    if (paymentMethod == null || paymentMethod.isEmpty) {
      return 'Payment method is required';
    }
    if (!['mobile_money', 'pesapal'].contains(paymentMethod)) {
      return 'Invalid payment method';
    }
    return null;
  }

  /// Validate recipient name
  static String? validateRecipient(String? recipient) {
    if (recipient == null || recipient.isEmpty) {
      return 'Recipient name is required';
    }
    if (recipient.length < 2) {
      return 'Recipient name is too short';
    }
    if (recipient.length > 100) {
      return 'Recipient name is too long';
    }
    return null;
  }

  /// Comprehensive payment data validation
  static Map<String, String?> validatePaymentData({
    required double? amount,
    required String? phone,
    required String? country,
    required String? email,
    required String? paymentMethod,
    required String? recipient,
  }) {
    return {
      'amount': validateAmount(amount),
      'phone': validatePhone(phone),
      'country': validateCountry(country),
      'email': validateEmail(email),
      'paymentMethod': validatePaymentMethod(paymentMethod),
      'recipient': validateRecipient(recipient),
    };
  }

  /// Check if all validations pass
  static bool isValid(Map<String, String?> validations) {
    return validations.values.every((error) => error == null);
  }

  /// Get first validation error
  static String? getFirstError(Map<String, String?> validations) {
    for (final error in validations.values) {
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  /// Get all validation errors as a list
  static List<String> getAllErrors(Map<String, String?> validations) {
    return validations.values
        .where((error) => error != null)
        .cast<String>()
        .toList();
  }
}



