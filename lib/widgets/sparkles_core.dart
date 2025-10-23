
// lib/widgets/sparkles_core.dart (safe version)
// - Uses Ticker instead of AnimationController.unbounded
// - Avoids any Tween/lerp-based animations
// - Guards against NaN/infinite values

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SparklesCore extends StatefulWidget {
  final Color backgroundColor;
  final double? width;
  final double? height;
  final double minSize;
  final double maxSize;
  final double speed;
  final Color particleColor;
  final int particleDensity;
  final Duration fadeInDuration;
  final double? fpsLimit;
  final bool enablePushOnTap;

  const SparklesCore({
    super.key,
    this.backgroundColor = const Color(0xFF0D47A1),
    this.width,
    this.height,
    this.minSize = 1,
    this.maxSize = 3,
    this.speed = 1.0,
    this.particleColor = Colors.white,
    this.particleDensity = 120,
    this.fadeInDuration = const Duration(milliseconds: 1000),
    this.fpsLimit,
    this.enablePushOnTap = true,
  }) : assert(minSize > 0),
       assert(maxSize >= minSize),
       assert(particleDensity > 0);

  @override
  State<SparklesCore> createState() => _SparklesCoreState();
}

class _SparklesCoreState extends State<SparklesCore> with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  late List<_Particle> _particles;
  Size _lastSize = Size.zero;
  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _particles = <_Particle>[];
    _startTicker();
    _startFadeIn();
  }

  void _startTicker() {
    _ticker = createTicker((delta) {
      _elapsed += delta;
      // FPS limit
      if (widget.fpsLimit != null && widget.fpsLimit! > 0) {
        final minFrame = Duration(milliseconds: (1000 / widget.fpsLimit!).round());
        if (_elapsed < minFrame) return;
        _elapsed = Duration.zero;
      }
      if (mounted) setState(() {});
    });
    _ticker!.start();
  }

  Future<void> _startFadeIn() async {
    final start = DateTime.now();
    final total = widget.fadeInDuration.inMilliseconds.clamp(1, 1 << 30);
    while (mounted) {
      final t = (DateTime.now().difference(start).inMilliseconds / total).clamp(0.0, 1.0);
      setState(() => _opacity = t.toDouble());
      if (_opacity >= 1.0) break;
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _ensureParticles(Size size) {
    if (_lastSize == size && _particles.isNotEmpty) return;
    _lastSize = size;
    _particles = List.generate(widget.particleDensity, (_) => _randomParticle(size));
  }

  _Particle _randomParticle(Size size, {Offset? origin}) {
    final w = size.width.isFinite ? size.width : 0.0;
    final h = size.height.isFinite ? size.height : 0.0;
    final pos = origin ?? Offset(_rng.nextDouble() * w, _rng.nextDouble() * h);

    final baseSpeed = (0.1 + _rng.nextDouble() * 0.9) * (50.0 * widget.speed);
    final theta = _rng.nextDouble() * math.pi * 2;
    final vx = math.cos(theta) * baseSpeed;
    final vy = math.sin(theta) * baseSpeed;

    final sizePx = widget.minSize + _rng.nextDouble() * (widget.maxSize - widget.minSize);
    final baseOpacity = 0.1 + _rng.nextDouble() * 0.9;
    final twinkleHz = 0.1 + _rng.nextDouble() * 0.9;
    final twinklePhase = _rng.nextDouble() * math.pi * 2;

    return _Particle(
      position: pos,
      velocity: Offset(vx, vy),
      size: sizePx,
      baseOpacity: baseOpacity,
      twinkleHz: twinkleHz,
      twinklePhase: twinklePhase,
      color: widget.particleColor,
    );
  }

  void _onTapDown(TapDownDetails details, Size size) {
    if (!widget.enablePushOnTap) return;
    for (int i = 0; i < 4; i++) {
      final jitter = Offset((_rng.nextDouble() - 0.5) * 16, (_rng.nextDouble() - 0.5) * 16);
      _particles.add(_randomParticle(size, origin: details.localPosition + jitter));
    }
    final cap = (widget.particleDensity * 1.5).round();
    if (_particles.length > cap) {
      _particles.removeRange(0, _particles.length - cap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          widget.width ?? constraints.maxWidth,
          widget.height ?? constraints.maxHeight,
        );
        _ensureParticles(size);
        return CustomPaint(
          size: size,
          painter: _SparklesPainter(
            particles: _particles,
            backgroundColor: widget.backgroundColor,
            timeSeconds: DateTime.now().millisecondsSinceEpoch / 1000.0,
            canvasSize: size,
          ),
          child: const SizedBox.expand(),
        );
      },
    );

    return Opacity(
      opacity: _opacity.isFinite ? _opacity : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) _onTapDown(d, box.size);
        },
        child: child,
      ),
    );
  }
}

class _Particle {
  Offset position;
  Offset velocity;
  double size;
  double baseOpacity;
  double twinkleHz;
  double twinklePhase;
  Color color;

  _Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.baseOpacity,
    required this.twinkleHz,
    required this.twinklePhase,
    required this.color,
  });
}

class _SparklesPainter extends CustomPainter {
  final List<_Particle> particles;
  final Color backgroundColor;
  final double timeSeconds;
  final Size canvasSize;

  _SparklesPainter({
    required this.particles,
    required this.backgroundColor,
    required this.timeSeconds,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bg);

    final paint = Paint()..isAntiAlias = true;

    // integrate with a fixed timestep
    const double dt = 1 / 60.0;

    for (final p in particles) {
      var pos = p.position + p.velocity * dt;

      // wrap
      if (pos.dx < 0) pos = Offset(pos.dx + size.width, pos.dy);
      if (pos.dx > size.width) pos = Offset(pos.dx - size.width, pos.dy);
      if (pos.dy < 0) pos = Offset(pos.dx, pos.dy + size.height);
      if (pos.dy > size.height) pos = Offset(pos.dx, pos.dy - size.height);

      p.position = pos;

      final twinkle = 0.5 + 0.5 * math.sin(2 * math.pi * p.twinkleHz * timeSeconds + p.twinklePhase);
      final op = (p.baseOpacity * twinkle).clamp(0.05, 1.0);
      paint.color = p.color.withOpacity(op);

      final r = (p.size / 2).clamp(0.5, 20.0);
      canvas.drawCircle(p.position, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter oldDelegate) => true;
}
