import 'package:flutter/material.dart';
import '../services/core_api_service.dart';
import '../router_types.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  final _api = CoreApiService();
  bool _loading = true;
  Map<String, dynamic>? _salaryAdvanceEligibility;
  Map<String, dynamic>? _microLoanEligibility;
  List<dynamic> _loans = [];

  @override
  void initState() {
    super.initState();
    _api.init();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.checkCreditEligibility(type: 'SALARY_ADVANCE').catchError((_) => <String, dynamic>{}),
        _api.checkCreditEligibility(type: 'MICRO_LOAN').catchError((_) => <String, dynamic>{}),
        _api.listLoans().catchError((_) => <dynamic>[]),
      ]);
      setState(() {
        _salaryAdvanceEligibility = results[0] as Map<String, dynamic>?;
        _microLoanEligibility = results[1] as Map<String, dynamic>?;
        _loans = results[2] as List<dynamic>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading credit data: $e')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit & Loans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                  // Header
                  Text(
                    'Available Credit Products',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access quick loans and salary advances',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Salary Advance Card
                  _CreditProductCard(
                    title: 'Salary Advance',
                    description: 'Get up to 50% of your expected salary instantly',
                    icon: Icons.account_balance_wallet,
                    eligibility: _salaryAdvanceEligibility,
                    onApply: () => _navigateToApply('SALARY_ADVANCE'),
                    theme: theme,
                  ),
                  const SizedBox(height: 16),

                  // Micro Loan Card
                  _CreditProductCard(
                    title: 'Micro Loan',
                    description: 'Quick personal loans with flexible terms',
                    icon: Icons.monetization_on,
                    eligibility: _microLoanEligibility,
                    onApply: () => _navigateToApply('MICRO_LOAN'),
                    theme: theme,
                  ),
                  const SizedBox(height: 32),

                  // Active Loans Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Loans',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (_loans.isNotEmpty)
                        Text(
                          '${_loans.length} active',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_loans.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.credit_card_off, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No active loans',
                            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._loans.map((loan) => _LoanCard(
                          loan: loan,
                          onTap: () => _navigateToDetail(loan['id']?.toString()),
                          theme: theme,
                        )),
                ],
              ),
            ),
    );
  }

  void _navigateToApply(String type) {
    Navigator.of(context).pushNamed(
      RouteNames.creditApply,
      arguments: {'type': type},
    ).then((_) => _loadData());
  }

  void _navigateToDetail(String? loanId) {
    if (loanId == null || loanId.isEmpty) return;
    Navigator.of(context).pushNamed(
      RouteNames.creditDetail,
      arguments: {'loanId': loanId},
    );
  }
}

class _CreditProductCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Map<String, dynamic>? eligibility;
  final VoidCallback onApply;
  final ThemeData theme;

  const _CreditProductCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.eligibility,
    required this.onApply,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isEligible = eligibility?['eligible'] == true;
    final maxAmount = eligibility?['maxAmountMinor'];
    final reason = eligibility?['reason'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (eligibility == null)
              const Text('Checking eligibility...', style: TextStyle(color: Colors.grey))
            else if (isEligible) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Eligible',
                    style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (maxAmount != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Max Amount: ${_formatAmount(maxAmount.toString())} ${eligibility?['currency'] ?? 'USD'}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Apply Now'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Not Eligible',
                    style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (reason != null) ...[
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final VoidCallback onTap;
  final ThemeData theme;

  const _LoanCard({
    required this.loan,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final status = loan['status']?.toString() ?? 'UNKNOWN';
    final type = loan['type']?.toString() ?? '';
    final principalRaw = loan['principalMinor'];
    final principal = principalRaw?.toString() ?? '0';
    final currency = loan['currency']?.toString() ?? 'USD';
    final disbursedAt = loan['disbursedAt'];

    Color statusColor = Colors.grey;
    if (status == 'ACTIVE') statusColor = Colors.green;
    if (status == 'PENDING') statusColor = Colors.orange;
    if (status == 'REPAID') statusColor = Colors.blue;
    if (status == 'DEFAULTED') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.receipt_long, color: statusColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatType(type),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency ${_formatAmount(principal)}',
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (disbursedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Disbursed ${_formatDate(disbursedAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatType(String? type) {
    if (type == null || type.isEmpty) return 'Loan';
    return type
        .split('_')
        .where((word) => word.isNotEmpty) // Filter out empty segments
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatAmount(String amountStr) {
    try {
      final num amount = num.tryParse(amountStr) ?? 0;
      return (amount / 100).toStringAsFixed(2);
    } catch (_) {
      return '0.00';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return 'today';
      if (diff.inDays == 1) return 'yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
