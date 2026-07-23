import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/animations/odin_motion.dart';
import '../../../core/theme/odin_colors.dart';

enum OnboardingIllustration { welcome, stats, ai, club }

/// Dispatches to a restrained, per-slide illustration. `animate` is kept for
/// call-site compatibility with the onboarding page view (used to gate
/// off-screen slides) — each illustration runs its own continuous, calm
/// animation internally.
class AnimatedSlideIllustration extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return switch (type) {
      OnboardingIllustration.welcome => _WelcomeIllustration(accent: accent),
      OnboardingIllustration.stats => _StatsIllustration(accent: accent),
      OnboardingIllustration.ai => _AiIllustration(accent: accent),
      OnboardingIllustration.club => _ClubIllustration(accent: accent),
    };
  }
}

/// Anneau fin avec icône badge et un arc qui tourne lentement.
class _WelcomeIllustration extends StatefulWidget {
  const _WelcomeIllustration({required this.accent});
  final Color accent;

  @override
  State<_WelcomeIllustration> createState() => _WelcomeIllustrationState();
}

class _WelcomeIllustrationState extends State<_WelcomeIllustration> with SingleTickerProviderStateMixin {
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
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.accent.withValues(alpha: 0.16), width: 1.4),
            ),
          ),
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.accent.withValues(alpha: 0.26), width: 1.4),
            ),
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Transform.rotate(
                angle: _ctrl.value * math.pi * 2,
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: _ArcPainter(color: widget.accent),
                ),
              );
            },
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accent.withValues(alpha: 0.1),
              border: Border.all(color: widget.accent.withValues(alpha: 0.4), width: 1.4),
            ),
            child: Icon(Icons.workspace_premium_outlined, size: 42, color: widget.accent),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi / 3, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.color != color;
}

/// Radar de performance — tracé d'entrée puis respiration continue subtile.
class _StatsIllustration extends StatefulWidget {
  const _StatsIllustration({required this.accent});
  final Color accent;

  @override
  State<_StatsIllustration> createState() => _StatsIllustrationState();
}

class _StatsIllustrationState extends State<_StatsIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
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
      builder: (_, child) => Transform.scale(scale: 1 + _ctrl.value * 0.025, child: child),
      child: AnimatedRadarDraw(
        values: const [85, 72, 90, 78, 88, 65],
        labels: const ['TIR', 'PASSE', 'VITESSE', 'PHYSIQUE', 'DÉFENSE', 'DRIBBLE'],
        color: widget.accent,
        size: 220,
      ),
    );
  }
}

/// Graphe de nœuds — particules qui convergent en continu vers l'icône
/// centrale, comme un flux de données analysées en temps réel.
class _AiIllustration extends StatefulWidget {
  const _AiIllustration({required this.accent});
  final Color accent;

  @override
  State<_AiIllustration> createState() => _AiIllustrationState();
}

class _AiIllustrationState extends State<_AiIllustration> with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _flowCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _flowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _flowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _flowCtrl,
            builder: (_, __) => CustomPaint(
              size: const Size(220, 220),
              painter: _NodeGraphPainter(color: widget.accent, t: _flowCtrl.value),
            ),
          ),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              return Opacity(
                opacity: 0.75 + _pulseCtrl.value * 0.25,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [widget.accent, OdinColors.playerCoral]),
                    boxShadow: [BoxShadow(color: widget.accent.withValues(alpha: 0.35), blurRadius: 24)],
                  ),
                  child: const Icon(Icons.insights_outlined, size: 36, color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NodeGraphPainter extends CustomPainter {
  _NodeGraphPainter({required this.color, required this.t});
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 1.4;
    final dotPaint = Paint()..color = color.withValues(alpha: 0.6);
    final flowPaint = Paint();

    for (var i = 0; i < 4; i++) {
      final angle = -math.pi / 2 + i * (math.pi * 2 / 4);
      final node = Offset(center.dx + math.cos(angle) * 84, center.dy + math.sin(angle) * 84);
      canvas.drawLine(center, node, linePaint);
      canvas.drawCircle(node, 5, dotPaint);

      final phase = (t + i / 4) % 1.0;
      final flowPos = Offset.lerp(node, center, phase)!;
      final flowOpacity = math.sin(phase * math.pi).clamp(0.0, 1.0);
      canvas.drawCircle(flowPos, 3, flowPaint..color = color.withValues(alpha: 0.9 * flowOpacity));
    }
  }

  @override
  bool shouldRepaint(covariant _NodeGraphPainter old) => old.t != t;
}

/// Bouclier relié à des tuiles d'icônes — un balayage lumineux traverse la
/// ligne puis met en évidence chaque tuile en séquence, façon "sync live".
class _ClubIllustration extends StatefulWidget {
  const _ClubIllustration({required this.accent});
  final Color accent;

  @override
  State<_ClubIllustration> createState() => _ClubIllustrationState();
}

class _ClubIllustrationState extends State<_ClubIllustration> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _icons = [
    Icons.calendar_month_outlined,
    Icons.chat_bubble_outline,
    Icons.description_outlined,
    Icons.medical_services_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
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
        final t = _ctrl.value;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accent.withValues(alpha: 0.12),
                border: Border.all(color: widget.accent.withValues(alpha: 0.4), width: 1.4),
              ),
              child: Icon(Icons.shield_outlined, size: 38, color: widget.accent),
            ),
            SizedBox(
              width: 24,
              height: 28,
              child: CustomPaint(painter: _FlowLinePainter(color: widget.accent, t: t)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_icons.length, (i) {
                final phase = ((t * _icons.length) - i) % _icons.length;
                final glow = 1 - phase.clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: OdinColors.panelSolid,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color.lerp(OdinColors.panelBorder, widget.accent, glow)!,
                        width: 1 + glow * 0.6,
                      ),
                      boxShadow: glow > 0.05
                          ? [BoxShadow(color: widget.accent.withValues(alpha: 0.35 * glow), blurRadius: 12)]
                          : null,
                    ),
                    child: Icon(
                      _icons[i],
                      size: 20,
                      color: Color.lerp(widget.accent.withValues(alpha: 0.75), widget.accent, glow),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _FlowLinePainter extends CustomPainter {
  _FlowLinePainter({required this.color, required this.t});
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 1.4,
    );
    final travel = (t * 3) % 1.0;
    canvas.drawCircle(Offset(x, size.height * travel), 2.4, Paint()..color = color.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _FlowLinePainter old) => old.t != t;
}
