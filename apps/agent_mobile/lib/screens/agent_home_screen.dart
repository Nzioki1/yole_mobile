import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';
import 'enroll_customer_screen.dart';
import 'cash_in_out_screen.dart';
import 'agent_history_screen.dart';
import '../widgets/agent_float_card.dart';
import '../widgets/agent_action_tile.dart';

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
  Map<String, dynamic>? _commissionSummary;

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

      // Load commission summary
      Map<String, dynamic>? commissionSummary;
      try {
        commissionSummary = await _api.getCommissionSummaryToday();
      } catch (e) {
        debugPrint('Failed to load commission summary: $e');
      }
      
      setState(() {
        _pockets = pockets;
        _agentInfo = agentInfo;
        _currentAgentId = agentId;
        _commissionSummary = commissionSummary;
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
          _commissionSummary = null;
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  String _getCdfFloat() {
    final cdfPocket = _pockets.firstWhere(
      (p) => p['currency'] == 'CDF',
      orElse: () => {'availableMinor': 0},
    );
    final availableMinor = int.tryParse(cdfPocket['availableMinor']?.toString() ?? '0') ?? 0;
    final available = availableMinor / 100;
    return 'FC ${available.toStringAsFixed(2)}';
  }

  String _getUsdFloat() {
    final usdPocket = _pockets.firstWhere(
      (p) => p['currency'] == 'USD',
      orElse: () => {'availableMinor': 0},
    );
    final availableMinor = int.tryParse(usdPocket['availableMinor']?.toString() ?? '0') ?? 0;
    final available = availableMinor / 100;
    return '\$ ${available.toStringAsFixed(2)}';
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
                    AgentFloatCard(
                      cdfFloat: _getCdfFloat(),
                      usdFloat: _getUsdFloat(),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Today\'s Commissions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_commissionSummary != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AgentHistoryScreen(),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    color: Colors.teal.shade700,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Commission Earned',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'CDF',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          'FC ${((_commissionSummary!['cdfMinor'] as int) / 100).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'USD',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '\$${((_commissionSummary!['usdMinor'] as int) / 100).toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Transactions',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${_commissionSummary!['count']}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'Tap to view history',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.teal.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Colors.teal.shade700,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No commissions earned today yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
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
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  AgentActionTile(
                    icon: Icons.arrow_downward,
                    label: 'Cash In',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CashInOutScreen(),
                        ),
                      );
                    },
                  ),
                  AgentActionTile(
                    icon: Icons.arrow_upward,
                    label: 'Cash Out',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CashInOutScreen(),
                        ),
                      );
                    },
                  ),
                  AgentActionTile(
                    icon: Icons.payment,
                    label: 'Pay for customer',
                    onTap: () {
                      Navigator.pushNamed(context, '/assisted-pay');
                    },
                  ),
                  AgentActionTile(
                    icon: Icons.person_add,
                    label: 'Enroll',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnrollCustomerScreen(),
                        ),
                      );
                    },
                  ),
                  AgentActionTile(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AgentHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
