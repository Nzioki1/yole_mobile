/// Response model for transaction status API
class TransactionStatusResponse {
  final String orderTrackingId;
  final String status;
  final String? paymentMethod;
  final double? amount;
  final String? currency;
  final DateTime? completedAt;
  final String? failureReason;
  final Map<String, dynamic>? metadata;

  const TransactionStatusResponse({
    required this.orderTrackingId,
    required this.status,
    this.paymentMethod,
    this.amount,
    this.currency,
    this.completedAt,
    this.failureReason,
    this.metadata,
  });

  factory TransactionStatusResponse.fromJson(Map<String, dynamic> json) {
    return TransactionStatusResponse(
      orderTrackingId: json['order_tracking_id'] as String,
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String?,
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      currency: json['currency'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      failureReason: json['failure_reason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_tracking_id': orderTrackingId,
      'status': status,
      'payment_method': paymentMethod,
      'amount': amount,
      'currency': currency,
      'completed_at': completedAt?.toIso8601String(),
      'failure_reason': failureReason,
      'metadata': metadata,
    };
  }

  /// Check if transaction is completed
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// Check if transaction is pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if transaction failed
  bool get isFailed => status.toLowerCase() == 'failed';

  @override
  String toString() {
    return 'TransactionStatusResponse(orderTrackingId: $orderTrackingId, status: $status, amount: $amount, currency: $currency)';
  }
}





