import 'package:flutter/material.dart';

/// Reusable gradient primary button used across the app.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.height = 48,
    this.borderRadius = 16,
    this.gradient,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double height;
  final double borderRadius;
  final Gradient? gradient;
  final bool enabled;

  static const LinearGradient _defaultGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF3E8BFF), // brand blue
      Color(0xFF7B4DFF), // brand purple
    ],
  );

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? _defaultGradient;
    final isEnabled = enabled && onPressed != null;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: isEnabled ? onPressed : null,
            child: Center(
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: Colors.white.withOpacity(isEnabled ? 1 : 0.6),
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
