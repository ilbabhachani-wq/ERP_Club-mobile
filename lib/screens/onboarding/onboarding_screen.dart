import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../services/onboarding_service.dart';
import 'widgets/onboarding_illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _onboarding = OnboardingService();
  double _page = 0;

  static const _slides = [
    _SlideData(
      title: 'Bienvenue dans\nvotre espace pro',
      subtitle: 'La plateforme SaaS dédiée aux joueurs. Suivez votre carrière en temps réel, où que vous soyez.',
      accent: OdinColors.accent,
      illustration: OnboardingIllustration.welcome,
    ),
    _SlideData(
      title: 'Performances\n& Statistiques',
      subtitle: 'Radar FIFA, notes de match, heatmaps et objectifs de saison — tout en un seul endroit.',
      accent: OdinColors.playerCoral,
      illustration: OnboardingIllustration.stats,
    ),
    _SlideData(
      title: 'AI Coach\npersonnalisé',
      subtitle: 'Analyses IA, plans d\'entraînement sur mesure et prévention des blessures adaptés à votre profil.',
      accent: OdinColors.info,
      illustration: OnboardingIllustration.ai,
    ),
    _SlideData(
      title: 'Connecté à\nvotre club',
      subtitle: 'Planning, messages staff, documents médicaux et contrat — synchronisés avec votre organisation SaaS.',
      accent: OdinColors.success,
      illustration: OnboardingIllustration.club,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl.addListener(() {
      if (mounted) setState(() => _page = _pageCtrl.page ?? 0);
    });
  }

  Future<void> _finish() async {
    await _onboarding.markCompleted();
    if (mounted) context.go('/login');
  }

  void _next() {
    final index = _page.round();
    if (index < _slides.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 480), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _page.round().clamp(0, _slides.length - 1);
    final slide = _slides[active];
    final isLast = active == _slides.length - 1;

    return Scaffold(
      backgroundColor: OdinColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ParallaxOrbs(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _AnimatedDots(pageCount: _slides.length, currentPage: _page, color: slide.accent),
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Passer',
                          style: GoogleFonts.inter(color: OdinColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _slides.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) {
                      final delta = i - _page;
                      final opacity = (1 - delta.abs()).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Perspective3D(
                          rotateY: delta * 0.9,
                          depth: 0.0022,
                          alignment: delta > 0 ? Alignment.centerLeft : Alignment.centerRight,
                          child: Opacity(
                            opacity: opacity,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 260,
                                  child: AnimatedSlideIllustration(
                                    type: _slides[i].illustration,
                                    accent: _slides[i].accent,
                                    animate: delta.abs() < 0.5,
                                  ),
                                ),
                                const SizedBox(height: 36),
                                Column(
                                  children: [
                                    Text(
                                      _slides[i].title,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        height: 1.15,
                                        color: OdinColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      _slides[i].subtitle,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        height: 1.55,
                                        color: OdinColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: PressScale(
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: slide.accent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: slide.accent.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'Commencer' : 'Continuer',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Icon(isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots({required this.pageCount, required this.currentPage, required this.color});

  final int pageCount;
  final double currentPage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(pageCount, (i) {
        final dist = (currentPage - i).abs().clamp(0.0, 1.0);
        final active = 1 - dist;
        return AnimatedContainer(
          duration: 280.ms,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 6),
          width: 8 + 20 * active,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Color.lerp(Colors.white.withValues(alpha: 0.15), color, active),
            boxShadow: active > 0.5
                ? [BoxShadow(color: color.withValues(alpha: 0.4 * active), blurRadius: 8)]
                : null,
          ),
        );
      }),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.illustration,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final OnboardingIllustration illustration;
}
