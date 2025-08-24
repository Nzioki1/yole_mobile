import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/failure.dart';
import '../data/transfer_repository.dart';
import '../data/models.dart';

class TransferState {
  final TransferDraft? draft;
  final Quote? quote;
  final Transfer? transfer;
  final TransferRedirect? redirect;
  final bool loading;
  final Failure? error;
  final bool isSubmitting;

  const TransferState({
    this.draft,
    this.quote,
    this.transfer,
    this.redirect,
    this.loading = false,
    this.error,
    this.isSubmitting = false,
  });

  TransferState copyWith({
    TransferDraft? draft,
    Quote? quote,
    Transfer? transfer,
    TransferRedirect? redirect,
    bool? loading,
    Failure? error,
    bool? isSubmitting,
  }) =>
      TransferState(
        draft: draft ?? this.draft,
        quote: quote ?? this.quote,
        transfer: transfer ?? this.transfer,
        redirect: redirect ?? this.redirect,
        loading: loading ?? this.loading,
        error: error,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

class TransferNotifier extends StateNotifier<TransferState> {
  final TransferRepository repo;
  
  TransferNotifier(this.repo) : super(const TransferState());

  void _trackEvent(String event, {Map<String, dynamic>? params}) {
    // TODO: Implement analytics tracking
    // Analytics.track(event, properties: params);
    print('Analytics: $event ${params ?? {}}');
  }

  void createDraft(String recipientId, double amount, {
    String currency = 'USD',
    String recipientCountry = 'CD',
    String phoneNumber = '',
  }) {
    final draft = TransferDraft(
      recipientId: recipientId,
      amount: amount,
      currency: currency,
      recipientCountry: recipientCountry,
      phoneNumber: phoneNumber,
    );
    
    state = state.copyWith(draft: draft);
    _trackEvent('transfer_draft_created', params: {
      'recipient_id': recipientId,
      'amount': amount,
      'currency': currency,
    });
  }

  Future<void> getQuote(String amount, String currency, String recipientCountry) async {
    if (state.draft == null) return;

    state = state.copyWith(loading: true, error: null);
    _trackEvent('transfer_quote_requested', params: {
      'amount': amount,
      'currency': currency,
      'recipient_country': recipientCountry,
    });

    try {
      final quote = await repo.quoteTransfer(amount, currency, recipientCountry);
      
      final updatedDraft = state.draft!.copyWith(quote: quote);
      
      state = state.copyWith(
        draft: updatedDraft,
        quote: quote,
        loading: false,
      );
      
      _trackEvent('transfer_quote_received', params: {
        'amount': quote.amount,
        'charges': quote.charges,
        'total_cost': quote.totalCost,
      });
    } on Failure catch (e) {
      state = state.copyWith(error: e, loading: false);
      _trackEvent('transfer_quote_failed', params: {
        'error': e.message,
      });
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        loading: false,
      );
      _trackEvent('transfer_quote_failed', params: {
        'error': e.toString(),
      });
    }
  }

  Future<void> createTransfer() async {
    if (state.draft == null) return;

    state = state.copyWith(isSubmitting: true, error: null);
    _trackEvent('transfer_submit_started', params: {
      'amount': state.draft!.amount,
      'recipient_id': state.draft!.recipientId,
    });

    try {
      final redirect = await repo.createTransfer(
        state.draft!.amount.toString(),
        state.draft!.recipientCountry,
        state.draft!.phoneNumber,
      );
      
      state = state.copyWith(
        redirect: redirect,
        isSubmitting: false,
      );
      
      _trackEvent('transfer_submit_success', params: {
        'order_tracking_id': redirect.orderTrackingId,
      });
    } on Failure catch (e) {
      state = state.copyWith(error: e, isSubmitting: false);
      _trackEvent('transfer_submit_failed', params: {
        'error': e.message,
      });
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        isSubmitting: false,
      );
      _trackEvent('transfer_submit_failed', params: {
        'error': e.toString(),
      });
    }
  }

  Future<void> confirmTransfer(String orderTrackingId) async {
    state = state.copyWith(loading: true, error: null);
    _trackEvent('transfer_confirm_started', params: {
      'order_tracking_id': orderTrackingId,
    });

    try {
      final transfer = await repo.confirmTransfer(orderTrackingId);
      
      state = state.copyWith(
        transfer: transfer,
        loading: false,
      );
      
      _trackEvent('transfer_confirm_success', params: {
        'transfer_id': transfer.id,
        'status': transfer.status,
      });
    } on Failure catch (e) {
      state = state.copyWith(error: e, loading: false);
      _trackEvent('transfer_confirm_failed', params: {
        'error': e.message,
      });
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        loading: false,
      );
      _trackEvent('transfer_confirm_failed', params: {
        'error': e.toString(),
      });
    }
  }

  Future<String> getTransactionStatus(String orderTrackingId) async {
    try {
      final status = await repo.transactionStatus(orderTrackingId);
      _trackEvent('transfer_status_checked', params: {
        'order_tracking_id': orderTrackingId,
        'status': status,
      });
      return status;
    } on Failure catch (e) {
      _trackEvent('transfer_status_failed', params: {
        'error': e.message,
      });
      rethrow;
    } catch (e) {
      _trackEvent('transfer_status_failed', params: {
        'error': e.toString(),
      });
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void reset() {
    state = const TransferState();
  }
}

final transferProvider = StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  throw UnimplementedError('Provide TransferRepository via override at app start');
});

final transferDraftProvider = Provider<TransferDraft?>((ref) {
  return ref.watch(transferProvider).draft;
});

final transferQuoteProvider = Provider<Quote?>((ref) {
  return ref.watch(transferProvider).quote;
});

final transferRedirectProvider = Provider<TransferRedirect?>((ref) {
  return ref.watch(transferProvider).redirect;
});