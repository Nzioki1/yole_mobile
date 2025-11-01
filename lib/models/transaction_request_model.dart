/// Transaction request model for send money flow
class TransactionRequest {
  final double amount;
  final String currency;
  final String recipient;
  final String? recipientPhone;
  final String? recipientCountry;
  final String? note;
  final double feeAmount;
  final double totalAmount;
  final String paymentMethod;

  const TransactionRequest({
    required this.amount,
    required this.currency,
    required this.recipient,
    this.recipientPhone,
    this.recipientCountry,
    this.note,
    required this.feeAmount,
    required this.totalAmount,
    required this.paymentMethod,
  });

  /// Create from arguments map (from navigation)
  factory TransactionRequest.fromArguments(Map<String, dynamic> args) {
    return TransactionRequest(
      amount: args['amount'] as double,
      currency: args['currency'] as String,
      recipient: args['recipient'] as String,
      recipientPhone: args['recipientPhone'] as String?,
      recipientCountry: args['recipientCountry'] as String?,
      note: args['note'] as String?,
      feeAmount: args['feeAmount'] as double? ?? 0.0,
      totalAmount: args['totalAmount'] as double? ?? args['amount'] as double,
      paymentMethod: args['paymentMethod'] as String? ?? 'pesapal',
    );
  }

  /// Convert to arguments map (for navigation)
  Map<String, dynamic> toArguments() {
    return {
      'amount': amount,
      'currency': currency,
      'recipient': recipient,
      'recipientPhone': recipientPhone,
      'recipientCountry': recipientCountry,
      'note': note,
      'feeAmount': feeAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
    };
  }

  /// Create a copy with updated values
  TransactionRequest copyWith({
    double? amount,
    String? currency,
    String? recipient,
    String? recipientPhone,
    String? recipientCountry,
    String? note,
    double? feeAmount,
    double? totalAmount,
    String? paymentMethod,
  }) {
    return TransactionRequest(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      recipient: recipient ?? this.recipient,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      recipientCountry: recipientCountry ?? this.recipientCountry,
      note: note ?? this.note,
      feeAmount: feeAmount ?? this.feeAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  @override
  String toString() {
    return 'TransactionRequest(amount: $amount, currency: $currency, recipient: $recipient, totalAmount: $totalAmount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionRequest &&
        other.amount == amount &&
        other.currency == currency &&
        other.recipient == recipient &&
        other.recipientPhone == recipientPhone &&
        other.recipientCountry == recipientCountry &&
        other.note == note &&
        other.feeAmount == feeAmount &&
        other.totalAmount == totalAmount &&
        other.paymentMethod == paymentMethod;
  }

  @override
  int get hashCode {
    return Object.hash(
      amount,
      currency,
      recipient,
      recipientPhone,
      recipientCountry,
      note,
      feeAmount,
      totalAmount,
      paymentMethod,
    );
  }
}

/// PesaPal API response models
class PesaPalOrderResponse {
  final String orderTrackingId;
  final String merchantReference;
  final String redirectUrl;
  final String status;

  const PesaPalOrderResponse({
    required this.orderTrackingId,
    required this.merchantReference,
    required this.redirectUrl,
    required this.status,
  });

  factory PesaPalOrderResponse.fromJson(Map<String, dynamic> json) {
    return PesaPalOrderResponse(
      orderTrackingId: json['order_tracking_id'] as String,
      merchantReference: json['merchant_reference'] as String,
      redirectUrl: json['redirect_url'] as String,
      status: json['status'] as String,
    );
  }
}

class PesaPalTransactionStatus {
  final String orderTrackingId;
  final String merchantReference;
  final String status;
  final String? paymentMethod;
  final String? paymentAccount;
  final String? currency;
  final double? amount;
  final String? description;
  final String? message;
  final DateTime? createdDate;

  const PesaPalTransactionStatus({
    required this.orderTrackingId,
    required this.merchantReference,
    required this.status,
    this.paymentMethod,
    this.paymentAccount,
    this.currency,
    this.amount,
    this.description,
    this.message,
    this.createdDate,
  });

  factory PesaPalTransactionStatus.fromJson(Map<String, dynamic> json) {
    return PesaPalTransactionStatus(
      orderTrackingId: json['order_tracking_id'] as String,
      merchantReference: json['merchant_reference'] as String,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
      paymentAccount: json['payment_account'] as String?,
      currency: json['currency'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      description: json['description'] as String?,
      message: json['message'] as String?,
      createdDate: json['created_date'] != null
          ? DateTime.parse(json['created_date'] as String)
          : null,
    );
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
  bool get isInvalid => status == 'INVALID';
}

