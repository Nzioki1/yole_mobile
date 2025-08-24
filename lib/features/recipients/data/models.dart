class Country {
  final String? name;
  final String? dialCode;
  final String? isoCode;

  const Country({this.name, this.dialCode, this.isoCode});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'],
      dialCode: json['dialCode'],
      isoCode: json['isoCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dialCode': dialCode,
      'isoCode': isoCode,
    };
  }

  @override
  String toString() {
    return '${name ?? ''} (${dialCode ?? ''})';
  }
}

class Recipient {
  final String id;
  final String name;
  final String phoneNumber;
  final String? countryCode;
  final String? account;
  final DateTime? createdAt;

  const Recipient({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.countryCode,
    this.account,
    this.createdAt,
  });

  factory Recipient.fromJson(Map<String, dynamic> json) {
    return Recipient(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      countryCode: json['country_code'],
      account: json['account'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'account': account,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return '$name ($phoneNumber)';
  }
}

class RecipientsResponse {
  final List<Recipient> data;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  const RecipientsResponse({
    required this.data,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  factory RecipientsResponse.fromJson(Map<String, dynamic> json) {
    return RecipientsResponse(
      data: (json['data'] as List?)
          ?.map((e) => Recipient.fromJson(e))
          .toList() ?? [],
      currentPage: json['current_page'] ?? 1,
      totalPages: json['last_page'] ?? 1,
      totalItems: json['total'] ?? 0,
    );
  }
}

class AddRecipientRequest {
  final String name;
  final String phoneNumber;
  final String countryCode;

  const AddRecipientRequest({
    required this.name,
    required this.phoneNumber,
    required this.countryCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'country_code': countryCode,
    };
  }
}