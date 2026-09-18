import 'package:flutter/material.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C7A53).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pie_chart,
                  size: 60,
                  color: Color(0xFF0C7A53),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Coming Soon',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0C7A53),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Track and Manage Your Spending',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Poste Finance budgeting tools will be available soon. '
                'Set spending limits, track expenses, and get insights to help you save more. '
                'Stay tuned!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _FeatureChip(
                    icon: Icons.category,
                    label: 'Categories',
                  ),
                  _FeatureChip(
                    icon: Icons.trending_down,
                    label: 'Spending Insights',
                  ),
                  _FeatureChip(
                    icon: Icons.notifications_active,
                    label: 'Alerts',
                  ),
                  _FeatureChip(
                    icon: Icons.bar_chart,
                    label: 'Reports',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C7A53).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0C7A53).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF0C7A53),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0C7A53),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
