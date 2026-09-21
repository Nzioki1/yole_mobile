import 'package:flutter/material.dart';
import '../constants/poste_design_tokens.dart';

class AgentReceiptCard extends StatelessWidget {
  final String title;
  final List<MapEntry<String, String>> fields;
  final VoidCallback onDone;

  const AgentReceiptCard({
    super.key,
    required this.title,
    required this.fields,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: PosteDesignTokens.borderRadiusMedium,
      ),
      child: Padding(
        padding: const EdgeInsets.all(PosteDesignTokens.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: PosteDesignTokens.accentGreen,
              size: 48,
            ),
            const SizedBox(height: PosteDesignTokens.spacing12),
            Text(title, style: PosteDesignTokens.heading2),
            const SizedBox(height: PosteDesignTokens.spacing16),
            ...fields.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: PosteDesignTokens.spacing4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: PosteDesignTokens.caption),
                  Text(entry.value, style: PosteDesignTokens.bodyBold),
                ],
              ),
            )),
            const SizedBox(height: PosteDesignTokens.spacing24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
