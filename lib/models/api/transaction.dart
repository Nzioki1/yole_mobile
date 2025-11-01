/// Transaction model for API responses
class Transaction {
  final String id;
  final String reference;
  final String status;
  final double amount;
  final String currency;
  final String recipientPhone;
  final String? recipientName;
  final String? recipientCountry;
  final String? note;
  final double? feeAmount;
  final String? feeCurrency;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.reference,
    required this.status,
    required this.amount,
    required this.currency,
    required this.recipientPhone,
    this.recipientName,
    this.recipientCountry,
    this.note,
    this.feeAmount,
    this.feeCurrency,
    this.paymentMethod,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      reference: json['reference'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      recipientPhone: json['recipient_phone'] as String,
      recipientName: json['recipient_name'] as String?,
      recipientCountry: json['recipient_country'] as String?,
      note: json['note'] as String?,
      feeAmount: json['fee_amount'] != null
          ? (json['fee_amount'] as num).toDouble()
          : null,
      feeCurrency: json['fee_currency'] as String?,
      paymentMethod: json['payment_method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'status': status,
      'amount': amount,
      'currency': currency,
      'recipient_phone': recipientPhone,
      'recipient_name': recipientName,
      'recipient_country': recipientCountry,
      'note': note,
      'fee_amount': feeAmount,
      'fee_currency': feeCurrency,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Check if transaction is completed
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// Check if transaction is pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if transaction failed
  bool get isFailed => status.toLowerCase() == 'failed';

  /// Check if transaction is cancelled
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Get formatted amount with currency
  String get formattedAmount =>
      '${currency == 'USD' ? '\$' : '€'}${amount.toStringAsFixed(2)} $currency';

  /// Get formatted fee amount
  String? get formattedFeeAmount {
    if (feeAmount == null || feeCurrency == null) return null;
    return '${feeCurrency == 'USD' ? '\$' : '€'}${feeAmount!.toStringAsFixed(2)} $feeCurrency';
  }

  @override
  String toString() {
    return 'Transaction(id: $id, reference: $reference, status: $status, amount: $amount, currency: $currency)';
  }
}





