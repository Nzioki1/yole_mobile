import 'package:flutter/material.dart';
import '../../constants/poste_design_tokens.dart';

class PosteQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PosteQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PosteDesignTokens.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.all(PosteDesignTokens.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: PosteDesignTokens.borderRadiusMedium,
          border: Border.all(color: PosteDesignTokens.borderDefault),
          boxShadow: PosteDesignTokens.elevation2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(PosteDesignTokens.spacing12),
              decoration: BoxDecoration(
                color: PosteDesignTokens.tealPale,
                borderRadius: PosteDesignTokens.borderRadiusSmall,
              ),
              child: Icon(
                icon,
                color: PosteDesignTokens.primaryTeal,
                size: 28,
              ),
            ),
            const SizedBox(height: PosteDesignTokens.spacing8),
            Text(
              label,
              style: PosteDesignTokens.label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
