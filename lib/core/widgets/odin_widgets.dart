import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../animations/odin_animations.dart';
import '../theme/odin_colors.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_providers.dart';
/// Fond login web — aurora + grille + étoiles + orbes + particules animées.
class LoginBackdrop extends StatefulWidget {
  const LoginBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<LoginBackdrop> createState() => _LoginBackdropState();
}

class _LoginBackdropState extends State<LoginBackdrop> with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: OdinColors.canvas),
        // Breathing radial glows
        AnimatedBuilder(
          animation: Listenable.merge([_pulse, _drift]),
          builder: (_, _) {
            final p = _pulse.value;
            final d = _drift.value * math.pi * 2;
            return Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.75 + math.sin(d) * 0.12, -0.55 + math.cos(d) * 0.08),
                      radius: 1.15 + p * 0.25,
                      colors: [
                        Color.fromRGBO(139, 92, 246, 0.22 + p * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.8 + math.cos(d * 0.8) * 0.1, -0.65 + math.sin(d * 0.7) * 0.1),
                      radius: 1.05 + (1 - p) * 0.2,
                      colors: [
                        Color.fromRGBO(192, 57, 43, 0.24 + (1 - p) * 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.7 + math.sin(d * 1.1) * 0.1, 0.8 + math.cos(d) * 0.08),
                      radius: 1.1 + p * 0.15,
                      colors: [
                        Color.fromRGBO(58, 123, 213, 0.2 + p * 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.7 + math.cos(d) * 0.1, 0.85),
                      radius: 1.0 + (1 - p) * 0.18,
                      colors: [
                        Color.fromRGBO(6, 182, 212, 0.18 + (1 - p) * 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Spinning aurora
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _spin,
            builder: (_, _) {
              return Transform.rotate(
                angle: _spin.value * 6.28318,
                child: Transform.scale(
                  scale: 1.15,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                    child: const CustomPaint(painter: _ConicAuroraPainter()),
                  ),
                ),
              );
            },
          ),
        ),
        // Soft floating orbs
        AnimatedBuilder(
          animation: _drift,
          builder: (_, _) => CustomPaint(
            painter: _FloatingOrbsPainter(_drift.value),
            size: Size.infinite,
          ),
        ),
        // Pulsing grid
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) => CustomPaint(
            painter: _LoginGridPainter(intensity: 0.7 + _pulse.value * 0.5),
            size: Size.infinite,
          ),
        ),
        const _LoginStarsLayer(),
        const _LoginParticlesLayer(),
        // Soft vignette
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.15,
              colors: [Colors.transparent, Color(0x660B0B14)],
              stops: [0.45, 1],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ConicAuroraPainter extends CustomPainter {
  const _ConicAuroraPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 1.2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0x228B5CF6),
          Color(0x28C0392B),
          Color(0x223A7BD5),
          Color(0x2206B6D4),
          Color(0x28FF7A00),
          Color(0x228B5CF6),
        ],
      ).createShader(rect);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingOrbsPainter extends CustomPainter {
  _FloatingOrbsPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final orbs = [
      (Alignment(-0.6, -0.3), const Color(0xFF8B5CF6), 90.0, 0.0),
      (Alignment(0.55, -0.45), const Color(0xFFFF7A00), 70.0, 0.33),
      (Alignment(0.4, 0.55), const Color(0xFF3B82F6), 80.0, 0.66),
      (Alignment(-0.45, 0.5), const Color(0xFF06B6D4), 60.0, 0.2),
    ];
    for (final o in orbs) {
      final phase = (t + o.$4) % 1.0;
      final bob = math.sin(phase * math.pi * 2) * 18;
      final cx = size.width * (o.$1.x * 0.5 + 0.5);
      final cy = size.height * (o.$1.y * 0.5 + 0.5) + bob;
      final r = o.$3 * (0.9 + 0.15 * math.sin(phase * math.pi * 2));
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            o.$2.withValues(alpha: 0.22),
            o.$2.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FloatingOrbsPainter oldDelegate) => oldDelegate.t != t;
}

class _LoginGridPainter extends CustomPainter {
  const _LoginGridPainter({this.intensity = 1});
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 48.0;
    final center = Offset(size.width / 2, size.height * 0.45);
    final maxDist = size.shortestSide * 0.75;

    for (var x = 0.0; x <= size.width; x += step) {
      final dist = (Offset(x, center.dy) - center).distance;
      final alpha = (1 - (dist / maxDist).clamp(0.0, 1.0)) * 0.04 * intensity;
      if (alpha <= 0.001) continue;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = 1,
      );
    }
    for (var y = 0.0; y <= size.height; y += step) {
      final dist = (Offset(center.dx, y) - center).distance;
      final alpha = (1 - (dist / maxDist).clamp(0.0, 1.0)) * 0.04 * intensity;
      if (alpha <= 0.001) continue;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LoginGridPainter oldDelegate) => oldDelegate.intensity != intensity;
}

/// Étoiles scintillantes — login web Stars().
class _LoginStarsLayer extends StatefulWidget {
  const _LoginStarsLayer();

  @override
  State<_LoginStarsLayer> createState() => _LoginStarsLayerState();
}

class _LoginStarsLayerState extends State<_LoginStarsLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<({double x, double y, double size, double phase})> _stars;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _stars = List.generate(55, (i) {
      return (
        x: (i * 47 % 100) / 100,
        y: (i * 73 % 100) / 100,
        size: 0.9 + (i % 6) * 0.35,
        phase: (i % 12) / 12.0,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return CustomPaint(
          size: size,
          painter: _StarsPainter(_stars, _ctrl.value),
        );
      },
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.stars, this.t);
  final List<({double x, double y, double size, double phase})> stars;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final opacity = 0.12 + (0.7 * (0.5 + 0.5 * math.sin((t + s.phase) * math.pi * 2)));
      final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), s.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter oldDelegate) => oldDelegate.t != t;
}

/// Particules flottantes colorées — login web Particles().
class _LoginParticlesLayer extends StatefulWidget {
  const _LoginParticlesLayer();

  @override
  State<_LoginParticlesLayer> createState() => _LoginParticlesLayerState();
}

class _LoginParticlesLayerState extends State<_LoginParticlesLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<({double x, double y, double size, double phase, Color color, double speed})> _dots;

  static const _palette = [
    Color(0xFFFF7A00),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFF22C55E),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _dots = List.generate(36, (i) {
      return (
        x: (i * 37 % 100) / 100,
        y: (i * 59 % 100) / 100,
        size: 2.0 + (i % 5) * 1.1,
        phase: (i % 10) / 10.0,
        color: _palette[i % _palette.length],
        speed: 0.6 + (i % 4) * 0.25,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return CustomPaint(
          size: size,
          painter: _ParticlesDriftPainter(_dots, _ctrl.value),
        );
      },
    );
  }
}

class _ParticlesDriftPainter extends CustomPainter {
  _ParticlesDriftPainter(this.dots, this.t);
  final List<({double x, double y, double size, double phase, Color color, double speed})> dots;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final phase = (t * d.speed + d.phase) % 1.0;
      final opacity = phase < 0.5 ? phase * 1.1 : (1 - phase) * 1.1;
      final dx = d.x * size.width + math.sin((t + d.phase) * math.pi * 2) * 12;
      final dy = ((d.y - phase * 0.35) % 1.0) * size.height;
      final paint = Paint()
        ..color = d.color.withValues(alpha: opacity.clamp(0.0, 0.75))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawCircle(Offset(dx, dy), d.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesDriftPainter oldDelegate) => oldDelegate.t != t;
}

/// Tilt 3D parallax — comme AuthShell web (rotateX/rotateY).
class LoginTiltWrapper extends StatefulWidget {
  const LoginTiltWrapper({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<LoginTiltWrapper> createState() => _LoginTiltWrapperState();
}

class _LoginTiltWrapperState extends State<LoginTiltWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _idle;
  double _px = 0;
  double _py = 0;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      onPointerMove: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(e.position);
        setState(() {
          _px = (local.dx / box.size.width - 0.5).clamp(-0.5, 0.5);
          _py = (local.dy / box.size.height - 0.5).clamp(-0.5, 0.5);
        });
      },
      onPointerUp: (_) => setState(() { _px = 0; _py = 0; }),
      child: AnimatedBuilder(
        animation: _idle,
        builder: (_, child) {
          final idleX = math.sin(_idle.value * math.pi) * 0.015;
          final rotY = (_px * 0.12 + idleX).clamp(-0.12, 0.12);
          final rotX = (-_py * 0.1).clamp(-0.1, 0.1);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(rotX)
              ..rotateY(rotY),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Carte auth web — AUTH_CARD_STYLE (AuthShell.tsx).
class AuthGlassCard extends StatefulWidget {
  const AuthGlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(28)});

  final Widget child;
  final EdgeInsets padding;

  @override
  State<AuthGlassCard> createState() => _AuthGlassCardState();
}

class _AuthGlassCardState extends State<AuthGlassCard> with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, -3 * _float.value),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: OdinColors.panelBorder),
          boxShadow: [
            BoxShadow(
              color: OdinColors.isDark ? const Color(0x66000000) : OdinColors.shadow,
              blurRadius: OdinColors.isDark ? 60 : 28,
              offset: const Offset(0, 24),
            ),
            BoxShadow(
              color: const Color(0x266366F1).withValues(alpha: OdinColors.isDark ? 0.15 : 0.08),
              blurRadius: 80,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: OdinColors.isDark ? const Color(0x8C0F1423) : OdinColors.glassRaised,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: OdinColors.isDark
                      ? const [Color(0x8C0F1423), Color(0x73101420)]
                      : [
                          OdinColors.glassRaised,
                          OdinColors.glassPanel,
                        ],
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Champ glass-input web — label au-dessus, bordure accent au focus.
class OdinGlassTextField extends StatefulWidget {
  const OdinGlassTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.validator,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  @override
  State<OdinGlassTextField> createState() => _OdinGlassTextFieldState();
}

class _OdinGlassTextFieldState extends State<OdinGlassTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _focused ? OdinColors.accent : OdinColors.textSecondary,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: OdinColors.accent.withValues(alpha: 0.32),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: widget.validator,
            autofillHints: widget.autofillHints,
            cursorColor: OdinColors.accent,
            style: TextStyle(color: OdinColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: OdinColors.textMuted, fontSize: 14),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _focused ? OdinColors.accent : OdinColors.textSecondary,
                    )
                  : null,
              filled: true,
              fillColor: _focused
                  ? (OdinColors.isDark ? const Color(0xFF1E2438) : OdinColors.glassRaised)
                  : (OdinColors.isDark ? const Color(0xB81C1C2E) : OdinColors.inputFill),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _focused ? OdinColors.accent : OdinColors.panelBorder,
                  width: _focused ? 1.6 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: OdinColors.panelBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: OdinColors.accent, width: 1.6),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: OdinColors.danger),
              ),
              errorStyle: TextStyle(color: OdinColors.danger, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fond premium — aurora animée + grille subtile.
class OdinBackdrop extends StatelessWidget {
  const OdinBackdrop({super.key, required this.child, this.showGrid = true});

  final Widget child;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    // Rebuild every screen that uses this backdrop when theme/locale flips.
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();
    final c1 = OdinColors.canvas;
    final c2 = OdinColors.canvas2;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c1, c2, c1],
            ),
          ),
        ),
        const _AuroraLayer(),
        if (showGrid) CustomPaint(painter: _GridPainter(OdinColors.gridLine)),
        child,
      ],
    );
  }
}

class _AuroraLayer extends StatefulWidget {
  const _AuroraLayer();

  @override
  State<_AuroraLayer> createState() => _AuroraLayerState();
}

class _AuroraLayerState extends State<_AuroraLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
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
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.7 + _ctrl.value * 0.2, -0.75),
                  radius: 1.1,
                  colors: [
                OdinColors.playerCoral.withValues(alpha: OdinColors.isDark ? 0.14 : 0.08),
                Colors.transparent,
              ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.85 - _ctrl.value * 0.15, 0.15),
                  radius: 0.85,
                  colors: [
                    OdinColors.accent.withValues(alpha: OdinColors.isDark ? 0.1 : 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.9),
                  radius: 0.7,
                  colors: [
                    const Color(0xFF22D3EE).withValues(alpha: OdinColors.isDark ? 0.06 : 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.color != color;
}

/// Scaffold page pro — backdrop + transition + padding safe.
class OdinPageScaffold extends StatelessWidget {
  const OdinPageScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 100),
    this.animate = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return OdinBackdrop(
      child: animate ? OdinAnimations.page(body) : body,
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.raised = false,
    this.accentColor,
    this.blur = true,
    this.clipContent = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool raised;
  final Color? accentColor;
  final bool blur;
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? OdinColors.accent;
    final radius = BorderRadius.circular(22);
    final panel = raised ? OdinColors.glassRaised : OdinColors.glassPanel;
    final panelEnd = OdinColors.isDark
        ? (raised ? const Color(0xB816162A) : const Color(0x9616162A))
        : OdinColors.panelSolid;

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: raised ? accent.withValues(alpha: 0.25) : OdinColors.panelBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: raised ? accent.withValues(alpha: OdinColors.isDark ? 0.12 : 0.08) : OdinColors.shadow,
            blurRadius: raised ? 36 : (OdinColors.isDark ? 20 : 16),
            offset: Offset(0, raised ? 14 : 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [panel, panelEnd],
        ),
      ),
      child: clipContent
          ? ClipRRect(
              borderRadius: radius,
              child: blur
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Padding(padding: padding, child: child),
                    )
                  : Padding(padding: padding, child: child),
            )
          : blur
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Padding(padding: padding, child: child),
                )
              : Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      card = AnimatedGlassCard(onTap: onTap!, child: card);
    }
    return card;
  }
}

class AnimatedGlassCard extends StatefulWidget {
  const AnimatedGlassCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class JoueurPageTransition extends StatelessWidget {
  const JoueurPageTransition({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => OdinAnimations.page(child);
}

class JoueurKpiCard extends StatelessWidget {
  const JoueurKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.color = OdinColors.accent,
    this.index = 0,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return OdinAnimations.fadeUp(
      KeyedSubtree(
        key: ValueKey('kpi-$label-$index'),
        child: GlassCard(
          accentColor: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: OdinColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      index: index,
    );
  }
}

class OvrRing extends StatelessWidget {
  const OvrRing({
    super.key,
    required this.ovr,
    this.size = 80,
    this.color = OdinColors.playerCoral,
  });

  final int ovr;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (ovr / 99).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$ovr',
                style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  color: OdinColors.textPrimary,
                ),
              ),
              Text(
                'OVR',
                style: TextStyle(
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w700,
                  color: OdinColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.color = OdinColors.playerCoral});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class OdinPrimaryButton extends StatelessWidget {
  const OdinPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient
              ? const LinearGradient(
                  colors: [OdinColors.accent, Color(0xFFE66000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gradient ? null : OdinColors.accent,
          boxShadow: [
            BoxShadow(
              color: OdinColors.accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[Icon(icon, size: 20, color: Colors.white), const SizedBox(width: 8)],
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class OdinGlassNavBar extends StatelessWidget {
  const OdinGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
    this.accentColor = OdinColors.accent,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom > 0 ? bottom : 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: OdinColors.navFill,
              border: Border.all(color: OdinColors.panelBorder),
              boxShadow: [
                BoxShadow(
                  color: OdinColors.shadow,
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemW = constraints.maxWidth / destinations.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: itemW * selectedIndex + 6,
                      width: itemW - 12,
                      top: 8,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withValues(alpha: 0.28),
                              accentColor.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(destinations.length, (i) {
                        final d = destinations[i];
                        final active = i == selectedIndex;
                        final iconData = active
                            ? (d.selectedIcon as Icon?)?.icon ?? (d.icon as Icon).icon
                            : (d.icon as Icon).icon;
                        return Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onSelected(i);
                            },
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                                color: active ? accentColor : OdinColors.textMuted,
                                letterSpacing: active ? 0.2 : 0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedScale(
                                    scale: active ? 1.08 : 1,
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutBack,
                                    child: Icon(
                                      iconData,
                                      size: 22,
                                      color: active ? accentColor : OdinColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    d.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class OdinProAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OdinProAppBar({
    super.key,
    required this.club,
    this.subtitle = 'Mon Espace',
    this.actions,
    this.showLogo = true,
    this.accentColor = OdinColors.accent,
    this.logoSize = 56,
  });

  final String club;
  final String subtitle;
  final List<Widget>? actions;
  final bool showLogo;
  final Color accentColor;
  final double logoSize;

  @override
  Size get preferredSize => Size.fromHeight(logoSize + 20);

  @override
  Widget build(BuildContext context) {
    final barH = logoSize + 20;
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: OdinColors.appBarFill,
            border: Border(
              bottom: BorderSide(color: OdinColors.accent.withValues(alpha: 0.22)),
            ),
            boxShadow: [
              BoxShadow(
                color: OdinColors.accent.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: barH,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    if (showLogo) ...[
                      Container(
                        width: logoSize,
                        height: logoSize,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: OdinColors.panelSolid,
                          border: Border.all(color: OdinColors.accent.withValues(alpha: 0.35)),
                          boxShadow: [
                            BoxShadow(
                              color: OdinColors.accent.withValues(alpha: 0.28),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/odin-logo.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subtitle.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: OdinColors.accent.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            club,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: OdinColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (actions != null) ...actions!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
