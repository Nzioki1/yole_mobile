import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../providers/favorites_provider.dart';
import '../providers/contacts_provider.dart';
import '../utils/contacts_permission.dart';
import '../l10n/app_localizations.dart';
// import '../router_types.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ok = await ensureContactsPermission(context);
      if (!mounted || !ok) return;
      await ref.read(contactsRepoProvider.notifier).loadLite();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        toolbarHeight: 64,
        title: Text(
          l10n.favorites,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AppBarPillButton(
              label: 'Add from Contacts',
              icon: Icons.lock_open_rounded,
              onTap: _onAddFromContacts,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No favorites yet',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                )
              : ReorderableListView(
                  proxyDecorator: (child, index, animation) =>
                      Material(color: Colors.transparent, child: child),
                  onReorder: (oldIndex, newIndex) {
                    notifier.reorder(oldIndex, newIndex);
                  },
                  children: [
                    for (final c in items)
                      _FavTile(
                        key: ValueKey(c.id),
                        contact: c,
                        onSend: () async {
                          // Multiple numbers → let user pick
                          if (c.phones.length > 1) {
                            final selectedPhone =
                                await _showPhoneSelector(context, c.phones);
                            if (selectedPhone != null && context.mounted) {
                              Navigator.of(context).pop({
                                'recipient': c.label,
                                'recipientPhone': selectedPhone,
                                'recipientCountry': c.countryCode,
                              });
                            }
                          } else if (c.phones.isNotEmpty) {
                            // Single number → return directly
                            Navigator.of(context).pop({
                              'recipient': c.label,
                              'recipientPhone': c.phones.first,
                              'recipientCountry': c.countryCode,
                            });
                          } else {
                            // No stored numbers
                            final l10n = AppLocalizations.of(context)!;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.noPhoneNumber)),
                            );
                          }
                        },
                        onDelete: () => notifier.remove(c.id),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<String?> _showPhoneSelector(
      BuildContext context, List<String> phones) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectPhoneNumber),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: phones
              .map((phone) => ListTile(
                    title: Text(phone),
                    onTap: () => Navigator.pop(context, phone),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _onAddFromContacts() async {
    if (!await ensureContactsPermission(context)) return;

    final picked = await showModalBottomSheet<_PickedContact>(
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      context: context,
      builder: (ctx) => _FastContactPicker(ref: ref),
    );

    if (!mounted || picked == null) return;

    // Extract phone numbers from picked contact
    final phoneNumbers = picked.phones
        .map((p) => p.number)
        .where((n) => n.trim().isNotEmpty)
        .toList();

    ref.read(favoritesProvider.notifier).add(
          FavoriteContact(
            id: picked.id,
            label: picked.displayName,
            initials: _initials(picked.displayName),
            phones: phoneNumbers,
            countryCode: null,
          ),
        );

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.addedToFavorites(picked.displayName))),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first.characters.first : '';
    final second = parts.length > 1 ? parts[1].characters.first : '';
    return (first + second).toUpperCase();
  }
}

class _FavTile extends StatelessWidget {
  const _FavTile({
    required this.contact,
    required this.onSend,
    required this.onDelete,
    super.key,
  });

  final FavoriteContact contact;
  final VoidCallback onSend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(color: const Color(0xFF2B2F58))
            : Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7B4DFF), Color(0xFF4DA3FF)],
              ),
            ),
            child: Text(
              contact.initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              contact.label,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          Icon(Icons.drag_handle_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Send',
            onPressed: onSend,
            icon: Icon(Icons.send_rounded, color: theme.primaryColor),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Remove',
            onPressed: onDelete,
            icon: Icon(Icons.delete_outline_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

class _AppBarPillButton extends StatelessWidget {
  const _AppBarPillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Material(
        color: theme.primaryColor,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickedContact {
  final String id;
  final String displayName;
  final List<Phone> phones;
  const _PickedContact(
      {required this.id, required this.displayName, required this.phones});
}

class _FastContactPicker extends StatefulWidget {
  const _FastContactPicker({required this.ref});
  final WidgetRef ref;

  @override
  State<_FastContactPicker> createState() => _FastContactPickerState();
}

class _FastContactPickerState extends State<_FastContactPicker> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _queryCtrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() => _query = _queryCtrl.text.trim());
    });
  }

  Future<void> _pick(Contact c) async {
    final full =
        await widget.ref.read(contactsRepoProvider.notifier).getFull(c.id);
    if (!mounted) return;

    if (full == null || full.phones.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noPhoneNumber)),
      );
      return;
    }
    Navigator.pop(
      context,
      _PickedContact(
        id: c.id,
        displayName: c.displayName,
        phones: full.phones,
      ),
    );
  }

  String _initialsLocal(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    String first = parts.isNotEmpty ? parts.first : '';
    String second = parts.length > 1 ? parts[1] : '';
    String pick(String s) => s.isEmpty ? '' : s.characters.first;
    return (pick(first) + pick(second)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contactsAsync = widget.ref.watch(contactsRepoProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryCtrl,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: AppLocalizations.of(context)!.searchContacts,
                        hintStyle: TextStyle(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5)),
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primaryColor),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Fixed the contactsAsync.when syntax
            Expanded(
              child: contactsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Failed to load contacts',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
                data: (contacts) {
                  final filtered = _query.isEmpty
                      ? contacts
                      : contacts
                          .where((c) => c.displayName
                              .toLowerCase()
                              .contains(_query.toLowerCase()))
                          .toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final contact = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.cardTheme.color,
                          child: Text(
                            _initialsLocal(contact.displayName),
                            style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                          contact.displayName,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                        onTap: () => _pick(contact),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
