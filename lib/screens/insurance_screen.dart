import 'package:flutter/material.dart';
import '../services/core_api_service.dart';
import '../constants/insurance_products.dart';
import '../models/insurance_product.dart';

class InsuranceScreen extends StatefulWidget {
  const InsuranceScreen({super.key});

  @override
  State<InsuranceScreen> createState() => _InsuranceScreenState();
}

class _InsuranceScreenState extends State<InsuranceScreen>
    with SingleTickerProviderStateMixin {
  final _api = CoreApiService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _api.init();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'My Policies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProductsTab(api: _api),
          _MyPoliciesTab(api: _api),
        ],
      ),
    );
  }
}

class _ProductsTab extends StatefulWidget {
  final CoreApiService api;

  const _ProductsTab({required this.api});

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.api.getInsurancePolicies('cust_kasee'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final policies = snapshot.data!;
        final activeProductIds = policies
            .where((p) => p['active'] == true)
            .map((p) => p['productId'] as String)
            .toSet();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: kInsuranceProducts.length,
          itemBuilder: (context, index) {
            final product = kInsuranceProducts[index];
            final isActive = activeProductIds.contains(product.id);
            return _ProductCard(
              product: product,
              isActive: isActive,
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/insurance/activate',
                  arguments: {'productId': product.id},
                );
                if (result == true && context.mounted) {
                  setState(() {});
                }
              },
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final InsuranceProduct product;
  final bool isActive;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF008A8A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      color: Color(0xFF008A8A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.nameFr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          product.subtitleEn,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: isActive ? Colors.green[700] : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.descriptionFr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Couverture jusqu\'à ${(product.claimCapMinor / 100).toStringAsFixed(0)} CDF',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF008A8A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008A8A),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isActive ? 'Edit' : 'Activate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPoliciesTab extends StatefulWidget {
  final CoreApiService api;

  const _MyPoliciesTab({required this.api});

  @override
  State<_MyPoliciesTab> createState() => _MyPoliciesTabState();
}

class _MyPoliciesTabState extends State<_MyPoliciesTab> {
  Future<void> _deactivatePolicy(String policyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Policy'),
        content: const Text(
          'Are you sure you want to deactivate this insurance policy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await widget.api.deactivateInsurance(policyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Policy deactivated')),
        );
        setState(() {});
      }
    }
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text(
          'Claims filing will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.api.getInsurancePolicies('cust_kasee'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final policies = snapshot.data!
            .where((p) => p['active'] == true)
            .toList();

        if (policies.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No active policies',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: policies.length,
          itemBuilder: (context, index) {
            final policy = policies[index];
            final product = kInsuranceProducts.firstWhere(
              (p) => p.id == policy['productId'],
            );
            return _PolicyCard(
              policy: policy,
              product: product,
              onDeactivate: () => _deactivatePolicy(policy['id'] as String),
              onFileClaim: _showComingSoonDialog,
            );
          },
        );
      },
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final Map<String, dynamic> policy;
  final InsuranceProduct product;
  final VoidCallback onDeactivate;
  final VoidCallback onFileClaim;

  const _PolicyCard({
    required this.policy,
    required this.product,
    required this.onDeactivate,
    required this.onFileClaim,
  });

  String _getPremiumSummary() {
    final mode = policy['premiumMode'] as String;
    if (mode == 'PERCENT') {
      final bps = policy['percentBps'] as int;
      final percent = (bps / 100).toStringAsFixed(1);
      return '$percent% of transaction amount';
    } else {
      final amount = (policy['fixedMinor'] as int) / 100;
      final schedule = policy['fixedSchedule'] as String;
      if (schedule == 'MONTHLY') {
        return '${amount.toStringAsFixed(0)} CDF per month';
      } else {
        return '${amount.toStringAsFixed(0)} CDF per transaction';
      }
    }
  }

  String _getDeductFromLabel() {
    final deductFrom = policy['deductFrom'] as String;
    switch (deductFrom) {
      case 'BILL':
        return 'On bills';
      case 'SEND':
        return 'On send money';
      case 'BOTH':
        return 'On bills and send money';
      default:
        return deductFrom;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.nameFr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getPremiumSummary(),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _getDeductFromLabel(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Activated on ${DateTime.parse(policy['activatedAt'] as String).toLocal().toString().split(' ')[0]}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDeactivate,
                  child: const Text('Deactivate'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onFileClaim,
                  child: const Text('File a Claim'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
