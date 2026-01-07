import 'package:flutter/material.dart';

enum StatusChipVariant { success, warning, error, neutral, info }

class StatusChip extends StatelessWidget {
  final String text;
  final StatusChipVariant variant;
  final double? fontSize;

  const StatusChip({super.key, required this.text, this.variant = StatusChipVariant.neutral, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (variant) {
      case StatusChipVariant.success:
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green.shade700;
        break;
      case StatusChipVariant.warning:
        bg = Colors.orange.withValues(alpha: 0.12);
        fg = Colors.orange.shade700;
        break;
      case StatusChipVariant.error:
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red.shade700;
        break;
      case StatusChipVariant.neutral:
      default:
        bg = colors.primary.withValues(alpha: 0.10);
        fg = colors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: fontSize ?? 12)),
    );
  }
}
