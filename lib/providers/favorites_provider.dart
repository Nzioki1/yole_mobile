import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple model for a favorite contact.
class FavoriteContact {
  const FavoriteContact({required this.id, required this.label, required this.initials});
  final String id;
  final String label;
  final String initials;
}

/// Riverpod controller (in-memory). Swap to persistence when ready.
class FavoritesController extends StateNotifier<List<FavoriteContact>> {
  FavoritesController()
      : super(const [
          FavoriteContact(id: '1', label: 'Marie', initials: 'MK'),
          FavoriteContact(id: '2', label: 'Joseph', initials: 'JM'),
          FavoriteContact(id: '3', label: 'Grace', initials: 'GT'),
        ]);

  void add(FavoriteContact c) => state = [...state, c];
  void remove(String id) => state = state.where((c) => c.id != id).toList();

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesController, List<FavoriteContact>>((ref) {
  return FavoritesController();
});
