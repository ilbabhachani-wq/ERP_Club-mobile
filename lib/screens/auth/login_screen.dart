import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_logo.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

const _featureTags = ['IA', 'Analyse', 'Performance', 'Recrutement'];

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
      await context.read<JoueurDataProvider>().load(auth.user!);
      if (mounted) context.go('/');
    } else {
      _shakeKey.currentState?.shake();
      if (auth.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggingIn = context.select<AuthProvider, bool>((a) => a.loggingIn);

    return Scaffold(
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: LoginTiltWrapper(
                        enabled: _booted,
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
                            const Text(
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
                            const Text(
                              'Espace Joueur • SaaS Pro',
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
                                    color: Colors.white.withValues(alpha: 0.04),
                                  ),
                                  child: Text(
                                    e.value,
                                    style: const TextStyle(
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
                                      const Text(
                                        'Connexion',
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                                      )
                                          .animate(delay: 320.ms)
                                          .fadeIn()
                                          .slideX(begin: -0.08, end: 0),
                                      const SizedBox(height: 6),
                                      const Text(
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
                                        loading: loggingIn,
                                        label: 'Se connecter',
                                        onPressed: loggingIn ? null : _submit,
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
              color: const Color(0xFF0D0D18),
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
        ],
      ),
    );
  }
}
