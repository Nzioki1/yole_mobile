class Quote {
  final double amount;
  final String currency;
  final double charges;
  final double totalCost;
  final String recipientCountry;
  final double exchangeRate;

  const Quote({
    required this.amount,
    required this.currency,
    required this.charges,
    required this.totalCost,
    required this.recipientCountry,
    required this.exchangeRate,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      charges: (json['charges'] ?? 0).toDouble(),
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      recipientCountry: json['recipient_country'] ?? '',
      exchangeRate: (json['exchange_rate'] ?? 1).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'charges': charges,
      'total_cost': totalCost,
      'recipient_country': recipientCountry,
      'exchange_rate': exchangeRate,
    };
  }
}

class TransferDraft {
  final String recipientId;
  final double amount;
  final String currency;
  final String recipientCountry;
  final String phoneNumber;
  final Quote? quote;

  const TransferDraft({
    required this.recipientId,
    required this.amount,
    this.currency = 'USD',
    this.recipientCountry = 'CD',
    this.phoneNumber = '',
    this.quote,
  });

  Map<String, dynamic> toJson() {
    return {
      'sending_amount': amount.toString(),
      'recipient_country': recipientCountry,
      'phone_number': phoneNumber,
      'currency': currency,
    };
  }

  TransferDraft copyWith({
    String? recipientId,
    double? amount,
    String? currency,
    String? recipientCountry,
    String? phoneNumber,
    Quote? quote,
  }) {
    return TransferDraft(
      recipientId: recipientId ?? this.recipientId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      recipientCountry: recipientCountry ?? this.recipientCountry,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      quote: quote ?? this.quote,
    );
  }
}

class Transfer {
  final String id;
  final String orderTrackingId;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final String recipientPhone;
  final String recipientCountry;

  const Transfer({
    required this.id,
    required this.orderTrackingId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.recipientPhone,
    required this.recipientCountry,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      id: json['id']?.toString() ?? '',
      orderTrackingId: json['order_tracking_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      recipientPhone: json['recipient_phone'] ?? '',
      recipientCountry: json['recipient_country'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_tracking_id': orderTrackingId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'recipient_phone': recipientPhone,
      'recipient_country': recipientCountry,
    };
  }
}

class TransferRedirect {
  final String orderTrackingId;
  final String redirectUrl;

  const TransferRedirect({
    required this.orderTrackingId,
    required this.redirectUrl,
  });

  factory TransferRedirect.fromJson(Map<String, dynamic> json) {
    return TransferRedirect(
      orderTrackingId: json['order_tracking_id'] ?? '',
      redirectUrl: json['redirect_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_tracking_id': orderTrackingId,
      'redirect_url': redirectUrl,
    };
  }
}

class Transaction {
  final String recipient;
  final String currency;
  final double amount;
  final String status;
  final DateTime date;
  final TransactionSender? sender;

  const Transaction({
    required this.recipient,
    required this.currency,
    required this.amount,
    required this.status,
    required this.date,
    this.sender,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      recipient: json['recipient'] ?? '',
      currency: json['currency'] ?? 'USD',
      amount: json['amount'] is int 
          ? (json['amount'] as int).toDouble()
          : (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      sender: json['sender'] != null 
          ? TransactionSender.fromJson(json['sender']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipient': recipient,
      'currency': currency,
      'amount': amount,
      'status': status,
      'date': date.toIso8601String(),
      'sender': sender?.toJson(),
    };
  }
}

class TransactionSender {
  final String name;
  final String phoneNumber;

  const TransactionSender({
    required this.name,
    required this.phoneNumber,
  });

  factory TransactionSender.fromJson(Map<String, dynamic> json) {
    return TransactionSender(
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
    };
  }
}

class TransferRequest {
  final String sendingAmount;
  final String recipientCountry;
  final String phoneNumber;

  const TransferRequest({
    required this.sendingAmount,
    required this.recipientCountry,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'sending_amount': sendingAmount,
      'recipient_country': recipientCountry,
      'phone_number': phoneNumber,
    };
  }
}

class QuoteRequest {
  final String amount;
  final String currency;
  final String recipientCountry;

  const QuoteRequest({
    required this.amount,
    this.currency = 'USD',
    this.recipientCountry = 'CD',
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'recipient_country': recipientCountry,
    };
  }
}

class TransactionStatusRequest {
  final String orderTrackingId;

  const TransactionStatusRequest({required this.orderTrackingId});

  Map<String, dynamic> toJson() {
    return {
      'order_tracking_id': orderTrackingId,
    };
  }
}