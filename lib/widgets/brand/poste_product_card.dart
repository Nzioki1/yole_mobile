import 'package:flutter/material.dart';
import '../../constants/poste_design_tokens.dart';

class PosteProductCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onActivate;

  const PosteProductCard({
    super.key,
    required this.title,
    required this.description,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: PosteDesignTokens.spacing16,
        vertical: PosteDesignTokens.spacing8,
      ),
      padding: const EdgeInsets.all(PosteDesignTokens.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: PosteDesignTokens.borderRadiusMedium,
        border: Border.all(color: PosteDesignTokens.borderDefault),
        boxShadow: PosteDesignTokens.elevation2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PosteDesignTokens.heading3),
          const SizedBox(height: PosteDesignTokens.spacing8),
          Text(description, style: PosteDesignTokens.caption),
          const SizedBox(height: PosteDesignTokens.spacing12),
          OutlinedButton(
            onPressed: onActivate,
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }
}
