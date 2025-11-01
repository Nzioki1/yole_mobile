import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/transaction_service.dart';
import '../models/api/charges_response.dart';
import '../models/api/send_money_response.dart';
import '../models/api/transaction_status_response.dart';
import '../models/api/transaction.dart';
import 'api_providers.dart';

/// State for charges calculation
class ChargesState {
  final ChargesResponse? charges;
  final bool isLoading;
  final String? error;

  const ChargesState({
    this.charges,
    this.isLoading = false,
    this.error,
  });

  ChargesState copyWith({
    ChargesResponse? charges,
    bool? isLoading,
    String? error,
  }) {
    return ChargesState(
      charges: charges ?? this.charges,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// State for send money operation
class SendMoneyState {
  final SendMoneyResponse? response;
  final bool isLoading;
  final String? error;

  const SendMoneyState({
    this.response,
    this.isLoading = false,
    this.error,
  });

  SendMoneyState copyWith({
    SendMoneyResponse? response,
    bool? isLoading,
    String? error,
  }) {
    return SendMoneyState(
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// State for transaction status
class TransactionStatusState {
  final TransactionStatusResponse? status;
  final bool isLoading;
  final String? error;

  const TransactionStatusState({
    this.status,
    this.isLoading = false,
    this.error,
  });

  TransactionStatusState copyWith({
    TransactionStatusResponse? status,
    bool? isLoading,
    String? error,
  }) {
    return TransactionStatusState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// State for transactions list
class TransactionsState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  const TransactionsState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  TransactionsState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier for charges calculation
class ChargesNotifier extends StateNotifier<ChargesState> {
  final TransactionService _transactionService;

  ChargesNotifier(this._transactionService) : super(const ChargesState());

  Future<void> calculateCharges({
    required double amount,
    required String currency,
    required String recipientCountry,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final charges = await _transactionService.getCharges(
        amount: amount,
        currency: currency,
        recipientCountry: recipientCountry,
      );

      state = state.copyWith(
        charges: charges,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearCharges() {
    state = const ChargesState();
  }
}

/// Notifier for send money operation
class SendMoneyNotifier extends StateNotifier<SendMoneyState> {
  final TransactionService _transactionService;

  SendMoneyNotifier(this._transactionService) : super(const SendMoneyState());

  Future<void> sendMoney({
    required double sendingAmount,
    required String recipientCountry,
    required String phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _transactionService.sendMoney(
        sendingAmount: sendingAmount,
        recipientCountry: recipientCountry,
        phoneNumber: phoneNumber,
      );

      state = state.copyWith(
        response: response,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearSendMoney() {
    state = const SendMoneyState();
  }
}

/// Notifier for transaction status
class TransactionStatusNotifier extends StateNotifier<TransactionStatusState> {
  final TransactionService _transactionService;

  TransactionStatusNotifier(this._transactionService)
      : super(const TransactionStatusState());

  Future<void> checkStatus(String orderTrackingId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final status = await _transactionService.checkStatus(orderTrackingId);

      state = state.copyWith(
        status: status,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearStatus() {
    state = const TransactionStatusState();
  }
}

/// Notifier for transactions list
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionService _transactionService;

  TransactionsNotifier(this._transactionService)
      : super(const TransactionsState());

  Future<void> loadTransactions({
    bool refresh = false,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    if (refresh) {
      state = state.copyWith(
        transactions: [],
        currentPage: 1,
        hasMore: true,
        error: null,
      );
    }

    if (!state.hasMore && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final newTransactions = await _transactionService.getTransactions(
        page: state.currentPage,
        limit: 20,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
      );

      state = state.copyWith(
        transactions: refresh
            ? newTransactions
            : [...state.transactions, ...newTransactions],
        isLoading: false,
        hasMore: newTransactions.length >= 20,
        currentPage: state.currentPage + 1,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshTransactions() async {
    await loadTransactions(refresh: true);
  }

  void clearTransactions() {
    state = const TransactionsState();
  }
}

/// Providers
final chargesProvider =
    StateNotifierProvider<ChargesNotifier, ChargesState>((ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  return ChargesNotifier(transactionService);
});

final sendMoneyProvider =
    StateNotifierProvider<SendMoneyNotifier, SendMoneyState>((ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  return SendMoneyNotifier(transactionService);
});

final transactionStatusProvider =
    StateNotifierProvider<TransactionStatusNotifier, TransactionStatusState>(
        (ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  return TransactionStatusNotifier(transactionService);
});

final transactionsListProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final transactionService = ref.watch(transactionServiceProvider);
  return TransactionsNotifier(transactionService);
});
