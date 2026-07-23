import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/odin_colors.dart';

enum OnboardingIllustration { welcome, stats, ai, club }

class AnimatedSlideIllustration extends StatefulWidget {
  const AnimatedSlideIllustration({
    super.key,
    required this.type,
    required this.accent,
    required this.animate,
  });

  final OnboardingIllustration type;
  final Color accent;
  final bool animate;

  @override
  State<AnimatedSlideIllustration> createState() => _AnimatedSlideIllustrationState();
}

class _AnimatedSlideIllustrationState extends State<AnimatedSlideIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
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
        return switch (widget.type) {
          OnboardingIllustration.welcome => _WelcomeIllustration(t: _ctrl.value, accent: widget.accent),
          OnboardingIllustration.stats => _StatsIllustration(t: _ctrl.value, accent: widget.accent),
          OnboardingIllustration.ai => _AiIllustration(t: _ctrl.value, accent: widget.accent),
          OnboardingIllustration.club => _ClubIllustration(t: _ctrl.value, accent: widget.accent),
        };
      },
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration({required this.t, required this.accent});
  final double t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final float = math.sin(t * math.pi * 2) * 8;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(0, float),
          child: Container(
            width: 180,
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFFFFF4D6), accent.withValues(alpha: 0.6)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 16)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('87', style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: OdinColors.fifaStat.withValues(alpha: 0.9))),
                Text('OVR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: OdinColors.fifaStat.withValues(alpha: 0.6))),
                const SizedBox(height: 16),
                Icon(Icons.person, size: 80, color: OdinColors.fifaStat.withValues(alpha: 0.25)),
              ],
            ),
          ),
        ),
        Positioned(
          right: 20,
          top: 40 + float * 0.5,
          child: _floatingBadge(Icons.emoji_events, OdinColors.warning, t, 0),
        ),
        Positioned(
          left: 16,
          bottom: 50 - float * 0.5,
          child: _floatingBadge(Icons.trending_up, OdinColors.success, t, 0.5),
        ),
      ],
    );
  }
}

class _StatsIllustration extends StatelessWidget {
  const _StatsIllustration({required this.t, required this.accent});
  final double t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarPainter(t: t, color: accent),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: OdinColors.glassPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OdinColors.panelBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_rounded, color: accent, size: 20),
              const SizedBox(width: 8),
              const Text('+12% cette saison', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.t, required this.color});
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    const n = 6;
    final values = [0.85, 0.72, 0.9, 0.78, 0.88, 0.65];

    for (var level = 1; level <= 4; level++) {
      final r = radius * level / 4;
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * i / n);
        final p = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.06)..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    final animValues = values.map((v) => v * (0.85 + math.sin(t * math.pi * 2) * 0.05)).toList();
    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / n);
      final p = Offset(
        center.dx + radius * animValues[i] * math.cos(angle),
        center.dy + radius * animValues[i] * math.sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawPath(dataPath, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t;
}

class _AiIllustration extends StatelessWidget {
  const _AiIllustration({required this.t, required this.accent});
  final double t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final pulse = 1 + math.sin(t * math.pi * 2) * 0.06;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.scale(
          scale: pulse,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [accent, OdinColors.playerCoral]),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 30)],
          ),
          child: const Icon(Icons.auto_awesome, size: 52, color: Colors.white),
        ),
        ...List.generate(3, (i) {
          final angle = t * math.pi * 2 + i * (math.pi * 2 / 3);
          return Positioned(
            left: 140 + math.cos(angle) * 60,
            top: 140 + math.sin(angle) * 60,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: OdinColors.glassPanel,
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              child: Icon(
                [Icons.speed, Icons.favorite, Icons.psychology][i],
                size: 18,
                color: accent,
              ),
            ),
          );
        }),
        Positioned(
          bottom: 20,
          child: _TypingBubble(t),
        ),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble(this.t);
  final double t;

  @override
  Widget build(BuildContext context) {
    const text = 'Plan optimisé ✓';
    final chars = (t * 4).floor().clamp(0, text.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: OdinColors.glassRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OdinColors.panelBorder),
      ),
      child: Text(
        text.substring(0, chars),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}

class _ClubIllustration extends StatelessWidget {
  const _ClubIllustration({required this.t, required this.accent});
  final double t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.15),
                border: Border.all(color: accent, width: 2),
              ),
              child: Icon(Icons.shield_rounded, size: 48, color: accent),
            ),
            ...List.generate(4, (i) {
              final angle = t * math.pi * 0.5 + i * math.pi / 2;
              final icons = [Icons.calendar_month, Icons.chat, Icons.description, Icons.medical_services];
              return Transform.translate(
                offset: Offset(math.cos(angle) * 90, math.sin(angle) * 70),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: OdinColors.panelSolid,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OdinColors.panelBorder),
                    boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 12)],
                  ),
                  child: Icon(icons[i], size: 22, color: accent),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _syncDot(t, 0),
            Container(width: 40, height: 2, color: accent.withValues(alpha: 0.4)),
            Icon(Icons.cloud_done_rounded, color: accent, size: 20),
            Container(width: 40, height: 2, color: accent.withValues(alpha: 0.4)),
            _syncDot(t, 0.5),
          ],
        ),
        const SizedBox(height: 8),
        Text('Sync SaaS en temps réel', style: TextStyle(color: OdinColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

Widget _syncDot(double t, double offset) {
  final active = math.sin((t + offset) * math.pi * 2) > 0;
  return Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? OdinColors.success : Colors.white.withValues(alpha: 0.2),
      boxShadow: active ? [BoxShadow(color: OdinColors.success.withValues(alpha: 0.5), blurRadius: 6)] : null,
    ),
  );
}

Widget _floatingBadge(IconData icon, Color color, double t, double phase) {
  final y = math.sin((t + phase) * math.pi * 2) * 6;
  return Transform.translate(
    offset: Offset(0, y),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
  );
}
