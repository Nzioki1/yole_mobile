import 'package:flutter/material.dart';
import '../constants/poste_design_tokens.dart';

class AgentFloatCard extends StatelessWidget {
  final String cdfFloat;
  final String usdFloat;

  const AgentFloatCard({
    super.key,
    required this.cdfFloat,
    required this.usdFloat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing8,
      ),
      padding: const EdgeInsets.all(PosteDesignTokens.spacing20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PosteDesignTokens.primaryTeal, PosteDesignTokens.tealDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: PosteDesignTokens.borderRadiusMedium,
        boxShadow: PosteDesignTokens.elevation4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent Float',
            style: PosteDesignTokens.caption.copyWith(
              color: PosteDesignTokens.tealPale,
            ),
          ),
          const SizedBox(height: PosteDesignTokens.spacing8),
          Text(
            'CDF: $cdfFloat',
            style: PosteDesignTokens.amountLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: PosteDesignTokens.spacing4),
          Text(
            'USD: $usdFloat',
            style: PosteDesignTokens.amountMedium.copyWith(
              color: PosteDesignTokens.tealPale,
            ),
          ),
        ],
      ),
    );
  }
}
