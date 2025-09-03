import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'recipients_providers.dart';
import '../../../core/services/contacts_service.dart';
import '../data/models.dart';
import '../../transfer/presentation/send_amount_screen.dart';

class RecipientsScreen extends ConsumerStatefulWidget {
  const RecipientsScreen({super.key});

  @override
  ConsumerState<RecipientsScreen> createState() => _RecipientsScreenState();
}

class _RecipientsScreenState extends ConsumerState<RecipientsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(recipientsProvider.notifier)
          .updateSearchQuery(_searchController.text);
      ref.read(recipientsProvider.notifier).fetchRecipients(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 RecipientsScreen: build called');

    try {
      print('🔍 RecipientsScreen: About to watch recipientsProvider');
      final state = ref.watch(recipientsProvider);
      print('🔍 RecipientsScreen: State loaded successfully');

      print('🔍 RecipientsScreen: About to read recipientsProvider.notifier');
      final notifier = ref.read(recipientsProvider.notifier);
      print('🔍 RecipientsScreen: Notifier loaded successfully');

      print(
        '🔍 RecipientsScreen: State details - recipients: ${state.recipients.length}, loading: ${state.loading}, error: ${state.error?.message}',
      );

      return LoadingOverlay(
        isLoading: state.loading,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Recipients'),
            actions: [
              IconButton(
                icon: const Icon(Icons.contacts),
                onPressed: () => _showContactPicker(context, notifier),
                tooltip: 'Pick from contacts',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddRecipientDialog(context, notifier),
              ),
            ],
          ),
          body: Column(
            children: [
              if (state.error != null)
                ErrorBanner(
                  message: state.error!.message,
                  onDismiss: () => notifier.clearError(),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search recipients...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.contacts),
                      onPressed: () => _showContactPicker(context, notifier),
                      tooltip: 'Pick from contacts',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildRecipientsList(state, notifier)),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('🔍 RecipientsScreen: ERROR in build method: $e');
      print('🔍 RecipientsScreen: Stack trace: $stackTrace');

      return Scaffold(
        appBar: AppBar(title: const Text('Recipients')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading recipients',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $e',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  print('🔍 RecipientsScreen: Retry button pressed');
                  setState(() {});
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildRecipientsList(
    RecipientsState state,
    RecipientsNotifier notifier,
  ) {
    if (state.recipients.isEmpty && !state.loading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => notifier.fetchRecipients(refresh: true),
      child: ListView.builder(
        itemCount: state.recipients.length + (state.hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.recipients.length) {
            return _buildLoadMoreButton(notifier);
          }

          final recipient = state.recipients[index];
          final isSelected = state.selectedRecipient?.id == recipient.id;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: ListTile(
              leading: CircleAvatar(
                child: Text(recipient.name[0].toUpperCase()),
              ),
              title: Text(
                recipient.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipient.phoneNumber),
                  if (recipient.account != null)
                    Text('Account: ${recipient.account}'),
                ],
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () => _selectRecipient(recipient),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No recipients found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first recipient to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Add Recipient',
            onPressed: () => _showAddRecipientDialog(
              context,
              ref.read(recipientsProvider.notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(RecipientsNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SecondaryButton(
        label: 'Load More',
        onPressed: () => notifier.loadMoreRecipients(),
      ),
    );
  }

  void _showAddRecipientDialog(
    BuildContext context,
    RecipientsNotifier notifier,
  ) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String? selectedCountryCode;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Recipient'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameController,
                label: 'Name',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCountryCode,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                items: ref.read(recipientsProvider).countries.map((country) {
                  return DropdownMenuItem(
                    value: country.isoCode,
                    child: Text('${country.name} (${country.dialCode})'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCountryCode = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Country is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          PrimaryButton(
            label: 'Add',
            onPressed: () async {
              if (formKey.currentState!.validate() &&
                  selectedCountryCode != null) {
                await notifier.addRecipient(
                  nameController.text,
                  phoneController.text,
                  selectedCountryCode!,
                );
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _selectRecipient(Recipient recipient) {
    print('🔍 RecipientsScreen: Selecting recipient: ${recipient.name}');
    ref.read(recipientsProvider.notifier).selectRecipient(recipient);
    // Navigate to send amount screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SendAmountScreen(
          recipientId: recipient.id,
          recipientName: recipient.name,
          recipientPhone: recipient.phoneNumber,
        ),
      ),
    );
  }

  void _showContactPicker(
    BuildContext context,
    RecipientsNotifier notifier,
  ) async {
    print('🔍 RecipientsScreen: _showContactPicker called');
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading contacts...'),
            ],
          ),
        ),
      );

      // Get contacts
      print('🔍 RecipientsScreen: Getting contacts...');
      final contacts = await ContactsService.getContacts();
      print('🔍 RecipientsScreen: Got ${contacts.length} contacts');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show contact picker dialog
      if (mounted) {
        _showContactPickerDialog(context, contacts, notifier);
      }
    } catch (e) {
      print('🔍 RecipientsScreen: Error in _showContactPicker: $e');
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error with more details
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error Loading Contacts'),
            content: Text(
              'Failed to load contacts: $e\n\nPlease check your contacts permission in device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showContactPicker(context, notifier);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showContactPickerDialog(
    BuildContext context,
    List<AppContact> contacts,
    RecipientsNotifier notifier,
  ) {
    print(
      '🔍 RecipientsScreen: _showContactPickerDialog called with ${contacts.length} contacts',
    );
    final searchController = TextEditingController();
    List<AppContact> filteredContacts = contacts;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Pick Contact'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search contacts...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      filteredContacts = contacts.where((contact) {
                        return contact.name.toLowerCase().contains(
                              value.toLowerCase(),
                            ) ||
                            contact.phoneNumber.contains(value);
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredContacts.isEmpty
                      ? const Center(child: Text('No contacts found'))
                      : ListView.builder(
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = filteredContacts[index];
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(contact.name[0].toUpperCase()),
                              ),
                              title: Text(contact.name),
                              subtitle: Text(contact.phoneNumber),
                              onTap: () async {
                                print(
                                  '🔍 RecipientsScreen: Contact selected: ${contact.name}',
                                );
                                Navigator.of(context).pop();
                                await _addContactAsRecipient(contact, notifier);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addContactAsRecipient(
    AppContact contact,
    RecipientsNotifier notifier,
  ) async {
    print(
      '🔍 RecipientsScreen: _addContactAsRecipient called for ${contact.name}',
    );
    try {
      // Format phone number
      final formattedPhone = ContactsService.formatPhoneNumber(
        contact.phoneNumber,
      );
      print('🔍 RecipientsScreen: Formatted phone: $formattedPhone');

      // Add recipient (using CD as default country code for Congo)
      await notifier.addRecipient(
        contact.name,
        formattedPhone,
        'CD', // Default to Congo
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${contact.name} added as recipient'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      print('🔍 RecipientsScreen: Error adding contact as recipient: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add recipient: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
