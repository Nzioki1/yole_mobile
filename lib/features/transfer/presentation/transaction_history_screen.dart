import 'package:flutter/material.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];

  final List<String> _filterOptions = ['All', 'Sent', 'Received', 'Failed'];

  @override
  void initState() {
    super.initState();
    _loadMockTransactions();
    _searchController.addListener(_filterTransactions);
  }

  void _loadMockTransactions() {
    // Mock transaction data
    _transactions = [
      {
        'id': 'TXN_001',
        'type': 'Sent',
        'amount': 150.00,
        'recipient': '+254 700 123 456',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'status': 'Completed',
        'fee': 2.50,
        'total': 152.50,
        'card': 'Visa ****1234',
      },
      {
        'id': 'TXN_002',
        'type': 'Received',
        'amount': 75.00,
        'sender': '+254 700 789 012',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'Completed',
        'fee': 0.00,
        'total': 75.00,
        'card': null,
      },
      {
        'id': 'TXN_003',
        'type': 'Sent',
        'amount': 300.00,
        'recipient': '+254 700 345 678',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'status': 'Completed',
        'fee': 3.00,
        'total': 303.00,
        'card': 'Mastercard ****5678',
      },
      {
        'id': 'TXN_004',
        'type': 'Sent',
        'amount': 50.00,
        'recipient': '+254 700 901 234',
        'date': DateTime.now().subtract(const Duration(days: 4)),
        'status': 'Failed',
        'fee': 1.00,
        'total': 51.00,
        'card': 'Visa ****9012',
      },
      {
        'id': 'TXN_005',
        'type': 'Received',
        'amount': 200.00,
        'sender': '+254 700 567 890',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'status': 'Completed',
        'fee': 0.00,
        'total': 200.00,
        'card': null,
      },
    ];
    _filteredTransactions = List.from(_transactions);
  }

  void _filterTransactions() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        // Filter by selected filter
        bool matchesFilter =
            _selectedFilter == 'All' || transaction['type'] == _selectedFilter;

        // Filter by search text
        bool matchesSearch =
            _searchController.text.isEmpty ||
            transaction['id'].toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            (transaction['recipient'] ?? transaction['sender']).contains(
              _searchController.text,
            );

        return matchesFilter && matchesSearch;
      }).toList();
    });
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedFilter = value;
      });
      _filterTransactions();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Sent':
        return Colors.red;
      case 'Received':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _onFilterChanged(filter);
                            }
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _filteredTransactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final isReceived = transaction['type'] == 'Received';
    final contact = isReceived
        ? transaction['sender']
        : transaction['recipient'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getTypeColor(transaction['type']).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isReceived ? Icons.call_received : Icons.call_made,
            color: _getTypeColor(transaction['type']),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction['type'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction['status'],
                style: TextStyle(
                  color: _getStatusColor(transaction['status']),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(contact, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              'ID: ${transaction['id']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              '${transaction['date'].day}/${transaction['date'].month}/${transaction['date'].year} at ${transaction['date'].hour}:${transaction['date'].minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (transaction['card'] != null) ...[
              const SizedBox(height: 4),
              Text(
                'Card: ${transaction['card']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isReceived ? '+' : '-'}\$${transaction['amount'].toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isReceived ? Colors.green : Colors.red,
              ),
            ),
            if (transaction['fee'] > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Fee: \$${transaction['fee'].toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        onTap: () {
          _showTransactionDetails(transaction);
        },
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Details',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    _buildDetailRow('Transaction ID', transaction['id']),
                    _buildDetailRow('Type', transaction['type']),
                    _buildDetailRow('Status', transaction['status']),
                    _buildDetailRow(
                      'Amount',
                      '\$${transaction['amount'].toStringAsFixed(2)}',
                    ),
                    if (transaction['fee'] > 0)
                      _buildDetailRow(
                        'Fee',
                        '\$${transaction['fee'].toStringAsFixed(2)}',
                      ),
                    _buildDetailRow(
                      'Total',
                      '\$${transaction['total'].toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      'Date',
                      '${transaction['date'].day}/${transaction['date'].month}/${transaction['date'].year}',
                    ),
                    _buildDetailRow(
                      'Time',
                      '${transaction['date'].hour}:${transaction['date'].minute.toString().padLeft(2, '0')}',
                    ),
                    if (transaction['card'] != null)
                      _buildDetailRow('Payment Method', transaction['card']),
                  ],
                ),
              ),
            ),

            // Close button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
