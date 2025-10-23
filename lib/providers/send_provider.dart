import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipient_model.dart';
import '../models/transaction_model.dart';

enum SendStep { enterDetails, reviewFees, paymentMethod, pspCheckout, result }

class SendState {
  final SendStep step;
  final RecipientModel? selectedRecipient;
  final double amount;
  final String currency;
  final TransactionStatus transactionStatus;

  const SendState({
    this.step = SendStep.enterDetails,
    this.selectedRecipient,
    this.amount = 0.0,
    this.currency = 'USD',
    this.transactionStatus = TransactionStatus.pending,
  });

  SendState copyWith({
    SendStep? step,
    RecipientModel? selectedRecipient,
    double? amount,
    String? currency,
    TransactionStatus? transactionStatus,
  }) {
    return SendState(
      step: step ?? this.step,
      selectedRecipient: selectedRecipient ?? this.selectedRecipient,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      transactionStatus: transactionStatus ?? this.transactionStatus,
    );
  }
}

class SendNotifier extends StateNotifier<SendState> {
  SendNotifier() : super(const SendState());

  void setStep(SendStep step) => state = state.copyWith(step: step);
  void setRecipient(RecipientModel r) => state = state.copyWith(selectedRecipient: r);
  void setAmount(double a) => state = state.copyWith(amount: a);
  void setCurrency(String c) => state = state.copyWith(currency: c);
  void setStatus(TransactionStatus s) => state = state.copyWith(transactionStatus: s);
}

final sendProvider = StateNotifierProvider<SendNotifier, SendState>((ref) {
  return SendNotifier();
});
