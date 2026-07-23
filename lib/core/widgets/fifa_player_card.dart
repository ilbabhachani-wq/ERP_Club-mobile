import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/odin_colors.dart';
import '../../models/player_models.dart';
import 'fifa_card_utils.dart';

/// Carte FIFA UT complète — alignée sur FifaPlayerCard.tsx
class FifaPlayerCard extends StatefulWidget {
  const FifaPlayerCard({
    super.key,
    required this.name,
    required this.position,
    required this.ovr,
    required this.age,
    required this.radar,
    this.number = '—',
    this.nationality = '',
    this.flag = '',
    this.club = 'FC Carthage',
    this.photoUrl,
    this.badge,
    this.onPhotoTap,
    this.compact = false,
    this.width = 220,
  });

  final String name;
  final String position;
  final int ovr;
  final int age;
  final PlayerRadar radar;
  final String number;
  final String nationality;
  final String flag;
  final String club;
  final String? photoUrl;
  final String? badge;
  final VoidCallback? onPhotoTap;
  final bool compact;
  final double width;

  @override
  State<FifaPlayerCard> createState() => _FifaPlayerCardState();
}

class _FifaPlayerCardState extends State<FifaPlayerCard> with TickerProviderStateMixin {
  late final AnimationController _shine;
  late final AnimationController _enter;
  late final AnimationController _float;
  bool _photoFailed = false;

  @override
  void initState() {
    super.initState();
    _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 550))..forward();
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shine.dispose();
    _enter.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = fifaCardTier(widget.ovr);
    final attr = getFifaAttributes(widget.radar);
    final displayName = formatFifaName(widget.name);
    final initials = getInitials(widget.name);
    final w = widget.width;
    final h = w * 1.5;
    final s = w / 220;
    final showPhoto = widget.photoUrl != null && !_photoFailed;

    final statRows = [
      (attr.pac, 'PAC', attr.dri, 'DRI'),
      (attr.sho, 'SHO', attr.def, 'DEF'),
      (attr.pas, 'PAS', attr.phy, 'PHY'),
    ];

    return GestureDetector(
      onTap: widget.onPhotoTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shine, _enter, _float]),
        builder: (_, __) {
          final scale = 0.94 + (_enter.value * 0.06);
          final rotY = (1 - _enter.value) * -0.1;
          final floatY = math.sin(_float.value * math.pi) * 4 * s;

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
                boxShadow: [
                  BoxShadow(color: tier.glow.withValues(alpha: 0.35), blurRadius: 28 * s, spreadRadius: 2),
                  BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 32 * s, offset: Offset(0, 14 * s)),
                ],
              ),
              child: CustomPaint(
                foregroundPainter: _UtShinePainter(_shine.value),
                child: ClipPath(
                  clipper: _FifaClipper(),
                  child: Stack(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: tier.gradient.map((c) => Color(c)).toList(),
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                      CustomPaint(painter: _UtStripePainter(), size: Size.infinite),
                      CustomPaint(painter: _UtDiagonalStripePainter(), size: Size.infinite),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 108,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [const Color(0x338C5505), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                          ),
                        ),
                      ),
                      if (showPhoto)
                        Positioned(
                          top: -18 * s,
                          left: w * -0.03,
                          right: w * -0.03,
                          bottom: 108 * s + 34 * s,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 22 * s, offset: Offset(0, 14 * s)),
                              ],
                            ),
                            child: Image.network(
                              widget.photoUrl!,
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              errorBuilder: (_, __, ___) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) setState(() => _photoFailed = true);
                                });
                                return _silhouette(initials, s);
                              },
                            ),
                          ),
                        )
                      else
                        Positioned(
                          top: 20 * s,
                          left: 0,
                          right: 0,
                          bottom: 108 * s + 34 * s,
                          child: _silhouette(initials, s),
                        ),
                      if (widget.number != '—')
                        Positioned(
                          top: 14 * s,
                          right: 16 * s,
                          child: Text(
                            widget.number,
                            style: TextStyle(
                              fontSize: 22 * s,
                              fontWeight: FontWeight.w900,
                              color: fifaStatColor,
                              shadows: const [Shadow(color: Color(0x80FFFFFF), offset: Offset(0, 1))],
                            ),
                          ),
                        ),
                      if (widget.badge != null)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: OdinColors.playerCoral.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
                            ),
                            child: Text(
                              widget.badge!,
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(begin: 1, end: 1.06, duration: 1200.ms, curve: Curves.easeInOut)
                              .fade(begin: 1, end: 0.85, duration: 1200.ms),
                        ),
                      Positioned(
                        top: 16 * s,
                        left: 18 * s,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.ovr}',
                              style: TextStyle(
                                fontSize: 48 * s,
                                fontWeight: FontWeight.w900,
                                color: fifaStatColor,
                                height: 1,
                                letterSpacing: -1,
                                shadows: const [Shadow(color: Color(0x80FFFFFF), offset: Offset(0, 1))],
                              ),
                            ),
                            Text(
                              widget.position,
                              style: TextStyle(
                                fontSize: 14 * s,
                                fontWeight: FontWeight.w800,
                                color: fifaStatColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 18 * s,
                        right: 18 * s,
                        top: h * 0.38,
                        child: Column(
                          children: [
                            for (final row in statRows) ...[
                              _statRow(row.$1, row.$2, row.$3, row.$4, s),
                              if (row != statRows.last) SizedBox(height: 10 * s),
                            ],
                          ],
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 30 * s,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.flag.isNotEmpty)
                                  Text(widget.flag, style: TextStyle(fontSize: 16 * s)),
                                if (widget.flag.isNotEmpty) SizedBox(width: 12 * s),
                                _leagueLogo(s),
                                SizedBox(width: 12 * s),
                                _clubLogo(s),
                              ],
                            ),
                            SizedBox(height: 10 * s),
                            Text(
                              displayName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20 * s,
                                fontWeight: FontWeight.w800,
                                color: fifaStatColor,
                                letterSpacing: 0.5,
                                shadows: const [Shadow(color: Color(0x73FFFFFF), offset: Offset(0, 1))],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _silhouette(String initials, double s) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 120 * s,
        height: 120 * s,
        margin: EdgeInsets.only(bottom: 8 * s),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [Colors.white.withValues(alpha: 0.35), const Color(0x0F502D00)],
          ),
          border: Border.all(color: const Color(0x1A2A1805), width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 42 * s,
            fontWeight: FontWeight.w900,
            color: fifaStatColor.withValues(alpha: 0.28),
          ),
        ),
      ),
    );
  }

  Widget _leagueLogo(double s) {
    return Container(
      width: 20 * s,
      height: 20 * s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: OdinColors.red,
        border: Border.all(color: const Color(0xFF8B0000)),
      ),
      alignment: Alignment.center,
      child: Text('L1', style: TextStyle(fontSize: 7 * s, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }

  Widget _clubLogo(double s) {
    return CustomPaint(size: Size(22 * s, 26 * s), painter: _ClubShieldPainter());
  }

  Widget _statRow(int left, String lLabel, int right, String rLabel, double s) {
    return Row(
      children: [
        Expanded(child: _statCell(left, lLabel, TextAlign.left, s)),
        Expanded(child: _statCell(right, rLabel, TextAlign.right, s)),
      ],
    );
  }

  Widget _statCell(int value, String label, TextAlign align, double s) {
    return Row(
      mainAxisAlignment: align == TextAlign.left ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (align == TextAlign.right) ...[
          Text(label, style: _statLabel(s)),
          SizedBox(width: 4 * s),
        ],
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Text('$v', style: _statValue(s)),
        ),
        if (align == TextAlign.left) ...[
          SizedBox(width: 4 * s),
          Text(label, style: _statLabel(s)),
        ],
      ],
    );
  }

  static TextStyle _statValue(double s) => TextStyle(
        fontSize: 12 * s,
        fontWeight: FontWeight.w900,
        color: fifaStatColor,
        shadows: const [Shadow(color: Color(0x73FFFFFF), offset: Offset(0, 1))],
      );

  static TextStyle _statLabel(double s) => TextStyle(fontSize: 8 * s, fontWeight: FontWeight.w700, color: const Color(0xC71A1008));
}

class _FifaClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.06, h * 0.02)
      ..lineTo(w * 0.94, h * 0.02)
      ..lineTo(w, h * 0.07)
      ..lineTo(w, h * 0.67)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.67)
      ..lineTo(0, h * 0.07)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _UtStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripe = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(-0.35),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), stripe);

    final glow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.6),
        radius: 0.55,
        colors: [Colors.white.withValues(alpha: 0.5), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UtDiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const step = 24.0;
    for (var d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UtShinePainter extends CustomPainter {
  _UtShinePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = (t * 1.8) % 1.0;
    if (phase > 0.55) return;
    final dx = -size.width * 1.2 + (size.width * 2.4 * (phase / 0.55));
    final rect = Rect.fromLTWH(dx, 0, size.width * 0.4, size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.35);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_UtShinePainter oldDelegate) => oldDelegate.t != t;
}

class _ClubShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 1)
      ..lineTo(size.width - 2, size.height * 0.22)
      ..lineTo(size.width - 2, size.height * 0.55)
      ..quadraticBezierTo(size.width / 2, size.height - 1, 2, size.height * 0.55)
      ..lineTo(2, size.height * 0.22)
      ..close();
    canvas.drawPath(path, Paint()..color = OdinColors.playerCoral);
    canvas.drawPath(path, Paint()..color = OdinColors.red..style = PaintingStyle.stroke..strokeWidth = 1);
    final tp = TextPainter(
      text: const TextSpan(text: 'FCC', style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: Colors.white)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.38));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fond bokeh animé pour mettre en valeur la carte UT (sans clipping).
class FifaCardShowcase extends StatefulWidget {
  const FifaCardShowcase({super.key, required this.child, this.height = 320});

  final Widget child;
  final double height;

  @override
  State<FifaCardShowcase> createState() => _FifaCardShowcaseState();
}

class _FifaCardShowcaseState extends State<FifaCardShowcase> with SingleTickerProviderStateMixin {
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
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ...List.generate(6, (i) {
                final t = (_ctrl.value + i * 0.17) % 1.0;
                return Positioned(
                  left: 24 + i * 48 + math.sin(t * math.pi * 2) * 14,
                  top: 40 + math.cos(t * math.pi * 2) * 18,
                  child: Container(
                    width: 36 + i * 10,
                    height: 36 + i * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF7A00).withValues(alpha: 0.06 + i * 0.018),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: widget.child,
              ),
            ],
          );
        },
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  RadarChartPainter({
    required this.values,
    required this.labels,
    this.color = OdinColors.playerCoral,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 24;
    final n = values.length;
    if (n < 3) return;

    final gridPaint = Paint()
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
      canvas.drawPath(path, gridPaint);
    }

    final dataPath = Path();
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / n);
      final v = (values[i] / 100).clamp(0.0, 1.0);
      final p = Offset(
        center.dx + radius * v * math.cos(angle),
        center.dy + radius * v * math.sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(p.dx, p.dy);
      } else {
        dataPath.lineTo(p.dx, p.dy);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) => true;
}
