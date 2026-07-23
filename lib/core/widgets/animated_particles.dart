import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/odin_colors.dart';

/// Particules flottantes pour splash & onboarding.
class AnimatedParticles extends StatefulWidget {
  const AnimatedParticles({
    super.key,
    this.count = 24,
    this.colors = const [OdinColors.accent, OdinColors.playerCoral, OdinColors.info],
  });

  final int count;
  final List<Color> colors;

  @override
  State<AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<AnimatedParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _particles = List.generate(widget.count, (i) {
      return _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 4 + 2,
        speed: rng.nextDouble() * 0.3 + 0.1,
        phase: rng.nextDouble() * math.pi * 2,
        color: widget.colors[i % widget.colors.length],
      );
    });
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _ParticlesPainter(_particles, _ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.color,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;
  final Color color;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.particles, this.t);
  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = (p.x + math.sin(t * math.pi * 2 * p.speed + p.phase) * 0.04) * size.width;
      final dy = ((p.y + t * p.speed * 0.15) % 1.0) * size.height;
      final opacity = 0.15 + math.sin(t * math.pi * 2 + p.phase).abs() * 0.35;
      canvas.drawCircle(
        Offset(dx, dy),
        p.size,
        Paint()..color = p.color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.t != t;
}

/// Orbes aurora animés en arrière-plan.
class AuroraOrbs extends StatefulWidget {
  const AuroraOrbs({super.key});

  @override
  State<AuroraOrbs> createState() => _AuroraOrbsState();
}

class _AuroraOrbsState extends State<AuroraOrbs> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _orb(
              alignment: Alignment(-0.8 + _ctrl.value * 0.3, -0.7),
              color: OdinColors.playerCoral.withValues(alpha: 0.18),
              size: 280,
            ),
            _orb(
              alignment: Alignment(0.9 - _ctrl.value * 0.2, 0.1),
              color: OdinColors.accent.withValues(alpha: 0.14),
              size: 240,
            ),
            _orb(
              alignment: Alignment(0.0, 0.85 - _ctrl.value * 0.1),
              color: OdinColors.info.withValues(alpha: 0.1),
              size: 200,
            ),
          ],
        );
      },
    );
  }

  Widget _orb({required Alignment alignment, required Color color, required double size}) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
