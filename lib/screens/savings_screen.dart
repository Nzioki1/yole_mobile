import 'package:flutter/material.dart';
import '../services/core_api_service.dart';
import '../router_types.dart';

String _formatMinorAmount(Object? amount) {
  final amountStr = amount?.toString() ?? '0';
  final num parsed = num.tryParse(amountStr) ?? 0;
  return (parsed / 100).toStringAsFixed(2);
}

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final _api = CoreApiService();
  bool _loading = true;
  List<dynamic> _goals = [];

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _loading = true);
    try {
      final goals = await _api.listSavingsGoals();
      setState(() => _goals = goals);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading savings goals: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _navigateToCreateGoal() {
    Navigator.of(context)
        .pushNamed(RouteNames.savingsCreateGoal)
        .then((_) => _loadGoals());
  }

  void _navigateToGoalDetail(String goalId) {
    Navigator.of(context).pushNamed(
      RouteNames.savingsGoalDetail,
      arguments: {'goalId': goalId},
    ).then((_) => _loadGoals());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGoals,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGoals,
              child: _goals.isEmpty
                  ? _buildEmptyState(theme)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        return _GoalCard(
                          goal: goal,
                          onTap: () => _navigateToGoalDetail(goal['id']),
                          theme: theme,
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateGoal,
        icon: const Icon(Icons.add),
        label: const Text('Create Goal'),
        backgroundColor: const Color(0xFF00ACAC),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF00ACAC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.savings_outlined,
                size: 60,
                color: Color(0xFF00ACAC),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Savings Goals Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start saving for your dreams.\nCreate your first savings goal today!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreateGoal,
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACAC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final VoidCallback onTap;
  final ThemeData theme;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final name = goal['name'] as String? ?? 'Untitled Goal';
    final currency = goal['currency'] as String? ?? 'USD';
    final targetMinor = int.tryParse(goal['targetMinor']?.toString() ?? '0') ?? 0;
    final depositedMinor = int.tryParse(goal['depositedMinor']?.toString() ?? '0') ?? 0;
    final autoDepositEnabled = goal['autoDepositEnabled'] == true;

    final target = targetMinor / 100;
    final deposited = depositedMinor / 100;
    final progress = targetMinor > 0 ? (depositedMinor / targetMinor).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();

    final currencySymbol = currency == 'CDF' ? 'FC' : '\$';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00ACAC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      currency,
                      style: const TextStyle(
                        color: Color(0xFF00ACAC),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currencySymbol ${deposited.toStringAsFixed(2)} of $currencySymbol ${target.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF00ACAC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00ACAC),
                  ),
                ),
              ),
              if (autoDepositEnabled) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.autorenew,
                      size: 16,
                      color: Color(0xFF00ACAC),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Auto-deposit enabled',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF00ACAC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
