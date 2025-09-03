import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecipientSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> transferDetails;

  const RecipientSelectionScreen({super.key, required this.transferDetails});

  @override
  State<RecipientSelectionScreen> createState() =>
      _RecipientSelectionScreenState();
}

class _RecipientSelectionScreenState extends State<RecipientSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Map<String, dynamic>? _selectedRecipient;
  String _selectedTab = 'contacts'; // 'contacts' or 'recent'
  bool _showNewRecipientForm = false;

  // Sample data
  final List<Map<String, dynamic>> _contacts = [
    {'name': 'Alice Johnson', 'phone': '+254700987654', 'avatar': 'A'},
    {'name': 'Bob Smith', 'phone': '+254700123456', 'avatar': 'B'},
    {'name': 'Carol Davis', 'phone': '+254700555555', 'avatar': 'C'},
    {'name': 'David Wilson', 'phone': '+254700777777', 'avatar': 'D'},
    {'name': 'Emma Brown', 'phone': '+254700999999', 'avatar': 'E'},
  ];

  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'name': 'Alice Johnson',
      'phone': '+254700987654',
      'amount': 150.0,
      'date': '2024-01-15',
      'avatar': 'A',
    },
    {
      'name': 'Bob Smith',
      'phone': '+254700123456',
      'amount': 75.0,
      'date': '2024-01-10',
      'avatar': 'B',
    },
    {
      'name': 'Carol Davis',
      'phone': '+254700555555',
      'amount': 200.0,
      'date': '2024-01-05',
      'avatar': 'C',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _selectRecipient(Map<String, dynamic> recipient) {
    setState(() {
      _selectedRecipient = recipient;
      _showNewRecipientForm = false;
    });
  }

  void _displayNewRecipientForm() {
    setState(() {
      _showNewRecipientForm = true;
      _selectedRecipient = null;
    });
  }

  void _proceedToConfirmation() {
    if (_selectedRecipient == null && !_showNewRecipientForm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recipient or add a new one'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_showNewRecipientForm) {
      if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in recipient name and phone number'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _selectedRecipient = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'avatar': _nameController.text[0].toUpperCase(),
      };
    }

    // Navigate to confirmation screen
    final confirmationData = {
      ...widget.transferDetails,
      'recipient': _selectedRecipient,
    };

    context.push('/transfer-confirmation', extra: confirmationData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Select Recipient'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Step Indicator
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepIndicator(1, 'Amount', false),
                _buildStepConnector(),
                _buildStepIndicator(2, 'Recipient', true),
                _buildStepConnector(),
                _buildStepIndicator(3, 'Confirm', false),
              ],
            ),
          ),

          // Transfer Summary
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2563EB).withOpacity(0.1),
                  Color(0xFF7C3AED).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF2563EB).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF2563EB).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.attach_money,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer Amount',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${widget.transferDetails['amount'].toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Total: \$${widget.transferDetails['totalCost'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'Contacts',
                    Icons.contacts,
                    'contacts',
                  ),
                ),
                Expanded(
                  child: _buildTabButton('Recent', Icons.history, 'recent'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search Bar
          if (_selectedTab == 'contacts')
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _selectedTab == 'contacts'
                ? _buildContactsList()
                : _buildRecentTransactionsList(),
          ),

          // Selected Recipient Display
          if (_selectedRecipient != null || _showNewRecipientForm)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _showNewRecipientForm
                              ? 'New Recipient'
                              : _selectedRecipient!['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                            fontSize: 16,
                          ),
                        ),
                        if (_showNewRecipientForm)
                          Text(
                            'Fill in details below',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 14,
                            ),
                          )
                        else
                          Text(
                            _selectedRecipient!['phone'],
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedRecipient = null;
                        _showNewRecipientForm = false;
                      });
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.2),
                      foregroundColor: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

          // New Recipient Form
          if (_showNewRecipientForm)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Recipient Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+254 700 123 456',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),

          // Continue Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _proceedToConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue to Confirmation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, String tab) {
    final isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    final filteredContacts = _contacts.where((contact) {
      final searchTerm = _searchController.text.toLowerCase();
      return contact['name'].toLowerCase().contains(searchTerm) ||
          contact['phone'].contains(searchTerm);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredContacts.length + 1, // +1 for "Add New" button
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: _displayNewRecipientForm,
              icon: const Icon(Icons.add),
              label: const Text('Add New Recipient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        }

        final contact = filteredContacts[index - 1];
        final isSelected = _selectedRecipient?['phone'] == contact['phone'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFF2563EB).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Color(0xFF2563EB) : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => _selectRecipient(contact),
            leading: CircleAvatar(
              backgroundColor: Color(0xFF2563EB).withOpacity(0.1),
              child: Text(
                contact['avatar'],
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              contact['name'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Color(0xFF2563EB) : Colors.grey.shade800,
              ),
            ),
            subtitle: Text(
              contact['phone'],
              style: TextStyle(
                color: isSelected
                    ? Color(0xFF2563EB).withOpacity(0.7)
                    : Colors.grey.shade600,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: Color(0xFF2563EB))
                : Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _recentTransactions[index];
        final isSelected = _selectedRecipient?['phone'] == transaction['phone'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFF2563EB).withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Color(0xFF2563EB) : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => _selectRecipient(transaction),
            leading: CircleAvatar(
              backgroundColor: Color(0xFF2563EB).withOpacity(0.1),
              child: Text(
                transaction['avatar'],
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              transaction['name'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? Color(0xFF2563EB) : Colors.grey.shade800,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['phone'],
                  style: TextStyle(
                    color: isSelected
                        ? Color(0xFF2563EB).withOpacity(0.7)
                        : Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Last sent: \$${transaction['amount'].toStringAsFixed(2)} on ${transaction['date']}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: Color(0xFF2563EB))
                : Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF2563EB) : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isActive ? Color(0xFF2563EB) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 40,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
