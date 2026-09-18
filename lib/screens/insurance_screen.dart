import 'package:flutter/material.dart';

class InsuranceScreen extends StatelessWidget {
  const InsuranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance'),
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
                  color: const Color(0xFF008A8A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  size: 60,
                  color: Color(0xFF008A8A),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Coming Soon',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF008A8A),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Protect What Matters Most',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Poste Finance insurance products will be available soon. '
                'Get comprehensive coverage for your health, life, and property. '
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
                    icon: Icons.favorite,
                    label: 'Health Insurance',
                  ),
                  _FeatureChip(
                    icon: Icons.family_restroom,
                    label: 'Life Insurance',
                  ),
                  _FeatureChip(
                    icon: Icons.home,
                    label: 'Property Insurance',
                  ),
                  _FeatureChip(
                    icon: Icons.directions_car,
                    label: 'Auto Insurance',
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
        color: const Color(0xFF008A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF008A8A).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF008A8A),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF008A8A),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
