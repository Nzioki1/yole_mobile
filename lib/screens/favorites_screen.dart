import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../providers/favorites_provider.dart';
import '../providers/contacts_provider.dart';
import '../utils/contacts_permission.dart';
import '../l10n/app_localizations.dart';
import '../utils/payment_validator.dart';
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
                        onSelect: () async {
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
                        onDetails: () => _showContactDetails(context, c),
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

  void _showContactDetails(BuildContext screenContext, FavoriteContact contact) {
    showDialog(
      context: screenContext,
      builder: (dialogContext) => _ContactDetailsDialog(
        contact: contact,
        onUpdate: (updatedContact) {
          ref.read(favoritesProvider.notifier).update(contact.id, updatedContact);
          Navigator.pop(dialogContext);
          ScaffoldMessenger.of(screenContext).showSnackBar(
            const SnackBar(
              content: Text('Contact updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
        onSelectPhone: _showPhoneSelector,
      ),
    );
  }
}

class _ContactDetailsDialog extends StatefulWidget {
  const _ContactDetailsDialog({
    required this.contact,
    required this.onUpdate,
    required this.onSelectPhone,
  });

  final FavoriteContact contact;
  final Function(FavoriteContact) onUpdate;
  final Future<String?> Function(BuildContext, List<String>) onSelectPhone;

  @override
  State<_ContactDetailsDialog> createState() => _ContactDetailsDialogState();
}

class _ContactDetailsDialogState extends State<_ContactDetailsDialog> {
  late List<TextEditingController> _phoneControllers;
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _phoneControllers = widget.contact.phones
        .map((phone) => TextEditingController(text: phone))
        .toList();
    if (_phoneControllers.isEmpty) {
      _phoneControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPhoneField() {
    setState(() {
      _phoneControllers.add(TextEditingController());
    });
  }

  void _removePhoneField(int index) {
    if (_phoneControllers.length > 1) {
      setState(() {
        _phoneControllers[index].dispose();
        _phoneControllers.removeAt(index);
      });
    }
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate all phone numbers
    final List<String> validPhones = [];
    for (var controller in _phoneControllers) {
      final phone = controller.text.trim();
      if (phone.isNotEmpty) {
        final error = PaymentValidator.validateCongoPhone(phone);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid phone: $phone\n$error'),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
        validPhones.add(phone);
      }
    }

    if (validPhones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('At least one phone number is required'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Create updated contact
    final updatedContact = FavoriteContact(
      id: widget.contact.id,
      label: widget.contact.label,
      initials: widget.contact.initials,
      phones: validPhones,
      countryCode: widget.contact.countryCode,
    );

    widget.onUpdate(updatedContact);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: theme.cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF7B4DFF), Color(0xFF4DA3FF)],
                      ),
                    ),
                    child: Text(
                      widget.contact.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.contact.label,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.contact.countryCode != null)
                          Text(
                            'Country: ${widget.contact.countryCode}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Edit/View Mode Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phone Numbers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_isEditMode)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditMode = true;
                        });
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Phone Numbers Section
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_isEditMode)
                        ..._phoneControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controller = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controller,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: '+243123456789',
                                      hintStyle: TextStyle(
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.phone_outlined,
                                        color: theme.colorScheme.primary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      filled: true,
                                      fillColor:
                                          theme.colorScheme.surface.withOpacity(0.5),
                                    ),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        if (_phoneControllers.length > 1) {
                                          return null; // Optional if multiple phones
                                        }
                                        return 'Phone number is required';
                                      }
                                      final error = PaymentValidator
                                          .validateCongoPhone(value.trim());
                                      return error;
                                    },
                                  ),
                                ),
                                if (_phoneControllers.length > 1)
                                  IconButton(
                                    onPressed: () => _removePhoneField(index),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.error,
                                    ),
                                    tooltip: 'Remove',
                                  ),
                              ],
                            ),
                          );
                        })
                      else
                        ...widget.contact.phones.map((phone) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      phone,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      if (_isEditMode && _phoneControllers.length < 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            onPressed: _addPhoneField,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Phone Number'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.primaryColor,
                            ),
                          ),
                        ),
                      if (!_isEditMode && widget.contact.phones.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.noPhoneNumber,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_isEditMode) ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditMode = false;
                          // Reset controllers to original values
                          _phoneControllers.clear();
                          _phoneControllers = widget.contact.phones
                              .map((phone) => TextEditingController(text: phone))
                              .toList();
                          if (_phoneControllers.isEmpty) {
                            _phoneControllers.add(TextEditingController());
                          }
                        });
                      },
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close details dialog first
                        // Wait a frame for dialog to close, then trigger selection
                        await Future.microtask(() {});
                        if (!context.mounted) return;

                        // Trigger selection
                        if (widget.contact.phones.length > 1) {
                          final selectedPhone = await widget.onSelectPhone(
                              context, widget.contact.phones);
                          if (selectedPhone != null && context.mounted) {
                            Navigator.of(context).pop({
                              'recipient': widget.contact.label,
                              'recipientPhone': selectedPhone,
                              'recipientCountry': widget.contact.countryCode,
                            });
                          }
                        } else if (widget.contact.phones.isNotEmpty) {
                          Navigator.of(context).pop({
                            'recipient': widget.contact.label,
                            'recipientPhone': widget.contact.phones.first,
                            'recipientCountry': widget.contact.countryCode,
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.noPhoneNumber)),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Select'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavTile extends StatelessWidget {
  const _FavTile({
    required this.contact,
    required this.onSelect,
    required this.onDetails,
    required this.onSend,
    required this.onDelete,
    super.key,
  });

  final FavoriteContact contact;
  final VoidCallback onSelect;
  final VoidCallback onDetails;
  final VoidCallback onSend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: isDark
            ? Border.all(color: const Color(0xFF2B2F58))
            : Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                IconButton(
                  tooltip: 'View Details',
                  onPressed: onDetails,
                  icon: Icon(
                    Icons.drag_handle_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 4),
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
          ),
        ),
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
