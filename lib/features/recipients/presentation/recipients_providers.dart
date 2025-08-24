import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/failure.dart';
import '../data/recipients_repository.dart';
import '../data/models.dart';

class RecipientsState {
  final List<Recipient> recipients;
  final List<Country> countries;
  final Recipient? selectedRecipient;
  final bool loading;
  final Failure? error;
  final int currentPage;
  final bool hasMorePages;
  final String? searchQuery;

  const RecipientsState({
    this.recipients = const [],
    this.countries = const [],
    this.selectedRecipient,
    this.loading = false,
    this.error,
    this.currentPage = 1,
    this.hasMorePages = false,
    this.searchQuery,
  });

  RecipientsState copyWith({
    List<Recipient>? recipients,
    List<Country>? countries,
    Recipient? selectedRecipient,
    bool? loading,
    Failure? error,
    int? currentPage,
    bool? hasMorePages,
    String? searchQuery,
  }) =>
      RecipientsState(
        recipients: recipients ?? this.recipients,
        countries: countries ?? this.countries,
        selectedRecipient: selectedRecipient ?? this.selectedRecipient,
        loading: loading ?? this.loading,
        error: error,
        currentPage: currentPage ?? this.currentPage,
        hasMorePages: hasMorePages ?? this.hasMorePages,
        searchQuery: searchQuery ?? this.searchQuery,
      );
}

class RecipientsNotifier extends StateNotifier<RecipientsState> {
  final RecipientsRepository repo;
  
  RecipientsNotifier(this.repo) : super(const RecipientsState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      fetchRecipients(),
      fetchCountries(),
    ]);
  }

  Future<void> fetchRecipients({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(loading: true, error: null, currentPage: 1);
    } else {
      state = state.copyWith(loading: true, error: null);
    }

    try {
      final response = await repo.fetchRecipients(
        page: refresh ? 1 : state.currentPage,
        query: state.searchQuery,
      );

      final newRecipients = refresh 
          ? response.data 
          : [...state.recipients, ...response.data];

      state = state.copyWith(
        recipients: newRecipients,
        loading: false,
        currentPage: response.currentPage,
        hasMorePages: response.currentPage < response.totalPages,
      );
    } on Failure catch (e) {
      state = state.copyWith(error: e, loading: false);
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        loading: false,
      );
    }
  }

  Future<void> fetchCountries() async {
    try {
      final countries = await repo.fetchCountries();
      state = state.copyWith(countries: countries);
    } on Failure catch (e) {
      // Don't fail the entire state for countries loading
      state = state.copyWith(error: e);
    } catch (e) {
      // Don't fail the entire state for countries loading
      state = state.copyWith(error: UnknownFailure(e.toString()));
    }
  }

  Future<void> addRecipient(String name, String phoneNumber, String countryCode) async {
    state = state.copyWith(loading: true, error: null);
    
    try {
      final newRecipient = await repo.addRecipient(name, phoneNumber, countryCode);
      final updatedRecipients = [newRecipient, ...state.recipients];
      
      state = state.copyWith(
        recipients: updatedRecipients,
        loading: false,
      );
    } on Failure catch (e) {
      state = state.copyWith(error: e, loading: false);
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        loading: false,
      );
    }
  }

  void selectRecipient(Recipient recipient) {
    state = state.copyWith(selectedRecipient: recipient);
  }

  void clearSelection() {
    state = state.copyWith(selectedRecipient: null);
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void loadMoreRecipients() {
    if (!state.loading && state.hasMorePages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      fetchRecipients();
    }
  }
}

final recipientsProvider = StateNotifierProvider<RecipientsNotifier, RecipientsState>((ref) {
  throw UnimplementedError('Provide RecipientsRepository via override at app start');
});

final selectedRecipientProvider = Provider<Recipient?>((ref) {
  return ref.watch(recipientsProvider).selectedRecipient;
});