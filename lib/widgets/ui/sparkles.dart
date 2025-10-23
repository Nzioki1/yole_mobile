import 'dart:math';
import 'package:flutter/material.dart';

/// A lightweight particle background with no external dependencies.
/// Renders small circular sparkles that drift slowly.
class SparklesCore extends StatefulWidget {
  final Color background;
  final double minSize;         // min particle radius
  final double maxSize;         // max particle radius
  final double speed;           // visual drift intensity (0.1 .. 4.0 typical)
  final Color particleColor;
  final int particleDensity;    // number of particles (10 .. 2000 typical)
  final double? width;
  final double? height;

  const SparklesCore({
    super.key,
    this.background = Colors.transparent,
    this.minSize = 1.0,
    this.maxSize = 3.0,
    this.speed = 1.0,
    this.particleColor = Colors.white,
    this.particleDensity = 120,
    this.width,
    this.height,
  });

  @override
  State<SparklesCore> createState() => _SparklesCoreState();
}

class _SparklesCoreState extends State<SparklesCore> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Particle> _particles;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16000))
      ..addListener(() => setState(() {}))
      ..repeat();
    _initParticles();
  }

  void _initParticles() {
    final count = widget.particleDensity.clamp(10, 2000);
    _particles = List.generate(count, (i) {
      final radius = _rand.nextDouble() * (widget.maxSize - widget.minSize) + widget.minSize;
      // random velocity in [-speed, speed]
      final vx = (_rand.nextDouble() * 2 - 1) * widget.speed;
      final vy = (_rand.nextDouble() * 2 - 1) * widget.speed;
      return _Particle(
        radius: radius,
        vx: vx,
        vy: vy,
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
      );
    });
  }

  @override
  void didUpdateWidget(covariant SparklesCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.particleDensity != widget.particleDensity ||
        oldWidget.minSize != widget.minSize ||
        oldWidget.maxSize != widget.maxSize ||
        oldWidget.speed != widget.speed ||
        oldWidget.particleColor != widget.particleColor) {
      _initParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = CustomPaint(
      painter: _SparklesPainter(
        particles: _particles,
        color: widget.particleColor,
        progress: _controller.value,
      ),
      child: const SizedBox.expand(),
    );

    return Container(
      width: widget.width,
      height: widget.height,
      color: widget.background,
      child: child,
    );
  }
}

class _Particle {
  double x, y;   // normalized 0..1
  double vx, vy; // velocity in normalized space per animation cycle
  double radius;
  _Particle({required this.radius, required this.vx, required this.vy, required this.x, required this.y});
}

class _SparklesPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double progress;
  _SparklesPainter({required this.particles, required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    for (final p in particles) {
      // simple wrap-around movement based on controller progress
      final dx = p.vx * progress;
      final dy = p.vy * progress;
      final x = ((p.x + dx) % 1.0) * size.width;
      final y = ((p.y + dy) % 1.0) * size.height;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter old) =>
      old.particles != particles || old.color != color || old.progress != progress;
}
