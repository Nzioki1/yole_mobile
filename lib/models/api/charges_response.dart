/// Response model for charges calculation API
class ChargesResponse {
  final double feeAmount;
  final String feeCurrency;
  final double totalAmount;
  final String feeType;
  final Map<String, dynamic>? breakdown;

  const ChargesResponse({
    required this.feeAmount,
    required this.feeCurrency,
    required this.totalAmount,
    required this.feeType,
    this.breakdown,
  });

  factory ChargesResponse.fromJson(Map<String, dynamic> json) {
    return ChargesResponse(
      feeAmount: (json['fee_amount'] as num?)?.toDouble() ?? 0.0,
      feeCurrency: json['fee_currency'] as String? ?? 'USD',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      feeType: json['fee_type'] as String? ?? 'fixed',
      breakdown: json['breakdown'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fee_amount': feeAmount,
      'fee_currency': feeCurrency,
      'total_amount': totalAmount,
      'fee_type': feeType,
      'breakdown': breakdown,
    };
  }

  @override
  String toString() {
    return 'ChargesResponse(feeAmount: $feeAmount, feeCurrency: $feeCurrency, totalAmount: $totalAmount, feeType: $feeType)';
  }
}
