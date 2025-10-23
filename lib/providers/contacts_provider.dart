import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// Holds a cached, lightweight list of contacts (names only).
class ContactsRepo extends StateNotifier<AsyncValue<List<Contact>>> {
  ContactsRepo() : super(const AsyncValue.loading());

  /// Loads a lightweight list (names only). No plugin-side query in 1.1.9+2.
  Future<void> loadLite() async {
    try {
      state = const AsyncValue.loading();
      final list = await FlutterContacts.getContacts(
        withProperties: false, // FAST
        withPhoto: false,
      );
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Fetch full contact when needed (on selection).
  Future<Contact?> getFull(String id) {
    return FlutterContacts.getContact(id, withProperties: true);
  }
}

final contactsRepoProvider =
    StateNotifierProvider<ContactsRepo, AsyncValue<List<Contact>>>(
  (ref) => ContactsRepo(),
);
