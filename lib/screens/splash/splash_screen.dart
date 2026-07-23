import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/animated_particles.dart';
import '../../core/widgets/odin_logo.dart';
import '../../providers/app_providers.dart';
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
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _progressCtrl.addListener(() {
      if (mounted) setState(() => _progress = _progressCtrl.value);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    _progressCtrl.forward();

    final auth = context.read<AuthProvider>();
    final joueurData = context.read<JoueurDataProvider>();

    final results = await Future.wait([
      auth.init(),
      Future<void>.delayed(const Duration(milliseconds: 2800)),
      _onboarding.isCompleted(),
    ]);

    if (!mounted) return;

    final onboardingDone = results[2] as bool;

    if (auth.isAuthenticated && auth.user != null) {
      await joueurData.load(auth.user!);
    }

    if (!mounted) return;

    if (!onboardingDone) {
      context.go('/onboarding');
    } else if (auth.isAuthenticated) {
      context.go('/');
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
    return Scaffold(
      backgroundColor: OdinColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ParallaxOrbs(),
          const AnimatedParticles(count: 28),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: kOdinLogoHeroTag,
                  child: const Material(
                    color: Colors.transparent,
                    child: OdinLogo(width: 200, animated: false),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.85, 0.85),
                      end: const Offset(1, 1),
                      duration: 700.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 24),
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
                    .fadeIn(delay: 280.ms, duration: 500.ms)
                    .slideY(begin: 0.28, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                Text(
                  'Espace Joueur · SaaS Pro',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: OdinColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ).animate().fadeIn(delay: 420.ms, duration: 500.ms),
                const SizedBox(height: 48),
                OdinShimmerProgress(progress: _progress)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms),
                const SizedBox(height: 12),
                Text(
                  'Chargement de votre espace…',
                  style: GoogleFonts.inter(fontSize: 11, color: OdinColors.textMuted),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: 800.ms)
                    .then()
                    .fadeOut(duration: 800.ms),
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
            ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}
