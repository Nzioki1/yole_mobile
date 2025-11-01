import 'package:flutter/material.dart';
import 'yole_logo_custom.dart';

/// Demo widget to showcase different YOLE logo variants
class LogoDemo extends StatelessWidget {
  const LogoDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOLE Logo Variants'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Custom Paint Implementation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Light theme variants
            const Text('Light Theme Variants:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text('Light Variant: '),
                const YoleLogoLight(width: 120, height: 48),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text('Dark Variant: '),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(8),
                  child: const YoleLogoDark(width: 120, height: 48),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text('Adaptive (Light): '),
                const YoleLogoAdaptive(
                    width: 120, height: 48, isDarkTheme: false),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text('Adaptive (Dark): '),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(8),
                  child: const YoleLogoAdaptive(
                      width: 120, height: 48, isDarkTheme: true),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Different sizes
            const Text('Different Sizes:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            Row(
              children: [
                const Text('Small: '),
                const YoleLogoCustom(width: 60, height: 24),
                const SizedBox(width: 20),
                const Text('Medium: '),
                const YoleLogoCustom(width: 120, height: 48),
                const SizedBox(width: 20),
                const Text('Large: '),
                const YoleLogoCustom(width: 180, height: 72),
              ],
            ),

            const SizedBox(height: 30),

            // Path details
            const Text('Path Details:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),

            const Text('Y: M8 8L16 20L24 8H28L18 24V36H14V24L4 8H8Z'),
            const Text('O: cx="40" cy="22" r="14" stroke'),
            const Text('L: M60 8V32H76V36H56V8H60Z'),
            const Text(
                'E: M84 8V36H80V8H84ZM80 8H96V12H80V8ZM80 20H92V24H80V20ZM80 32H96V36H80V32Z'),
          ],
        ),
      ),
    );
  }
}





