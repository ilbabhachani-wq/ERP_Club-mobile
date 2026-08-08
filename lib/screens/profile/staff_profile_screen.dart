import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/avatar_change_sheet.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';
import '../../providers/avatar_provider.dart';

/// Écran "Mon profil" générique pour le staff club (Préparateur, Responsable…).
/// Accessible depuis le bouton Réglages (haut droit) de chaque espace.
class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({
    super.key,
    required this.roleLabel,
    this.accentColor = OdinColors.accent,
  });

  final String roleLabel;
  final Color accentColor;

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final _currentPwd = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirmPwd = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _saving = false;

  @override
  void dispose() {
    _currentPwd.dispose();
    _newPwd.dispose();
    _confirmPwd.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final current = _currentPwd.text.trim();
    final next = _newPwd.text.trim();
    final confirm = _confirmPwd.text.trim();

    if (current.isEmpty || next.isEmpty) {
      _snack('Renseignez votre mot de passe actuel et le nouveau.', error: true);
      return;
    }
    if (next.length < 8) {
      _snack('Le nouveau mot de passe doit contenir au moins 8 caractères.', error: true);
      return;
    }
    if (next != confirm) {
      _snack('La confirmation ne correspond pas au nouveau mot de passe.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().changePassword(current, next);
      if (!mounted) return;
      _currentPwd.clear();
      _newPwd.clear();
      _confirmPwd.clear();
      _snack('Mot de passe mis à jour ✓');
    } catch (e) {
      _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? OdinColors.danger : const Color(0xFF22C55E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final avatar = context.watch<AvatarProvider>();
    final user = auth.user;
    final name = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim()
        : (user?.email.split('@').first ?? 'Utilisateur');
    final club = user?.organization?.clubName ?? '—';
    final accent = widget.accentColor;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          OdinAnimations.fadeUp(
            const Text(
              'Mon profil',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            index: 0,
          ),
          const SizedBox(height: 4),
          OdinAnimations.fadeUp(
            Text(widget.roleLabel, style: TextStyle(color: OdinColors.textMuted)),
            index: 1,
          ),
          const SizedBox(height: 20),
          OdinAnimations.scaleIn(
            GlassCard(
              raised: true,
              accentColor: accent,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: avatar.uploading ? null : () => showAvatarChangeSheet(context),
                    child: Stack(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: avatar.avatarUrl == null
                                ? LinearGradient(
                                    colors: [
                                      accent.withValues(alpha: 0.35),
                                      accent.withValues(alpha: 0.1),
                                    ],
                                  )
                                : null,
                            image: avatar.avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(avatar.avatarUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            border: Border.all(color: accent.withValues(alpha: 0.4), width: 2),
                          ),
                          child: avatar.uploading
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : (avatar.avatarUrl == null
                                  ? Center(
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                                      ),
                                    )
                                  : null),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                              border: Border.all(color: OdinColors.canvas, width: 2),
                            ),
                            child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(fontSize: 12, color: OdinColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.roleLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          OdinAnimations.fadeUp(const SectionTitle('Informations'), index: 2),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Column(
                children: [
                  _infoRow('Nom complet', name),
                  _infoRow('Email', user?.email ?? '—'),
                  _infoRow('Rôle', widget.roleLabel),
                  _infoRow('Club', club),
                ],
              ),
            ),
            index: 3,
          ),
          const SizedBox(height: 20),
          OdinAnimations.fadeUp(const SectionTitle('Sécurité — Changer le mot de passe'), index: 4),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Column(
                children: [
                  TextField(
                    controller: _currentPwd,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPwd,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPwd,
                    obscureText: _obscureNew,
                    decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe'),
                  ),
                  const SizedBox(height: 16),
                  OdinPrimaryButton(
                    label: 'Mettre à jour',
                    loading: _saving,
                    onPressed: _changePassword,
                  ),
                ],
              ),
            ),
            index: 5,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: OdinColors.textMuted)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
