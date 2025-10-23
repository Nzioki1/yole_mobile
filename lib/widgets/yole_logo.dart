import 'package:flutter/material.dart';

class YoleLogo extends StatelessWidget {
  const YoleLogo({
    super.key,
    this.size,                   // preferred
    this.height,                 // <- legacy alias supported
    this.isDarkTheme = true,
    this.letterSpacing = 6,
    this.fontWeight = FontWeight.w700,
    this.color,
  });

  final double? size;
  final double? height;          // some screens call `height: 64`
  final bool isDarkTheme;
  final double letterSpacing;
  final FontWeight fontWeight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? height ?? 48.0;
    final resolvedColor =
        color ?? (isDarkTheme ? Colors.white.withOpacity(0.95) : Colors.black87);

    return Text(
      'YOLE',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: resolvedSize,
        letterSpacing: letterSpacing,
        fontWeight: fontWeight,
        color: resolvedColor,
      ),
    );
  }
}
