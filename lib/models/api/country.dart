/// Country model for API responses
class Country {
  final String code;
  final String name;
  final String? flag;
  final String? currency;
  final String? currencySymbol;
  final bool isActive;

  const Country({
    required this.code,
    required this.name,
    this.flag,
    this.currency,
    this.currencySymbol,
    this.isActive = true,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      // API returns 'isoCode' but we want it as 'code'
      code: (json['code'] ?? json['isoCode'] ?? json['iso_code']) as String,
      name: json['name'] as String,
      flag: json['flag'] as String?,
      currency: json['currency'] as String?,
      currencySymbol:
          json['currency_symbol'] ?? json['currencySymbol'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'flag': flag,
      'currency': currency,
      'currency_symbol': currencySymbol,
      'is_active': isActive,
    };
  }

  /// Get display name with flag
  String get displayName {
    if (flag != null) {
      return '$flag $name';
    }
    return name;
  }

  @override
  String toString() {
    return 'Country(code: $code, name: $name, currency: $currency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}
