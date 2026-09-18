import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';
import 'enroll_customer_screen.dart';
import 'cash_in_out_screen.dart';
import 'agent_history_screen.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  final _api = AgentApiService();
  bool _loading = true;
  Map<String, dynamic>? _agentInfo;
  List<dynamic> _pockets = [];
  String? _currentAgentId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      await _api.init();
      
      // Load float balances from backend
      final wallet = await _api.getFloatBalances();
      final pockets = wallet['pockets'] as List<dynamic>? ?? [];
      final agentId = wallet['agentId'] as String?;
      
      // Load agent info for status card
      Map<String, dynamic>? agentInfo;
      if (agentId != null && agentId.isNotEmpty) {
        try {
          agentInfo = await _api.getAgentInfo(agentId);
        } catch (e) {
          // Agent info fetch failed, continue without it
          debugPrint('Failed to load agent info: $e');
        }
      }
      
      setState(() {
        _pockets = pockets;
        _agentInfo = agentInfo;
        _currentAgentId = agentId;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading float: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadData,
              textColor: Colors.white,
            ),
          ),
        );
        // Set empty state on error
        setState(() {
          _pockets = [];
          _agentInfo = null;
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/brand/poste-finance-mark.png',
              height: 28,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            const Text('Poste Finance'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Agent',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                await _api.clearAgentId();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Float Balance',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_pockets.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No float loaded. Pull to refresh.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._pockets.map((pocket) {
                      final availableMinor = int.tryParse(pocket['availableMinor']?.toString() ?? '0') ?? 0;
                      final ledgerMinor = int.tryParse(pocket['ledgerMinor']?.toString() ?? '0') ?? 0;
                      final currency = pocket['currency'] as String? ?? 'USD';
                      final available = availableMinor / 100;
                      final ledger = ledgerMinor / 100;
                      final currencySymbol = currency == 'CDF' ? 'FC' : '\$';
                      
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.account_balance_wallet,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            currency,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('Available: $currencySymbol${available.toStringAsFixed(2)}'),
                          trailing: Text(
                            '$currencySymbol${ledger.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  const Text(
                    'Agent Status',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_agentInfo != null)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          _agentInfo!['status'] == 'ACTIVE'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _agentInfo!['status'] == 'ACTIVE'
                              ? Colors.green
                              : Colors.red,
                          size: 32,
                        ),
                        title: Text(
                          '${_agentInfo!['firstName'] ?? ''} ${_agentInfo!['lastName'] ?? ''}'.trim(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Agent ID: ${_agentInfo!['id'] ?? ''}'),
                            const SizedBox(height: 2),
                            Text(
                              _agentInfo!['status'] == 'ACTIVE'
                                  ? '✓ Active'
                                  : '⊗ Inactive',
                              style: TextStyle(
                                color: _agentInfo!['status'] == 'ACTIVE'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Agent information unavailable',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_add),
                      title: const Text('Enroll Customer'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EnrollCustomerScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.arrow_downward, color: Colors.green),
                      title: const Text('Cash In / Out'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CashInOutScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('History'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AgentHistoryScreen(),
                          ),
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
