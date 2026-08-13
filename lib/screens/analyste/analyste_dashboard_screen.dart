import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/club_logo.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/analyste_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/avatar_provider.dart';
import '../../services/imgbb_service.dart';

/// Hub Analyste → page profil pro (identité + stats + accès rapide).
class AnalysteDashboardScreen extends StatelessWidget {
  const AnalysteDashboardScreen({super.key});

  static const _brand = OdinColors.accent; // #FF7A00 — palette web
  static const _shortcuts = [
    _Shortcut('Live', 'Temps réel', Icons.sensors, '/analyste/live', Color(0xFFEF4444)),
    _Shortcut('PPI', 'Score IA', Icons.star_rounded, '/analyste/ppi', Color(0xFFF59E0B)),
    _Shortcut('Viiv', 'Smartwatch', Icons.watch_rounded, '/analyste/viiv', Color(0xFF22D3EE)),
    _Shortcut('Predict', 'ML match', Icons.psychology, '/analyste/prediction', OdinColors.accent),
    _Shortcut('Chimie', 'Relations', Icons.hub_outlined, '/analyste/chemistry', Color(0xFF22C55E)),
    _Shortcut('Modules', 'Tous les outils', Icons.apps_rounded, '/analyste/modules', OdinColors.playerCoral),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<AnalysteDataProvider>();
    final avatar = context.watch<AvatarProvider>();
    final user = auth.user;
    final dash = data.dashboard;

    if (data.loading && dash == null) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    final displayName = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!
        : (dash?.info.name ?? user?.email.split('@').first ?? 'Analyste');
    final email = user?.email ?? '';
    final club = user?.organization?.clubName ?? dash?.info.club ?? 'Club';
    final logoUrl = user?.organization?.logoUrl;
    final season = dash?.info.season ?? '2025-26';
    final league = user?.organization?.league ?? 'Ligue 1';
    final country = user?.organization?.country ?? '';
    final stats = dash?.liveStats ?? const [];
    final patterns = dash?.patterns ?? const [];
    final initials = _initials(displayName);

    return OdinBackdrop(
      child: RefreshIndicator(
        color: _brand,
        backgroundColor: OdinColors.panelSolid,
        onRefresh: () => data.refreshDashboard(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
          children: [
            // ── Hero profil ───────────────────────────────────────────────
            OdinAnimations.scaleIn(
              _ProfileHero(
                initials: initials,
                displayName: displayName,
                email: email,
                club: club,
                logoUrl: logoUrl,
                season: season,
                league: league,
                avatarUrl: avatar.avatarUrl,
                uploading: avatar.uploading,
                onAvatarTap: () => _pickAvatar(context),
              ),
            ),

            const SizedBox(height: 16),

            // ── Stats saison ──────────────────────────────────────────────
            OdinAnimations.fadeUp(
              const _SectionLabel('Indicateurs live'),
              index: 1,
            ),
            const SizedBox(height: 10),
            if (stats.isNotEmpty)
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stats.length.clamp(0, 6),
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final s = stats[i];
                    return OdinAnimations.fadeUp(
                      _StatChip(
                        label: s.label,
                        value: s.value,
                        color: _hex(s.color),
                        icon: _statIcon(s.label),
                      ),
                      index: i + 2,
                    );
                  },
                ),
              )
            else
              OdinAnimations.fadeUp(
                Row(
                  children: [
                    Expanded(child: _StatChip(label: 'Modules', value: '10', color: _brand, icon: Icons.apps_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatChip(label: 'Rôle', value: 'IA', color: const Color(0xFF22D3EE), icon: Icons.psychology_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatChip(label: 'Saison', value: season.split('-').last, color: const Color(0xFF22C55E), icon: Icons.calendar_today_rounded)),
                  ],
                ),
                index: 2,
              ),

            const SizedBox(height: 20),

            // ── Infos profil ──────────────────────────────────────────────
            OdinAnimations.fadeUp(const _SectionLabel('Profil professionnel'), index: 4),
            const SizedBox(height: 10),
            OdinAnimations.fadeUp(
              _InfoCard(
                rows: [
                  _InfoRowData(Icons.badge_outlined, 'Rôle', 'Analyste Performance'),
                  _InfoRowData(Icons.email_outlined, 'Email', email.isEmpty ? '—' : email),
                  _InfoRowData(Icons.sports_soccer_outlined, 'Club', club),
                  if (league.isNotEmpty) _InfoRowData(Icons.emoji_events_outlined, 'Compétition', league),
                  if (country.isNotEmpty) _InfoRowData(Icons.public_outlined, 'Pays', country),
                  _InfoRowData(Icons.calendar_month_outlined, 'Saison', season),
                  _InfoRowData(Icons.verified_outlined, 'Statut', 'Actif · SaaS Pro'),
                ],
              ),
              index: 5,
            ),

            const SizedBox(height: 20),

            // ── Accès rapide ──────────────────────────────────────────────
            OdinAnimations.fadeUp(const _SectionLabel('Accès rapide'), index: 6),
            const SizedBox(height: 10),
            OdinAnimations.fadeUp(
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _shortcuts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 132,
                ),
                itemBuilder: (_, i) {
                  final s = _shortcuts[i];
                  return SaasModuleCard(
                    title: s.label,
                    subtitle: s.subtitle,
                    icon: s.icon,
                    color: s.color,
                    height: 132,
                    onTap: () => context.go(s.path),
                  )
                      .animate()
                      .fadeIn(delay: (60 * i).ms, duration: 380.ms, curve: Curves.easeOutCubic)
                      .slideY(begin: 0.12, end: 0, delay: (60 * i).ms, duration: 420.ms, curve: Curves.easeOutCubic);
                },
              ),
              index: 7,
            ),

            // ── Activité / patterns ───────────────────────────────────────
            if (patterns.isNotEmpty) ...[
              const SizedBox(height: 20),
              OdinAnimations.fadeUp(
                Row(
                  children: [
                    const Expanded(child: _SectionLabel('Activité récente')),
                    GestureDetector(
                      onTap: () => context.go('/analyste/patterns'),
                      child: const Text(
                        'Tout voir',
                        style: TextStyle(color: _brand, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                index: 8,
              ),
              const SizedBox(height: 10),
              ...List.generate(patterns.take(3).length, (i) {
                final p = patterns[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OdinAnimations.fadeUp(
                    _ActivityTile(
                      title: p.title,
                      confidence: p.confidence.round(),
                      severity: p.severity,
                    ),
                    index: i + 9,
                  ),
                );
              }),
            ],

            const SizedBox(height: 16),
            OdinAnimations.fadeUp(
              GlassCard(
                onTap: () => auth.logout(),
                accentColor: OdinColors.danger,
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: OdinColors.danger),
                    SizedBox(width: 12),
                    Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.w800)),
                    Spacer(),
                    Icon(Icons.chevron_right_rounded, color: OdinColors.textMuted, size: 18),
                  ],
                ),
              ),
              index: 12,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    HapticFeedback.selectionClick();
    final avatar = context.read<AvatarProvider>();
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: OdinColors.panelSolid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Photo de profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
               Text(
                'Upload via ImgBB',
                style: TextStyle(fontSize: 12, color: OdinColors.textMuted),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: OdinColors.accent),
                title: const Text('Galerie', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: OdinColors.accent),
                title: const Text('Caméra', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              if (avatar.avatarUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: OdinColors.danger),
                  title: const Text('Supprimer la photo', style: TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () async {
                    await avatar.clear();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    try {
      await avatar.pickAndUpload(source: source);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo mise à jour ✓'), backgroundColor: Color(0xFF22C55E)),
        );
      }
    } on ImgbbException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: OdinColors.danger),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: OdinColors.danger),
        );
      }
    }
  }
}

// ─── Widgets ────────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.initials,
    required this.displayName,
    required this.email,
    required this.club,
    this.logoUrl,
    required this.season,
    required this.league,
    this.avatarUrl,
    this.uploading = false,
    this.onAvatarTap,
  });

  final String initials;
  final String displayName;
  final String email;
  final String club;
  final String? logoUrl;
  final String season;
  final String league;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: OdinColors.accent.withValues(alpha: 0.28)),
        gradient: LinearGradient(
          begin: Alignment(-0.8, -1),
          end: Alignment(1, 1.2),
          colors: [
            Color(0x38FF7A00),
            Color(0xF20B0B14),
            Color(0x18C0392B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: OdinColors.accent.withValues(alpha: 0.16),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: -2,
            child: Opacity(
              opacity: 0.16,
              child: ClubLogo(
                clubName: club,
                logoUrl: logoUrl,
                size: 108,
                radius: 20,
                padding: 8,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          OdinColors.accent.withValues(alpha: 0.4),
                          OdinColors.accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1.08, 1.08),
                        duration: 2400.ms,
                        curve: Curves.easeInOut,
                      ),
                  Hero(
                    tag: 'analyste-avatar',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onAvatarTap,
                        customBorder: const CircleBorder(),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: avatarUrl == null
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFFF9A3D), Color(0xFFE66000)],
                                      )
                                    : null,
                                image: avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(avatarUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: OdinColors.accent.withValues(alpha: 0.45),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: avatarUrl == null
                                  ? Text(
                                      initials,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    )
                                  : null,
                            ),
                            if (uploading)
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.45),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  ),
                                ),
                              ),
                            if (!uploading)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: OdinColors.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: OdinColors.canvas, width: 2),
                                  ),
                                  child: Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack,
                        duration: 600.ms,
                      ),
                  Positioned(
                    left: 0,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: OdinColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: OdinColors.canvas, width: 2.5),
                      ),
                      child: Icon(Icons.check_rounded, size: 12, color: Colors.white),
                    ),
                  )
                      .animate(delay: 400.ms)
                      .fadeIn()
                      .scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.easeOutBack),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Touchez pour changer la photo',
                style: TextStyle(fontSize: 11, color: OdinColors.textMuted.withValues(alpha: 0.9)),
              ).animate(delay: 350.ms).fadeIn(),
              const SizedBox(height: 8),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              )
                  .animate(delay: 120.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: OdinColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: OdinColors.accent.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: OdinColors.accent),
                    SizedBox(width: 6),
                    Text(
                      'ANALYSTE PERFORMANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: OdinColors.accent,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn()
                  .slideY(begin: 0.3, end: 0),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(color: OdinColors.textMuted, fontSize: 12),
                ).animate(delay: 260.ms).fadeIn(),
              ],
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MetaPill(
                    text: club,
                    leading: ClubLogo(
                      clubName: club,
                      logoUrl: logoUrl,
                      size: 22,
                      radius: 6,
                      padding: 2,
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _MetaPill(
                    icon: Icons.calendar_today_outlined,
                    text: season,
                  ),
                ],
              ).animate(delay: 320.ms).fadeIn().slideY(begin: 0.2, end: 0),
              if (league.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  league,
                  style: TextStyle(
                    color: OdinColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate(delay: 380.ms).fadeIn(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    this.icon,
    this.leading,
    required this.text,
  });

  final IconData? icon;
  final Widget? leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) leading! else if (icon != null) Icon(icon, size: 12, color: OdinColors.textMuted),
          if (leading != null || icon != null) const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: OdinColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: OdinColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = icon ?? _statIcon(label);
    return Container(
      width: 132,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(resolvedIcon, size: 12, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 0.5,
                    color: OdinColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

IconData _statIcon(String label) {
  final k = label.toLowerCase();
  if (k.contains('possession')) return Icons.pie_chart_rounded;
  if (k.contains('xg') || k.contains('but')) return Icons.sports_soccer_rounded;
  if (k.contains('risque') || k.contains('risk')) return Icons.warning_amber_rounded;
  if (k.contains('joueur') || k.contains('dispos')) return Icons.groups_rounded;
  if (k.contains('module')) return Icons.apps_rounded;
  if (k.contains('rôle') || k.contains('role') || k.contains('ia')) return Icons.psychology_rounded;
  if (k.contains('saison')) return Icons.calendar_today_rounded;
  if (k.contains('fatigue')) return Icons.local_fire_department_rounded;
  if (k.contains('ppi')) return Icons.star_rounded;
  return Icons.insights_rounded;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xD90F1D3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _InfoRow(data: rows[i]),
            if (i < rows.length - 1)
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.05), indent: 52, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.data});
  final _InfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: OdinColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, size: 16, color: OdinColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(data.label, style: TextStyle(color: OdinColors.textMuted, fontSize: 12)),
          ),
          Flexible(
            child: Text(
              data.value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.confidence,
    required this.severity,
  });

  final String title;
  final int confidence;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final dot = severity == 'injury'
        ? OdinColors.danger
        : severity == 'tactical'
            ? OdinColors.info
            : OdinColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: OdinColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OdinColors.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Text(
            '$confidence%',
            style: const TextStyle(fontWeight: FontWeight.w900, color: OdinColors.accent, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut(this.label, this.subtitle, this.icon, this.path, this.color);
  final String label;
  final String subtitle;
  final IconData icon;
  final String path;
  final Color color;
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'A';
  if (parts.length == 1) {
    final s = parts.first;
    return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
  }
  return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
}

Color _hex(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF8B5CF6);
}
