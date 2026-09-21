import 'package:flutter/material.dart';
import '../services/offline_agent_repository.dart';

class AgentHistoryScreen extends StatefulWidget {
  const AgentHistoryScreen({super.key});

  @override
  State<AgentHistoryScreen> createState() => _AgentHistoryScreenState();
}

class _AgentHistoryScreenState extends State<AgentHistoryScreen> {
  final _repo = OfflineAgentRepository.instance;
  final _searchController = TextEditingController();
  String _selectedSegment = 'ALL';
  bool _loading = true;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterItems);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final journals = _repo.getTodayHistory();
      final enrollments = _repo.getTodayEnrollments();
      final commissions = _repo.listCommissionsToday();

      final items = <Map<String, dynamic>>[];

      // Add cash operations
      for (final journal in journals) {
        final customer = _repo.findCustomerById(journal['customerId'] as String);
        
        // Find matching commission by txnId/refId
        final commission = commissions.firstWhere(
          (c) => c['txnId'] == journal['refId'],
          orElse: () => <String, dynamic>{},
        );

        items.add({
          'type': journal['type'],
          'timestamp': journal['postedAt'],
          'customer': customer,
          'amountMinor': journal['amountMinor'],
          'feeMinor': journal['feeMinor'],
          'currency': journal['currency'],
          'balanceAfterMinor': journal['balanceAfterMinor'],
          'referenceId': journal['id'],
          'data': journal,
          'commission': commission.isNotEmpty ? commission : null,
        });
      }

      // Add enrollments
      for (final customer in enrollments) {
        items.add({
          'type': 'ENROLL',
          'timestamp': customer['createdAt'],
          'customer': customer,
          'referenceId': customer['id'],
          'data': customer,
        });
      }

      // Sort by timestamp descending
      items.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] as String);
        final bTime = DateTime.parse(b['timestamp'] as String);
        return bTime.compareTo(aTime);
      });

      setState(() {
        _allItems = items;
        _filteredItems = items;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterItems() {
    final query = _searchController.text.trim().toLowerCase();
    var items = _allItems;

    // Apply segment filter
    if (_selectedSegment != 'ALL') {
      items = items.where((item) {
        if (_selectedSegment == 'CASH_IN') {
          return item['type'] == 'AGENT_CASH_IN';
        } else if (_selectedSegment == 'CASH_OUT') {
          return item['type'] == 'AGENT_CASH_OUT';
        } else if (_selectedSegment == 'ENROLL') {
          return item['type'] == 'ENROLL';
        }
        return true;
      }).toList();
    }

    // Apply search filter
    if (query.isNotEmpty) {
      items = items.where((item) {
        final customer = item['customer'] as Map<String, dynamic>?;
        final phone = customer?['phoneE164'] as String? ?? '';
        final refId = item['referenceId'] as String? ?? '';
        return phone.toLowerCase().contains(query) ||
            refId.toLowerCase().contains(query);
      }).toList();
    }

    setState(() => _filteredItems = items);
  }

  Map<String, dynamic> _calculateTotals() {
    int cashInCdf = 0;
    int cashOutCdf = 0;
    int cashInCount = 0;
    int cashOutCount = 0;
    int enrollCount = 0;

    for (final item in _filteredItems) {
      final type = item['type'] as String;
      if (type == 'AGENT_CASH_IN') {
        cashInCount++;
        final currency = item['currency'] as String?;
        if (currency == 'CDF') {
          cashInCdf += item['amountMinor'] as int? ?? 0;
        }
      } else if (type == 'AGENT_CASH_OUT') {
        cashOutCount++;
        final currency = item['currency'] as String?;
        if (currency == 'CDF') {
          cashOutCdf += item['amountMinor'] as int? ?? 0;
        }
      } else if (type == 'ENROLL') {
        enrollCount++;
      }
    }

    return {
      'cashInCdf': cashInCdf,
      'cashOutCdf': cashOutCdf,
      'cashInCount': cashInCount,
      'cashOutCount': cashOutCount,
      'enrollCount': enrollCount,
    };
  }

  void _showDetailSheet(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final customer = item['customer'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTypeLabel(type),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 16),
              if (type == 'ENROLL') ..._buildEnrollmentDetails(customer)
              else ..._buildCashOperationDetails(item, customer),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEnrollmentDetails(Map<String, dynamic>? customer) {
    if (customer == null) return [const Text('Customer data unavailable')];

    final wallets = _repo.getCustomerWallets(customer['id'] as String);
    final cdfWallet = wallets.firstWhere(
      (w) => w['currency'] == 'CDF',
      orElse: () => <String, dynamic>{},
    );
    final usdWallet = wallets.firstWhere(
      (w) => w['currency'] == 'USD',
      orElse: () => <String, dynamic>{},
    );

    return [
      _buildDetailRow('Customer Name', '${customer['firstName']} ${customer['lastName']}'),
      _buildDetailRow('Phone', customer['phoneE164'] ?? 'N/A'),
      _buildDetailRow('Email', customer['email'] ?? 'N/A'),
      const Divider(),
      _buildDetailRow('Customer ID', customer['id'] ?? 'N/A'),
      _buildDetailRow('CDF Wallet', cdfWallet['id'] ?? 'N/A'),
      _buildDetailRow('USD Wallet', usdWallet['id'] ?? 'N/A'),
      const Divider(),
      _buildDetailRow('KYC Status', customer['kycStatus'] ?? 'N/A'),
      _buildDetailRow('Enrolled At', customer['createdAt'] ?? 'N/A'),
    ];
  }

  List<Widget> _buildCashOperationDetails(
    Map<String, dynamic> item,
    Map<String, dynamic>? customer,
  ) {
    if (customer == null) return [const Text('Customer data unavailable')];

    final amountMinor = item['amountMinor'] as int? ?? 0;
    final feeMinor = item['feeMinor'] as int? ?? 0;
    final balanceAfterMinor = item['balanceAfterMinor'] as int? ?? 0;
    final currency = item['currency'] as String? ?? 'USD';
    final symbol = currency == 'CDF' ? 'FC' : '\$';
    final amount = amountMinor / 100;
    final fee = feeMinor / 100;
    final balanceAfter = balanceAfterMinor / 100;

    // Get commission if available
    final commission = item['commission'] as Map<String, dynamic>?;
    final commissionMinor = commission?['commissionMinor'] as int? ?? 0;
    final commissionBps = commission?['bps'] as int? ?? 0;
    final commissionAmount = commissionMinor / 100;

    // Calculate agent float after (approximate from current float minus later transactions)
    final agentFloat = _repo.getFloatBalances();
    final pockets = agentFloat['pockets'] as List<dynamic>;
    final agentPocket = pockets.firstWhere(
      (p) => p['currency'] == currency,
      orElse: () => <String, dynamic>{'availableMinor': '0'},
    );
    final agentFloatAfter = int.parse(agentPocket['availableMinor']?.toString() ?? '0') / 100;

    return [
      _buildDetailRow('Customer Name', '${customer['firstName']} ${customer['lastName']}'),
      _buildDetailRow('Phone', customer['phoneE164'] ?? 'N/A'),
      _buildDetailRow('Customer ID', customer['id'] ?? 'N/A'),
      const Divider(),
      _buildDetailRow('Amount', '$symbol${amount.toStringAsFixed(2)}', bold: true),
      _buildDetailRow('Fee', '$symbol${fee.toStringAsFixed(2)}'),
      if (commission != null) ...[
        _buildDetailRow('Commission', '$symbol${commissionAmount.toStringAsFixed(2)}', bold: true),
        _buildDetailRow('Commission Rate', '${(commissionBps / 100).toStringAsFixed(2)}%'),
      ],
      const Divider(),
      _buildDetailRow('Customer Balance After', '$symbol${balanceAfter.toStringAsFixed(2)}'),
      _buildDetailRow('Agent Float After', '$symbol${agentFloatAfter.toStringAsFixed(2)}'),
      const Divider(),
      _buildDetailRow('Journal ID', item['referenceId'] ?? 'N/A', small: true),
      _buildDetailRow('Posted At', item['timestamp'] ?? 'N/A', small: true),
    ];
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false, bool small = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: small ? 12 : 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: small ? 12 : 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'AGENT_CASH_IN':
        return 'Cash In';
      case 'AGENT_CASH_OUT':
        return 'Cash Out';
      case 'ENROLL':
        return 'Customer Enrollment';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'AGENT_CASH_IN':
        return Icons.arrow_downward;
      case 'AGENT_CASH_OUT':
        return Icons.arrow_upward;
      case 'ENROLL':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'AGENT_CASH_IN':
        return Colors.green;
      case 'AGENT_CASH_OUT':
        return Colors.orange;
      case 'ENROLL':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent History'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ALL', label: Text('All')),
                    ButtonSegment(value: 'CASH_IN', label: Text('Cash In')),
                    ButtonSegment(value: 'CASH_OUT', label: Text('Cash Out')),
                    ButtonSegment(value: 'ENROLL', label: Text('Enroll')),
                  ],
                  selected: {_selectedSegment},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedSegment = newSelection.first;
                      _filterItems();
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search by phone or ref',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions today',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredItems.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _filteredItems.length) {
                            // Totals summary card
                            return Card(
                              margin: const EdgeInsets.all(16),
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Today:',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Divider(),
                                    _buildTotalRow(
                                      'Cash In',
                                      'FC ${(totals['cashInCdf'] / 100).toStringAsFixed(2)} (${totals['cashInCount']} txns)',
                                      Colors.green,
                                    ),
                                    _buildTotalRow(
                                      'Cash Out',
                                      'FC ${(totals['cashOutCdf'] / 100).toStringAsFixed(2)} (${totals['cashOutCount']} txns)',
                                      Colors.orange,
                                    ),
                                    _buildTotalRow(
                                      'Enrolled',
                                      '${totals['enrollCount']} customers',
                                      Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final item = _filteredItems[index];
                          final type = item['type'] as String;
                          final customer = item['customer'] as Map<String, dynamic>?;
                          final timestamp = DateTime.parse(item['timestamp'] as String);
                          final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

                          String subtitle;
                          if (type == 'ENROLL') {
                            subtitle = customer?['phoneE164'] ?? 'No phone';
                          } else {
                            final amountMinor = item['amountMinor'] as int? ?? 0;
                            final currency = item['currency'] as String? ?? 'USD';
                            final symbol = currency == 'CDF' ? 'FC' : '\$';
                            final amount = amountMinor / 100;
                            
                            // Add commission if available
                            final commission = item['commission'] as Map<String, dynamic>?;
                            if (commission != null) {
                              final commissionMinor = commission['commissionMinor'] as int? ?? 0;
                              final commissionAmount = commissionMinor / 100;
                              subtitle = '$symbol${amount.toStringAsFixed(2)} • Commission: $symbol${commissionAmount.toStringAsFixed(2)}';
                            } else {
                              subtitle = '$symbol${amount.toStringAsFixed(2)} • ${customer?['phoneE164'] ?? 'No phone'}';
                            }
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getTypeColor(type).withOpacity(0.2),
                                child: Icon(
                                  _getTypeIcon(type),
                                  color: _getTypeColor(type),
                                ),
                              ),
                              title: Text(
                                '${customer?['firstName'] ?? 'Unknown'} ${customer?['lastName'] ?? ''}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(subtitle),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getTypeLabel(type),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showDetailSheet(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
