import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart'; // adjust path if needed

// 🌍 App-wide state
class AppState {
  final String baseCurrency;
  final bool isLoading;
  final Locale locale;
  final String? currentView;
  final bool isDark;

  const AppState({
    this.baseCurrency = 'USD',
    this.isLoading = false,
    this.locale = const Locale('en'),
    this.currentView,
    this.isDark = false,
  });

  AppState copyWith({
    String? baseCurrency,
    bool? isLoading,
    Locale? locale,
    String? currentView,
    bool? isDark,
  }) {
    return AppState(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      isLoading: isLoading ?? this.isLoading,
      locale: locale ?? this.locale,
      currentView: currentView ?? this.currentView,
      isDark: isDark ?? this.isDark,
    );
  }
}

// 🧭 Notifier for app-level controls
class AppNotifier extends StateNotifier<AppState> {
  AppNotifier(this._ref) : super(const AppState());
  final Ref _ref;

  void setCurrency(String code) => state = state.copyWith(baseCurrency: code);
  void setLoading(bool v) => state = state.copyWith(isLoading: v);
  void setLocale(Locale l) => state = state.copyWith(locale: l);
  void setCurrentView(String view) => state = state.copyWith(currentView: view);
  void setDarkMode(bool isDark) => state = state.copyWith(isDark: isDark);

  /// 🔄 Global "reload" that refreshes the transactions list provider
  Future<void> reloadTransactions() async {
    await _ref.refresh(transactionsProvider.future);
  }
}

final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier(ref);
});

/// 💳 Transactions provider — used by TransactionsHistoryScreen
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) async {
  // Simulate network delay. Replace with your repository/service call.
  await Future<void>.delayed(const Duration(milliseconds: 400));

  return [
    TransactionModel(
      id: 'tx_001',
      recipientName: 'Marie Kabila',
      counterpart: '+254700000001',
      amount: -100.0,
      currency: 'USD',
      status: TransactionStatus.success,
      date: DateTime.now(),
    ),
    TransactionModel(
      id: 'tx_002',
      recipientName: 'Joseph Mumba',
      counterpart: 'IBAN •••• 4421',
      amount: -75.5,
      currency: 'EUR',
      status: TransactionStatus.processing,
      date: DateTime.now(),
    ),
    TransactionModel(
      id: 'tx_003',
      recipientName: 'Grace Tshisekedi',
      counterpart: '+243900000003',
      amount: -200.0,
      currency: 'USD',
      status: TransactionStatus.failed,
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
});
