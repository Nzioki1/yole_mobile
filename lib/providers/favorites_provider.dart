import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple model for a favorite contact.
class FavoriteContact {
  const FavoriteContact({
    required this.id,
    required this.label,
    required this.initials,
    this.phones = const [],
    this.countryCode,
  });

  final String id;
  final String label;
  final String initials;
  final List<String> phones; // All phone numbers for this contact
  final String? countryCode; // ISO country code, e.g. 'KE', 'UG'
}

/// Riverpod controller (in-memory). Swap to persistence when ready.
class FavoritesController extends StateNotifier<List<FavoriteContact>> {
  FavoritesController()
      : super(const [
          FavoriteContact(
            id: '1',
            label: 'Jean-Paul Kabila',
            initials: 'JP',
            phones: ['+243990123456'],
            countryCode: 'CD',
          ),
          FavoriteContact(
            id: '2',
            label: 'Marie Tshala',
            initials: 'MT',
            phones: ['+243991234567'],
            countryCode: 'CD',
          ),
          FavoriteContact(
            id: '3',
            label: 'Amina Payroll',
            initials: 'AP',
            phones: ['+243990000002'],
            countryCode: 'CD',
          ),
        ]);

  void add(FavoriteContact c) => state = [...state, c];
  void remove(String id) => state = state.where((c) => c.id != id).toList();

  void update(String id, FavoriteContact updated) {
    state = state.map((contact) {
      return contact.id == id ? updated : contact;
    }).toList();
  }

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
