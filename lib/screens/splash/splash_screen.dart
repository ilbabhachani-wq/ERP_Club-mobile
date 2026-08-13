import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_logo.dart';
import '../../providers/app_providers.dart';
import '../../providers/analyste_provider.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/medecin_provider.dart';
import '../../providers/preparateur_provider.dart';
import '../../providers/responsable_provider.dart';
import '../../providers/scout_provider.dart';
import '../../providers/viiv_provider.dart';
import '../../services/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final _onboarding = OnboardingService();
  late final AnimationController _progressCtrl;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _progressCtrl.addListener(() {
      if (mounted) setState(() => _progress = _progressCtrl.value);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    _progressCtrl.forward();

    final auth = context.read<AuthProvider>();

    final minFloor = Future<void>.delayed(const Duration(seconds: 2));
    final results = await Future.wait([
      auth.init(),
      _onboarding.isCompleted(),
    ]);
    await minFloor;

    if (!mounted) return;

    final onboardingDone = results[1] as bool;

    if (auth.isAuthenticated && auth.user != null) {
      final user = auth.user!;
      await context.read<AvatarProvider>().bindUser(user.email);
      try {
        if (user.isAnalyste) {
          await context.read<AnalysteDataProvider>().load();
          await context.read<ViivProvider>().load(context.read<JoueurDataProvider>());
        } else if (user.isScout) {
          await context.read<ScoutDataProvider>().load();
        } else if (user.isPreparateur) {
          await context.read<PreparateurDataProvider>().load();
        } else if (user.isResponsable) {
          await context.read<ResponsableDataProvider>().load(
                orgId: user.organization?.id,
              );
        } else if (user.isCoach) {
          await context.read<CoachProvider>().loadAll();
        } else if (user.isMedecin) {
          await context.read<MedecinProvider>().loadAll();
        } else {
          await context.read<JoueurDataProvider>().load(user);
          await context.read<ViivProvider>().load(context.read<JoueurDataProvider>());
        }
      } catch (_) {
        // Still navigate — screens can pull-to-refresh / shell safety-net will retry.
      }
    }

    if (!mounted) return;

    if (!onboardingDone) {
      context.go('/onboarding');
    } else if (auth.isAuthenticated && auth.user != null) {
      context.go(auth.user!.homeRoute);
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: OdinColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ParallaxOrbs(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const _OrbitRing(),
                      Flip3DReveal(
                        child: Hero(
                          tag: kOdinLogoHeroTag,
                          child: Material(
                            color: Colors.transparent,
                            child: OdinLogo(width: 200, animated: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ODIN ERP',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: OdinColors.textPrimary,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 500.ms)
                    .slideY(begin: 0.28, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                Text(
                  auth.isAuthenticated && auth.user != null
                      ? '${auth.user!.spaceLabel} · ODIN'
                      : 'Club OS · ODIN ERP',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: OdinColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 820.ms, duration: 500.ms),
                const SizedBox(height: 48),
                OdinShimmerProgress(progress: _progress)
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 400.ms),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Powered by ODIN',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: OdinColors.textMuted.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

/// Anneau orbital décoratif derrière le logo — tilt 3D fixe + rotation lente
/// d'un arc lumineux, seul élément en boucle continue de l'écran.
class _OrbitRing extends StatefulWidget {
  const _OrbitRing();

  @override
  State<_OrbitRing> createState() => _OrbitRingState();
}

class _OrbitRingState extends State<_OrbitRing> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Perspective3D(
      rotateX: 1.15,
      depth: 0.003,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Transform.rotate(
            angle: _ctrl.value * math.pi * 2,
            child: CustomPaint(
              size: const Size(260, 260),
              painter: _RingPainter(),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 800.ms);
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = OdinColors.accent.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi / 2.2,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + math.pi / 2.2,
          colors: [Colors.transparent, OdinColors.accent.withValues(alpha: 0.85)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => false;
}
