import 'package:flutter/material.dart';
import '../../constants/poste_design_tokens.dart';

class PosteTxnTile extends StatelessWidget {
  final String time;
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const PosteTxnTile({
    super.key,
    required this.time,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: PosteDesignTokens.spacing16,
          vertical: PosteDesignTokens.spacing4,
        ),
        padding: const EdgeInsets.all(PosteDesignTokens.spacing12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: PosteDesignTokens.borderRadiusMedium,
          border: Border.all(color: PosteDesignTokens.borderDefault),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(PosteDesignTokens.spacing8),
              decoration: BoxDecoration(
                color: PosteDesignTokens.tealPale,
                borderRadius: PosteDesignTokens.borderRadiusSmall,
              ),
              child: Icon(
                icon,
                color: PosteDesignTokens.primaryTeal,
                size: 20,
              ),
            ),
            const SizedBox(width: PosteDesignTokens.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(time, style: PosteDesignTokens.label),
                      Text(
                        amount,
                        style: PosteDesignTokens.bodyBold.copyWith(
                          color: amount.startsWith('-')
                              ? PosteDesignTokens.accentRed
                              : PosteDesignTokens.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PosteDesignTokens.spacing4),
                  Text(title, style: PosteDesignTokens.body),
                  Text(subtitle, style: PosteDesignTokens.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
