import 'package:flutter/material.dart';
import '../../constants/poste_design_tokens.dart';

class PosteBalanceCard extends StatelessWidget {
  final String cdfBalance;
  final String usdBalance;
  final bool balanceVisible;
  final VoidCallback onToggleVisibility;

  const PosteBalanceCard({
    super.key,
    required this.cdfBalance,
    required this.usdBalance,
    required this.balanceVisible,
    required this.onToggleVisibility,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Balance',
                style: PosteDesignTokens.caption.copyWith(
                  color: PosteDesignTokens.tealPale,
                ),
              ),
              IconButton(
                icon: Icon(
                  balanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ],
          ),
          const SizedBox(height: PosteDesignTokens.spacing8),
          Text(
            balanceVisible ? cdfBalance : 'FC ••••••',
            style: PosteDesignTokens.amountLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: PosteDesignTokens.spacing4),
          Text(
            balanceVisible ? usdBalance : '\$ ••••••',
            style: PosteDesignTokens.amountMedium.copyWith(
              color: PosteDesignTokens.tealPale,
            ),
          ),
        ],
      ),
    );
  }
}
