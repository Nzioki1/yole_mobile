import 'package:flutter/material.dart';
import '../constants/poste_design_tokens.dart';

class AgentActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AgentActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing4,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(PosteDesignTokens.spacing8),
          decoration: BoxDecoration(
            color: PosteDesignTokens.tealPale,
            borderRadius: PosteDesignTokens.borderRadiusSmall,
          ),
          child: Icon(
            icon,
            color: PosteDesignTokens.primaryTeal,
            size: 24,
          ),
        ),
        title: Text(label, style: PosteDesignTokens.bodyBold),
        trailing: const Icon(
          Icons.chevron_right,
          color: PosteDesignTokens.textTertiary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: PosteDesignTokens.borderRadiusMedium,
          side: const BorderSide(color: PosteDesignTokens.borderDefault),
        ),
        tileColor: Colors.white,
      ),
    );
  }
}
