import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'recipients_providers.dart';

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
      ref.read(recipientsProvider.notifier).updateSearchQuery(_searchController.text);
      ref.read(recipientsProvider.notifier).fetchRecipients(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recipientsProvider);
    final notifier = ref.read(recipientsProvider.notifier);

    return LoadingOverlay(
      isLoading: state.loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recipients'),
          actions: [
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
              child: AppTextField(
                controller: _searchController,
                label: 'Search recipients...',
                prefixIcon: Icons.search,
              ),
            ),
            Expanded(
              child: _buildRecipientsList(state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientsList(RecipientsState state, RecipientsNotifier notifier) {
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
              onTap: () => notifier.selectRecipient(recipient),
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

  void _showAddRecipientDialog(BuildContext context, RecipientsNotifier notifier) {
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
              AppTextField(
                controller: phoneController,
                label: 'Phone Number',
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
                value: selectedCountryCode,
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
              if (formKey.currentState!.validate() && selectedCountryCode != null) {
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
}