import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/contacts_service.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import 'dart:async';

class EnhancedRecipientSelectionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> transferDetails;

  const EnhancedRecipientSelectionScreen({
    super.key,
    required this.transferDetails,
  });

  @override
  ConsumerState<EnhancedRecipientSelectionScreen> createState() =>
      _EnhancedRecipientSelectionScreenState();
}

class _EnhancedRecipientSelectionScreenState
    extends ConsumerState<EnhancedRecipientSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  AppContact? _selectedContact;
  String _selectedTab = 'contacts'; // 'contacts', 'recent', 'manual'
  bool _showManualEntry = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<AppContact> _contacts = [];
  List<AppContact> _filteredContacts = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contacts = await ContactsService.getContacts();
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });

      // If no contacts found, show a helpful message
      if (contacts.isEmpty) {
        setState(() {
          _errorMessage =
              'No contacts found. Please grant contacts permission or add contacts manually.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contacts: $e';
        _isLoading = false;
        _contacts = [];
        _filteredContacts = [];
      });
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterContacts(_searchController.text);
    });
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
    } else {
      setState(() {
        _filteredContacts = _contacts
            .where(
              (contact) =>
                  contact.name.toLowerCase().contains(query.toLowerCase()) ||
                  contact.phoneNumber.contains(query),
            )
            .toList();
      });
    }
  }

  void _selectContact(AppContact contact) {
    setState(() {
      _selectedContact = contact;
      _showManualEntry = false;
      _phoneController.text = ContactsService.formatPhoneNumber(
        contact.phoneNumber,
      );
      _nameController.text = contact.name;
    });
  }

  void _showManualEntryForm() {
    setState(() {
      _showManualEntry = true;
      _selectedContact = null;
      _phoneController.clear();
      _nameController.clear();
    });
  }

  void _proceedToAmount() {
    if (_selectedContact == null && !_showManualEntry) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a contact or enter recipient details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_showManualEntry) {
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in recipient name and phone number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Navigate to amount screen with recipient details
    final recipientDetails = {
      ...widget.transferDetails,
      'recipient_name': _selectedContact?.name ?? _nameController.text,
      'recipient_phone': _selectedContact?.phoneNumber ?? _phoneController.text,
      'is_manual_entry': _showManualEntry,
    };

    Navigator.of(
      context,
    ).pushNamed('/transfer/amount', arguments: recipientDetails);
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Recipient'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.error.withOpacity(.1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search contacts...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton('contacts', 'Contacts', Icons.contacts),
          _buildTabButton('recent', 'Recent', Icons.history),
          _buildTabButton('manual', 'Manual', Icons.edit),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tab;
            if (tab == 'manual') {
              _showManualEntryForm();
            } else {
              _showManualEntry = false;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'contacts':
        return _buildContactsList();
      case 'recent':
        return _buildRecentList();
      case 'manual':
        return _buildManualEntry();
      default:
        return _buildContactsList();
    }
  }

  Widget _buildContactsList() {
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No contacts found'
                  : 'No contacts match your search',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            if (_searchController.text.isEmpty)
              Text(
                'Grant contacts permission to access your phone book',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final isSelected = _selectedContact?.id == contact.id;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isSelected ? Colors.blue[50] : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              ContactsService.formatPhoneNumber(contact.phoneNumber),
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : null,
            onTap: () => _selectContact(contact),
          ),
        );
      },
    );
  }

  Widget _buildRecentList() {
    // Sample recent transactions - in real app, this would come from API
    final recentContacts = [
      {
        'name': 'Alice Johnson',
        'phone': '+254700987654',
        'amount': 150.0,
        'date': '2024-01-15',
      },
      {
        'name': 'Bob Smith',
        'phone': '+254700123456',
        'amount': 75.0,
        'date': '2024-01-10',
      },
      {
        'name': 'Carol Davis',
        'phone': '+254700555555',
        'amount': 200.0,
        'date': '2024-01-05',
      },
    ];

    return ListView.builder(
      itemCount: recentContacts.length,
      itemBuilder: (context, index) {
        final contact = recentContacts[index];
        final isSelected = _selectedContact?.phoneNumber == contact['phone'];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isSelected ? Colors.blue[50] : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: const Icon(Icons.history, color: Colors.green),
            ),
            title: Text(
              contact['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['phone'] as String,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  '\$${(contact['amount'] as double).toStringAsFixed(2)} on ${contact['date']}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : null,
            onTap: () {
              final recentContact = AppContact(
                id: 'recent_$index',
                name: contact['name'] as String,
                phoneNumber: contact['phone'] as String,
              );
              _selectContact(recentContact);
            },
          ),
        );
      },
    );
  }

  Widget _buildManualEntry() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Recipient Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Recipient Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (value.length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedContact != null || _showManualEntry) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${_selectedContact?.name ?? _nameController.text}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Continue',
              onPressed: (_selectedContact != null || _showManualEntry)
                  ? _proceedToAmount
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
