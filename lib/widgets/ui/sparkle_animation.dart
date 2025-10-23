// lib/screens/widgets/ui/sparkle_animation.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// SparkleAnimation (RAINING VERSION)
/// - Particles fall downward at per-particle speed and wrap to the top when off-screen.
/// - Visible on dark and light themes, with additive-looking halo via blur + plus blend.
class SparkleAnimation extends StatefulWidget {
  final double minSize;        // smallest core radius in logical px (e.g., 1.8)
  final double maxSize;        // largest core radius (e.g., 4.0)
  final double speed;          // global speed multiplier (0.5..1.5)
  final int particleDensity;   // number of particles
  final Color particleColor;   // core color (alpha respected)

  const SparkleAnimation({
    super.key,
    this.minSize = 1.8,
    this.maxSize = 4.0,
    this.speed = 1.0,
    this.particleDensity = 160,
    this.particleColor = const Color(0xB3FFFFFF), // ~70% white
  });

  @override
  State<SparkleAnimation> createState() => _SparkleAnimationState();
}

class _Particle {
  double xPct;       // 0..100 (% of width)
  double yPct;       // 0..100 (% of height) - will advance downward
  double size;       // core radius
  double speed;      // px/sec
  double jitter;     // -1..1 x jitter factor
  double opacity;    // 0..1 base opacity
  double twinkle;    // phase 0..1 for subtle flashing

  _Particle({
    required this.xPct,
    required this.yPct,
    required this.size,
    required this.speed,
    required this.jitter,
    required this.opacity,
    required this.twinkle,
  });
}

class _SparkleAnimationState extends State<SparkleAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late List<_Particle> _ps;
  final _rand = math.Random(42);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _initParticles();
  }

  void _initParticles() {
    final minS = widget.minSize.clamp(0.5, 10.0);
    final maxS = math.max(minS + 0.2, widget.maxSize.clamp(0.7, 16.0));

    _ps = List.generate(widget.particleDensity, (_) {
      final size = minS + _rand.nextDouble() * (maxS - minS);
      // Base speed in px/sec, scaled by size a bit so larger dots fall slightly faster
      final baseSpeed = 35 + _rand.nextDouble() * 70; // 35..105
      return _Particle(
        xPct: _rand.nextDouble() * 100.0,
        yPct: _rand.nextDouble() * 100.0,
        size: size,
        speed: baseSpeed * (0.8 + 0.4 * (size - minS) / (maxS - minS + 1e-6)),
        jitter: _rand.nextDouble() * 2 - 1, // -1..1
        opacity: 0.55 + _rand.nextDouble() * 0.35, // 0.55..0.90
        twinkle: _rand.nextDouble(), // 0..1
      );
    });
  }

  @override
  void didUpdateWidget(covariant SparkleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.particleDensity != widget.particleDensity ||
        oldWidget.minSize != widget.minSize ||
        oldWidget.maxSize != widget.maxSize) {
      _initParticles();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glow = isDark ? const Color(0xFF7DD3FC) : const Color(0xFF60A5FA);

    // Use elapsed time for smooth rain motion (seconds)
    final elapsedSec = (_ctrl.lastElapsedDuration ?? Duration.zero).inMicroseconds / 1e6;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          isComplex: true,
          willChange: true,
          painter: _SparkleRainPainter(
            particles: _ps,
            coreColor: widget.particleColor,
            glowColor: glow,
            elapsedSec: elapsedSec,
            speedMultiplier: widget.speed,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _SparkleRainPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color coreColor;
  final Color glowColor;
  final double elapsedSec;
  final double speedMultiplier;

  _SparkleRainPainter({
    required this.particles,
    required this.coreColor,
    required this.glowColor,
    required this.elapsedSec,
    required this.speedMultiplier,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    final corePaint = Paint()..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    for (final p in particles) {
      // Compute current y in px: base + velocity * time
      final baseY = (p.yPct / 100.0) * h;
      final vy = p.speed * speedMultiplier; // px/sec
      double y = (baseY + vy * elapsedSec) % (h + 40); // add margin to hide wrap
      y -= 20; // start a bit above the screen when wrapping

      // Slight horizontal sway as it falls
      final sway = (p.jitter * 6.0) * (1 - (((y / h) - 0.5).abs())); // peak in middle
      final x = (p.xPct / 100.0) * w + sway;

      // Twinkle (mild flashing, always visible)
      final tw = 0.5 + 0.5 * math.sin((elapsedSec + p.twinkle) * 2.0);
      final a = (tw * p.opacity * 255).clamp(0, 255).toInt();

      final r = (p.size * (1.2 + 0.6 * dpr)).clamp(1.5, 6.5);

      glowPaint.color = glowColor.withAlpha((a * 0.7).toInt());
      canvas.drawCircle(Offset(x, y), r * 2.4, glowPaint);

      corePaint.color = coreColor.withAlpha(a);
      canvas.drawCircle(Offset(x, y), r, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleRainPainter old) =>
      old.elapsedSec != elapsedSec ||
      old.particles != particles ||
      old.coreColor != coreColor ||
      old.glowColor != glowColor ||
      old.speedMultiplier != speedMultiplier;
}
