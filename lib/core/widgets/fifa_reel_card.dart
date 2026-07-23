import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/odin_colors.dart';
import 'fifa_card_utils.dart';

/// Carte compacte style FIFA Reels — comme capture UT pack opening.
class FifaReelCard extends StatefulWidget {
  const FifaReelCard({
    super.key,
    required this.ovr,
    this.photoUrl,
    this.playerName,
    this.showTrend = true,
    this.showTrophy = true,
    this.size = 150,
  });

  final int ovr;
  final String? photoUrl;
  final String? playerName;
  final bool showTrend;
  final bool showTrophy;
  final double size;

  @override
  State<FifaReelCard> createState() => _FifaReelCardState();
}

class _FifaReelCardState extends State<FifaReelCard> with TickerProviderStateMixin {
  late final AnimationController _shine;
  late final AnimationController _float;
  late final AnimationController _enter;
  late final AnimationController _ovr;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat(reverse: true);
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _ovr = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  }

  @override
  void dispose() {
    _shine.dispose();
    _float.dispose();
    _enter.dispose();
    _ovr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = fifaCardTier(widget.ovr);
    final w = widget.size;
    final h = widget.size * 1.28;

    return AnimatedBuilder(
      animation: Listenable.merge([_shine, _float, _enter, _ovr]),
      builder: (_, __) {
        final floatY = math.sin(_float.value * math.pi) * 6;
        final scale = 0.88 + (_enter.value * 0.12);
        final rotY = (1 - _enter.value) * -0.12 + math.sin(_float.value * math.pi) * 0.03;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotY)
            ..translate(0.0, floatY)
            ..scale(scale),
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: tier.glow.withValues(alpha: 0.45), blurRadius: 32, spreadRadius: 2),
                BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 12)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: tier.gradient.map((c) => Color(c)).toList(),
                      ),
                    ),
                  ),
                  CustomPaint(painter: _HoloStripePainter()),
                  CustomPaint(painter: _ReelShinePainter(_shine.value)),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.2),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.photoUrl != null)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 36, bottom: 28),
                        child: Image.network(
                          widget.photoUrl!,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (_, __, ___) => _silhouette(),
                        ),
                      ),
                    )
                  else
                    Positioned.fill(child: _silhouette()),
                  if (widget.showTrophy) _badge(Icons.emoji_events_rounded, top: 10, right: 10, color: const Color(0xFFD4AF37)),
                  if (widget.showTrend) _badge(Icons.trending_up_rounded, bottom: 10, left: 10, color: OdinColors.success),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          '${(widget.ovr * _ovr.value).round()}',
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: fifaStatColor,
                            height: 1,
                            letterSpacing: -1,
                            shadows: [Shadow(color: Color(0x80FFFFFF), offset: Offset(0, 1), blurRadius: 0)],
                          ),
                        ),
                        const Text(
                          'OVR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xCC1A1008),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _silhouette() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Icon(
          Icons.person,
          size: widget.size * 0.55,
          color: fifaStatColor.withValues(alpha: 0.22),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, {double? top, double? right, double? bottom, double? left, required Color color}) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

/// Fond bokeh + particules pour showcase carte FIFA.
class FifaReelShowcase extends StatefulWidget {
  const FifaReelShowcase({super.key, required this.child, this.height = 250});

  final Widget child;
  final double height;

  @override
  State<FifaReelShowcase> createState() => _FifaReelShowcaseState();
}

class _FifaReelShowcaseState extends State<FifaReelShowcase> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              ...List.generate(5, (i) {
                final t = (_ctrl.value + i * 0.2) % 1.0;
                return Positioned(
                  left: 20 + i * 55 + math.sin(t * math.pi * 2) * 12,
                  top: 30 + math.cos(t * math.pi * 2) * 20,
                  child: Container(
                    width: 40 + i * 8,
                    height: 40 + i * 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.08 + i * 0.02),
                    ),
                  ),
                );
              }),
              widget.child,
            ],
          );
        },
      ),
    );
  }
}

class _HoloStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(-0.4),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReelShinePainter extends CustomPainter {
  _ReelShinePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = -size.width * 1.2 + (size.width * 2.4 * t);
    final rect = Rect.fromLTWH(dx, 0, size.width * 0.45, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.55);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ReelShinePainter old) => old.t != t;
}
