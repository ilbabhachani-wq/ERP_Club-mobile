import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/odin_colors.dart';

/// Hero tag partagé splash → login.
const kOdinLogoHeroTag = 'odin-app-logo';

/// Hero tag carte FIFA.
const kFifaCardHeroTag = 'odin-player-card';

/// Curves SaaS — jamais linear.
abstract final class OdinCurves {
  static const entrance = Curves.easeOutCubic;
  static const pop = Curves.easeOutBack;
  static const micro = Curves.easeOut;
}

/// Rotation 3D avec perspective — réutilisée pour les révélations "flip"
/// (splash, login, onboarding) sans dépendance à un moteur 3D externe.
class Perspective3D extends StatelessWidget {
  const Perspective3D({
    super.key,
    required this.child,
    this.rotateX = 0,
    this.rotateY = 0,
    this.depth = 0.0016,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double rotateX;
  final double rotateY;
  final double depth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: alignment,
      transform: Matrix4.identity()
        ..setEntry(3, 2, depth)
        ..rotateX(rotateX)
        ..rotateY(rotateY),
      child: child,
    );
  }
}

/// Révélation "flip" 3D au montage — fondu + rotation en profondeur, une
/// seule fois, sans animation continue (sûr pour les widgets Hero partagés
/// entre écrans, ex. splash → login).
class Flip3DReveal extends StatelessWidget {
  const Flip3DReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
    this.angle = 1.3,
    this.depth = 0.0022,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final double angle;
  final double depth;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: 1 - value,
          child: Perspective3D(rotateY: value * angle, depth: depth, child: child!),
        );
      },
      child: child,
    );
  }
}

/// Count-up entier 0 → value.
class CountUpInt extends StatelessWidget {
  const CountUpInt({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix = '',
    this.suffix = '',
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: OdinCurves.entrance,
      builder: (_, v, __) => Text('$prefix$v$suffix', style: style),
    );
  }
}

/// Progress bar shimmer (splash / boot).
class OdinShimmerProgress extends StatelessWidget {
  const OdinShimmerProgress({
    super.key,
    this.width = 200,
    this.height = 4,
    this.progress,
  });

  final double width;
  final double height;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            ColoredBox(color: Colors.white.withValues(alpha: 0.08)),
            if (progress != null)
              FractionallySizedBox(
                widthFactor: progress!.clamp(0.05, 1.0),
                child: Shimmer.fromColors(
                  baseColor: OdinColors.accent,
                  highlightColor: OdinColors.playerCoral.withValues(alpha: 0.9),
                  period: const Duration(milliseconds: 1200),
                  child: const ColoredBox(color: Colors.white),
                ),
              )
            else
              Shimmer.fromColors(
                baseColor: OdinColors.accent.withValues(alpha: 0.55),
                highlightColor: OdinColors.playerCoral,
                period: const Duration(milliseconds: 1200),
                child: const ColoredBox(color: Colors.white),
              ),
          ],
        ),
      ),
    );
    return bar;
  }
}

/// Skeleton shimmer SaaS (Stripe/Linear style).
class OdinSkeleton extends StatelessWidget {
  const OdinSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 10,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1C1C2E),
      highlightColor: const Color(0xFF2A2A40),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class OdinPageSkeleton extends StatelessWidget {
  const OdinPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OdinSkeleton(width: 140, height: 14),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: OdinSkeleton(height: 88, radius: 16)),
              SizedBox(width: 12),
              Expanded(child: OdinSkeleton(height: 88, radius: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: OdinSkeleton(height: 88, radius: 16)),
              SizedBox(width: 12),
              Expanded(child: OdinSkeleton(height: 88, radius: 16)),
            ],
          ),
          const SizedBox(height: 20),
          const OdinSkeleton(width: 120, height: 14),
          const SizedBox(height: 12),
          const OdinSkeleton(height: 200, radius: 18),
        ],
      ),
    );
  }
}

/// Shake horizontal — erreur login.
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({super.key, required this.child});

  final Widget child;

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  void shake() => _ctrl.forward(from: 0);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        final offset = math.sin(t * math.pi * 6) * 8 * (1 - t);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Bouton morph → spinner circulaire.
class MorphLoadingButton extends StatelessWidget {
  const MorphLoadingButton({
    super.key,
    required this.loading,
    required this.label,
    required this.onPressed,
    this.color = OdinColors.accent,
  });

  final bool loading;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: loading ? null : onPressed,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final expandedWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOut,
              width: loading ? 52 : expandedWidth,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, OdinColors.accentStrong, 0.4)!],
                ),
                borderRadius: BorderRadius.circular(loading ? 26 : 14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: loading ? 12 : 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Micro-interaction scale 0.96 au tap.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, required this.onTap, this.scale = 0.96});

  final Widget child;
  final VoidCallback onTap;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  double _s = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _s = widget.scale),
      onTapUp: (_) {
        setState(() => _s = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _s = 1),
      child: AnimatedScale(
        scale: _s,
        duration: const Duration(milliseconds: 120),
        curve: OdinCurves.micro,
        child: widget.child,
      ),
    );
  }
}

/// Digit countdown qui roll.
class RollingDigit extends StatelessWidget {
  const RollingDigit({super.key, required this.value, required this.label, this.style});

  final String value;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            transitionBuilder: (child, anim) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero).animate(
                  CurvedAnimation(parent: anim, curve: OdinCurves.entrance),
                ),
                child: FadeTransition(opacity: anim, child: child),
              );
            },
            child: Text(
              value,
              key: ValueKey(value),
              style: style ??
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: OdinColors.textPrimary),
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 11, color: OdinColors.textMuted)),
        ],
      ),
    );
  }
}

/// Arc gauge type Apple Watch.
class AnimatedArcGauge extends StatelessWidget {
  const AnimatedArcGauge({
    super.key,
    required this.value,
    required this.label,
    this.size = 140,
    this.lowColor = OdinColors.danger,
    this.highColor = OdinColors.success,
  });

  final double value; // 0–100
  final String label;
  final double size;
  final Color lowColor;
  final Color highColor;

  @override
  Widget build(BuildContext context) {
    final t = (value / 100).clamp(0.0, 1.0);
    final color = Color.lerp(lowColor, highColor, t)!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: t),
      duration: const Duration(milliseconds: 1000),
      curve: OdinCurves.entrance,
      builder: (_, v, __) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ArcGaugePainter(progress: v, color: color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(v * 100).round()}%',
                    style: TextStyle(fontSize: size * 0.18, fontWeight: FontWeight.w900, color: color),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: size * 0.08, fontWeight: FontWeight.w700, color: OdinColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  _ArcGaugePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const start = -math.pi * 0.75;
    const sweep = math.pi * 1.5;

    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep * progress, false, fg);
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) => old.progress != progress || old.color != color;
}

/// Radar qui se trace progressivement.
class AnimatedRadarDraw extends StatefulWidget {
  const AnimatedRadarDraw({
    super.key,
    required this.values,
    this.labels = const [],
    this.color = OdinColors.playerCoral,
    this.size = 240,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double size;

  @override
  State<AnimatedRadarDraw> createState() => _AnimatedRadarDrawState();
}

class _AnimatedRadarDrawState extends State<AnimatedRadarDraw> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (_, __) {
        final scaled = widget.values.map((v) => v * _progress.value.clamp(0.0, 1.0)).toList();
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ProgressRadarPainter(
            values: scaled,
            labels: widget.labels,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _ProgressRadarPainter extends CustomPainter {
  _ProgressRadarPainter({required this.values, required this.labels, required this.color});

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 28;
    final n = values.length;
    if (n < 3) return;

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke;

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
      canvas.drawPath(path, grid);
    }

    final data = Path();
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / n);
      final v = (values[i] / 100).clamp(0.0, 1.0);
      final p = Offset(center.dx + radius * v * math.cos(angle), center.dy + radius * v * math.sin(angle));
      if (i == 0) {
        data.moveTo(p.dx, p.dy);
      } else {
        data.lineTo(p.dx, p.dy);
      }
    }
    data.close();
    canvas.drawPath(data, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawPath(
      data,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    if (labels.length == n) {
      for (var i = 0; i < n; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * i / n);
        final p = Offset(
          center.dx + (radius + 18) * math.cos(angle),
          center.dy + (radius + 18) * math.sin(angle),
        );
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: OdinColors.textMuted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRadarPainter old) => true;
}

/// Badge LIVE pulsant.
class LivePulseBadge extends StatelessWidget {
  const LivePulseBadge({super.key, this.label = 'LIVE'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: OdinColors.success.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OdinColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 8, color: OdinColors.success),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: OdinColors.success, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 1, end: 0.45, duration: 1500.ms, curve: Curves.easeInOut);
  }
}

/// Parallax orbs lents (splash / login).
class ParallaxOrbs extends StatefulWidget {
  const ParallaxOrbs({super.key});

  @override
  State<ParallaxOrbs> createState() => _ParallaxOrbsState();
}

class _ParallaxOrbsState extends State<ParallaxOrbs> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 28))..repeat();
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
        final t = _ctrl.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: 80 + math.sin(t) * 18,
              left: 30 + math.cos(t) * 12,
              child: _orb(280, OdinColors.playerCoral.withValues(alpha: 0.22)),
            ),
            Positioned(
              bottom: 160 + math.cos(t) * 22,
              right: -40 + math.sin(t * 0.8) * 14,
              child: _orb(320, OdinColors.info.withValues(alpha: 0.14)),
            ),
            Positioned(
              top: 280 + math.sin(t * 1.2) * 12,
              right: 40,
              child: _orb(180, OdinColors.accent.withValues(alpha: 0.12)),
            ),
          ],
        );
      },
    );
  }

  Widget _orb(double size, Color color) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
