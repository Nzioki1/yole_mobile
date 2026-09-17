import 'package:flutter/material.dart';

/// Honesty banner when running with `--dart-define=OFFLINE_DEMO=true`.
///
/// Exact copy: `Offline demo — no live API`
/// Duplicated from customer app (agent is a separate package).
class OfflineDemoBanner extends StatelessWidget {
  static const bool offlineDemo =
      bool.fromEnvironment('OFFLINE_DEMO', defaultValue: false);

  /// Exact user-visible honesty string (do not change without product sign-off).
  static const String bannerText = 'Offline demo — no live API';

  final Widget child;

  const OfflineDemoBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!offlineDemo) return child;

    return Column(
      children: [
        Material(
          color: const Color(0xFFFFC107), // amber warning
          elevation: 1,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  bannerText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF212121),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
