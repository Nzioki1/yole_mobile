import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transfer_repository.dart';
import '../data/models.dart';

class TransferState {
  final TransferDraft? draft;
  final String? confirmationId;
  final bool loading;
  TransferState({this.draft, this.confirmationId, this.loading = false});

  TransferState copyWith({TransferDraft? draft, String? confirmationId, bool? loading}) =>
      TransferState(draft: draft ?? this.draft, confirmationId: confirmationId ?? this.confirmationId, loading: loading ?? this.loading);
}

class TransferNotifier extends StateNotifier<TransferState> {
  final TransferRepository repo;
  TransferNotifier(this.repo) : super(TransferState());

  void setDraft(TransferDraft draft) => state = state.copyWith(draft: draft);

  Future<void> confirm() async {
    if (state.draft == null) return;
    state = state.copyWith(loading: true);
    final id = await repo.create(state.draft!);
    state = state.copyWith(confirmationId: id, loading: false);
  }
}

final transferProvider = StateNotifierProvider<TransferNotifier, TransferState>((ref) {
  return TransferNotifier(TransferRepository());
});