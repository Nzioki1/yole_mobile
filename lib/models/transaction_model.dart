enum TransactionStatus {
  success,
  pending,
  failed,
  cancelled,
  processing, // added to match screen usage
  delivered,  // added to match screen usage
}

class TransactionModel {
  final String id;
  final double amount;
  final String currency;
  final DateTime date;
  final String counterpart;     // e.g., phone or account identifier
  final String? recipientName;  // optional display name used by history screen
  final TransactionStatus status;

  const TransactionModel({
    required this.id,
    required this.amount,
    required this.currency,
    required this.date,
    required this.counterpart,
    this.recipientName,
    this.status = TransactionStatus.pending,
  });
  String get recipientPhone => counterpart;

  DateTime get timestamp => date;

}
