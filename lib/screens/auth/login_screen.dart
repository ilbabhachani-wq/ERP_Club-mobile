import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_logo.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';
import '../../providers/analyste_provider.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/medecin_provider.dart';
import '../../providers/coach_provider.dart';
import '../../providers/preparateur_provider.dart';
import '../../providers/responsable_provider.dart';
import '../../providers/scout_provider.dart';
import '../../providers/viiv_provider.dart';

const _featureTags = ['IA', 'Analyse', 'Performance', 'Recrutement'];

bool _isMedecinLogin(String role, String email) {
  final r = role.toUpperCase();
  final e = email.toLowerCase();
  return r == 'MEDICAL' ||
      r == 'MEDECIN' ||
      r == 'MEDECIN_CLUB' ||
      r == 'DOCTOR' ||
      e == 'asmamed@odin.tn';
}

bool _isCoachLogin(String role, String email) {
  final r = role.toUpperCase();
  final e = email.toLowerCase();
  return r == 'COACH' ||
      r == 'ENTRAINEUR' ||
      r == 'ENTRAÎNEUR' ||
      e == 'roccocoach@gmail.com';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  bool _booted = false;
  bool _showAuthOverlay = false;
  String _roleLabel = 'Espace Club';
  String _clubName = 'ODIN Club';
  String? _pendingRoute;

  static const _authSteps = [
    'Connexion...',
    'Authentification...',
    'Chargement IA...',
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _booted = true);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      final user = auth.user!;
      await context.read<AvatarProvider>().bindUser(user.email);
      if (!mounted) return;
      if (user.isAnalyste) {
        await context.read<AnalysteDataProvider>().load();
        if (!mounted) return;
        await context.read<ViivProvider>().load(context.read<JoueurDataProvider>());
      } else if (user.isScout) {
        await context.read<ScoutDataProvider>().load();
      } else if (user.isPreparateur) {
        await context.read<PreparateurDataProvider>().load();
      } else if (user.isResponsable) {
        await context.read<ResponsableDataProvider>().load(
              orgId: user.organization?.id,
            );
      } else if (_isMedecinLogin(user.role, user.email)) {
        await context.read<MedecinProvider>().loadAll();
      } else if (_isCoachLogin(user.role, user.email)) {
        await context.read<CoachProvider>().loadAll();
      } else {
        await context.read<JoueurDataProvider>().load(user);
        if (!mounted) return;
        await context.read<ViivProvider>().load(context.read<JoueurDataProvider>());
      }
      if (!mounted) return;
      final isMedecin = _isMedecinLogin(user.role, user.email);
      final isCoach = _isCoachLogin(user.role, user.email);
      setState(() {
        _roleLabel = user.isAnalyste
            ? 'Espace Analyste'
            : user.isScout
                ? 'Espace Scout'
                : user.isPreparateur
                    ? 'Espace Préparateur'
                    : user.isResponsable
                        ? 'Espace Responsable'
                        : isMedecin
                            ? 'Espace Médecin'
                            : isCoach
                                ? 'Espace Coach'
                                : 'Espace Joueur';
        _clubName = user.organization?.clubName ?? 'ODIN Club';
        _pendingRoute = isMedecin
            ? '/medecin/dossiers'
            : isCoach
                ? '/coach/entrainements'
                : user.homeRoute;
        _showAuthOverlay = true;
      });
    } else {
      _shakeKey.currentState?.shake();
      if (auth.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.error!),
            backgroundColor: OdinColors.danger,
          ),
        );
      }
    }
  }

  void _onAuthOverlayDone() {
    final route = _pendingRoute;
    if (route != null && mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final loggingIn = context.select<AuthProvider, bool>((a) => a.loggingIn);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
      backgroundColor: OdinColors.canvas,
      body: Stack(
        children: [
          LoginBackdrop(
            child: SafeArea(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _booted ? 1 : 0,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: LoginTiltWrapper(
                        enabled: _booted && !_showAuthOverlay,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Hero(
                              tag: kOdinLogoHeroTag,
                              child: const Material(
                                color: Colors.transparent,
                                child: OdinLogo(width: 220, animated: false),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic),
                            const SizedBox(height: 10),
                            Text(
                              'Football Intelligence Platform',
                              style: TextStyle(
                                color: OdinColors.accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.5,
                                fontSize: 11,
                              ),
                            )
                                .animate(delay: 80.ms)
                                .fadeIn(duration: 420.ms)
                                .slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 8),
                             Text(
                              'Espace Club • SaaS Pro',
                              style: TextStyle(
                                color: OdinColors.textMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                fontSize: 13,
                              ),
                            )
                                .animate(delay: 160.ms)
                                .fadeIn(duration: 420.ms)
                                .slideY(begin: 0.2, end: 0),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: _featureTags.asMap().entries.map((e) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: OdinColors.panelBorder),
                                    color: OdinColors.inputFill,
                                  ),
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: OdinColors.textSecondary,
                                    ),
                                  ),
                                )
                                    .animate(delay: (240 + e.key * 80).ms)
                                    .fadeIn()
                                    .slideY(begin: 0.25, end: 0);
                              }).toList(),
                            ),
                            const SizedBox(height: 28),
                            ShakeWidget(
                              key: _shakeKey,
                              child: AuthGlassCard(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Connexion',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                          color: OdinColors.textPrimary,
                                        ),
                                      )
                                          .animate(delay: 320.ms)
                                          .fadeIn()
                                          .slideX(begin: -0.08, end: 0),
                                      const SizedBox(height: 6),
                                       Text(
                                        'Accédez à votre espace personnel',
                                        style: TextStyle(color: OdinColors.textMuted, fontSize: 14, height: 1.4),
                                      ),
                                      const SizedBox(height: 24),
                                      OdinGlassTextField(
                                        label: 'Email',
                                        controller: _email,
                                        hint: 'joueur@club.com',
                                        prefixIcon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [AutofillHints.email],
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) return 'Email requis';
                                          if (!v.contains('@')) return 'Email invalide';
                                          return null;
                                        },
                                      )
                                          .animate(delay: 400.ms)
                                          .fadeIn()
                                          .slideY(begin: 0.2, end: 0),
                                      const SizedBox(height: 18),
                                      OdinGlassTextField(
                                        label: 'Mot de passe',
                                        controller: _password,
                                        prefixIcon: Icons.lock_outline,
                                        obscureText: true,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [AutofillHints.password],
                                        onFieldSubmitted: (_) => _submit(),
                                        validator: (v) => v == null || v.isEmpty ? 'Mot de passe requis' : null,
                                      )
                                          .animate(delay: 480.ms)
                                          .fadeIn()
                                          .slideY(begin: 0.2, end: 0),
                                      const SizedBox(height: 28),
                                      MorphLoadingButton(
                                        loading: loggingIn || _showAuthOverlay,
                                        label: 'Se connecter',
                                        onPressed: (loggingIn || _showAuthOverlay) ? null : _submit,
                                      )
                                          .animate(delay: 560.ms)
                                          .fadeIn()
                                          .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
                                    ],
                                  ),
                                ),
                              ),
                            )
                                .animate(delay: 280.ms)
                                .fadeIn(duration: 500.ms)
                                .slideY(begin: 0.08, end: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!_booted)
            Container(
              color: OdinColors.canvas,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OdinLogo(width: 240, animated: false),
                    SizedBox(height: 20),
                    OdinShimmerProgress(width: 220),
                  ],
                ),
              ),
            ).animate().fadeOut(delay: 700.ms, duration: 400.ms),
          if (_showAuthOverlay)
            _AuthSuccessOverlay(
              roleLabel: _roleLabel,
              clubName: _clubName,
              steps: _authSteps,
              onDone: _onAuthOverlayDone,
            ),
        ],
      ),
    ),
    );
  }
}

/// Overlay post-login aligné web (`AuthOverlay` LoginPage.tsx).
class _AuthSuccessOverlay extends StatefulWidget {
  const _AuthSuccessOverlay({
    required this.roleLabel,
    required this.clubName,
    required this.steps,
    required this.onDone,
  });

  final String roleLabel;
  final String clubName;
  final List<String> steps;
  final VoidCallback onDone;

  @override
  State<_AuthSuccessOverlay> createState() => _AuthSuccessOverlayState();
}

class _AuthSuccessOverlayState extends State<_AuthSuccessOverlay> {
  int _step = 0;
  bool _welcome = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _step = 1);
    });
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _step = 2);
    });
    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _welcome = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 2900), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xE60D0D18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Center(
            child: AnimatedSwitcher(
              duration: 350.ms,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: !_welcome
                  ? Column(
                      key: const ValueKey('loading'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const OdinLogo(width: 200, animated: false),
                        const SizedBox(height: 20),
                        Text(
                          widget.roleLabel,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: OdinColors.accent),
                            ),
                            const SizedBox(width: 10),
                            AnimatedSwitcher(
                              duration: 280.ms,
                              child: Text(
                                widget.steps[_step.clamp(0, widget.steps.length - 1)],
                                key: ValueKey(_step),
                                style: TextStyle(color: OdinColors.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 208,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: 1900.ms,
                              curve: Curves.easeInOut,
                              builder: (_, v, _) => LinearProgressIndicator(
                                value: v,
                                minHeight: 4,
                                backgroundColor: Colors.white.withValues(alpha: 0.08),
                                color: OdinColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      key: const ValueKey('welcome'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                                blurRadius: 40,
                              ),
                            ],
                          ),
                          child: Icon(Icons.check_circle_rounded, size: 44, color: Color(0xFF22C55E)),
                        )
                            .animate()
                            .scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.easeOutBack, duration: 500.ms),
                        const SizedBox(height: 20),
                        const Text(
                          'Bienvenue',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.clubName} · ${widget.roleLabel}',
                          style: TextStyle(color: OdinColors.textMuted, fontSize: 14),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
