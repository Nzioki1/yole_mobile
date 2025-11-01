/// Response model for send money API
class SendMoneyResponse {
  final String transactionId;
  final String reference;
  final String status;
  final double amount;
  final String currency;
  final String recipientPhone;
  final String? recipientCountry;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SendMoneyResponse({
    required this.transactionId,
    required this.reference,
    required this.status,
    required this.amount,
    required this.currency,
    required this.recipientPhone,
    this.recipientCountry,
    required this.createdAt,
    this.updatedAt,
  });

  factory SendMoneyResponse.fromJson(Map<String, dynamic> json) {
    return SendMoneyResponse(
      transactionId: json['transaction_id'] as String,
      reference: json['reference'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      recipientPhone: json['recipient_phone'] as String,
      recipientCountry: json['recipient_country'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'reference': reference,
      'status': status,
      'amount': amount,
      'currency': currency,
      'recipient_phone': recipientPhone,
      'recipient_country': recipientCountry,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SendMoneyResponse(transactionId: $transactionId, reference: $reference, status: $status, amount: $amount, currency: $currency)';
  }
}





