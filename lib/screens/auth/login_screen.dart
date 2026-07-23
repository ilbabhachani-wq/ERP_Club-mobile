import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_logo.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

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

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bientôt disponible')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggingIn = context.select<AuthProvider, bool>((a) => a.loggingIn);

    return Scaffold(
      backgroundColor: OdinColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ParallaxOrbs(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flip3DReveal(
                        child: Hero(
                          tag: kOdinLogoHeroTag,
                          child: Material(
                            color: Colors.transparent,
                            child: const OdinLogo(width: 220, animated: false),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Connectez-vous à votre espace joueur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: OdinColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          fontSize: 13,
                        ),
                      )
                          .animate(delay: 120.ms)
                          .fadeIn(duration: 420.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 28),
                      ShakeWidget(
                        key: _shakeKey,
                        child: AuthGlassCard(
                          child: Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Connexion',
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                                )
                                    .animate(delay: 220.ms)
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
                                    .animate(delay: 300.ms)
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
                                    .animate(delay: 360.ms)
                                    .fadeIn()
                                    .slideY(begin: 0.2, end: 0),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(
                                        color: OdinColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                MorphLoadingButton(
                                  loading: loggingIn,
                                  label: 'Se connecter',
                                  onPressed: loggingIn ? null : _submit,
                                )
                                    .animate(delay: 440.ms)
                                    .fadeIn()
                                    .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
                              ],
                            ),
                          ),
                        ),
                      )
                          .animate(delay: 200.ms)
                          .custom(
                            duration: 550.ms,
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) => Opacity(
                              opacity: value,
                              child: Perspective3D(
                                rotateX: (1 - value) * -0.32,
                                depth: 0.0018,
                                alignment: Alignment.topCenter,
                                child: child,
                              ),
                            ),
                          ),
                      const SizedBox(height: 28),
                      Text(
                        'ODIN ERP · v1.0.0',
                        style: TextStyle(
                          fontSize: 11,
                          color: OdinColors.textMuted.withValues(alpha: 0.5),
                          letterSpacing: 0.4,
                        ),
                      ).animate(delay: 600.ms).fadeIn(duration: 500.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
