import 'package:flutter/material.dart';
import '../services/agent_api_service.dart';
import 'enroll_customer_screen.dart';
import 'cash_in_out_screen.dart';

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
      
      setState(() {
        _pockets = pockets;
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
        setState(() => _pockets = []);
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLE Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _api.clearAgentId();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
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
                ],
              ),
            ),
    );
  }
}
