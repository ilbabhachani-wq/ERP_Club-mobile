import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/avatar_change_sheet.dart';
import '../../core/widgets/club_logo.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../core/utils/scout_player_photos.dart';
import '../../models/scout_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/scout_provider.dart';

class ScoutDashboardScreen extends StatelessWidget {
  const ScoutDashboardScreen({super.key});

  static const _shortcuts = [
    _Shortcut('Carte', 'Exploration', Icons.public, '/scout/map', Color(0xFF22D3EE)),
    _Shortcut('Recherche', 'Filtres IA', Icons.search_rounded, '/scout/search', Color(0xFF3B82F6)),
    _Shortcut('Prospects', 'Annuaire', Icons.groups_rounded, '/scout/prospects', Color(0xFF22C55E)),
    _Shortcut('Watchlist', 'Priorités', Icons.bookmark_rounded, '/scout/watchlist', Color(0xFFF59E0B)),
    _Shortcut('Missions', 'Terrain', Icons.flag_rounded, '/scout/missions', Color(0xFFEF4444)),
    _Shortcut('Rapport', 'Évaluation', Icons.assignment_rounded, '/scout/report', OdinColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<ScoutDataProvider>();
    final avatar = context.watch<AvatarProvider>();
    final dash = data.dashboard;
    final profile = data.profile;

    if (data.loading && dash == null) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    final name = profile?.fullName.trim().isNotEmpty == true
        ? profile!.fullName
        : (auth.user?.fullName ?? auth.user?.email.split('@').first ?? 'Scout');
    final club = auth.user?.organization?.clubName ?? dash?.clubName ?? 'Club';
    final logoUrl = auth.user?.organization?.logoUrl;
    final season = dash?.season ?? '2025-26';
    final kpis = dash?.kpis ?? const ScoutDashboardKpis();

    // Sync backend avatar → local cache once available
    final remoteAvatar = profile?.avatarUrl.trim() ?? '';
    if (remoteAvatar.isNotEmpty && avatar.avatarUrl != remoteAvatar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AvatarProvider>().syncFromRemote(remoteAvatar);
      });
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: () => data.refreshDashboard(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.scaleIn(
              _HeroCard(
                name: name,
                club: club,
                logoUrl: logoUrl,
                season: season,
                email: auth.user?.email ?? '',
                avatarUrl: avatar.avatarUrl ?? (remoteAvatar.isEmpty ? null : remoteAvatar),
                uploading: avatar.uploading,
                onAvatarTap: () => showAvatarChangeSheet(
                  context,
                  onUploaded: (url) async {
                    try {
                      await context.read<ScoutDataProvider>().updateProfile({'avatarUrl': url});
                    } catch (_) {}
                  },
                  onCleared: () async {
                    try {
                      await context.read<ScoutDataProvider>().updateProfile({'avatarUrl': ''});
                    } catch (_) {}
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Indicateurs'), index: 1),
            const SizedBox(height: 10),
            SizedBox(
              height: 108,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ScoutKpiCard(
                    label: 'Prospects',
                    value: '${kpis.totalProspects}',
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Watchlist',
                    value: '${kpis.watchlistCount}',
                    icon: Icons.bookmark_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Rapports',
                    value: '${kpis.reportsCount}',
                    icon: Icons.assignment_rounded,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Validés',
                    value: '${kpis.validatedCount}',
                    icon: Icons.verified_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Pot. moyen',
                    value: kpis.avgPotential.toStringAsFixed(0),
                    icon: Icons.trending_up_rounded,
                    color: const Color(0xFFA855F7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Accès rapide'), index: 2),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _shortcuts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 96,
              ),
              itemBuilder: (_, i) {
                final s = _shortcuts[i];
                return OdinAnimations.fadeUp(
                  _QuickTile(
                    label: s.label,
                    subtitle: s.subtitle,
                    icon: s.icon,
                    color: s.color,
                    onTap: () => context.go(s.route),
                  ),
                  index: i + 3,
                );
              },
            ),
            const SizedBox(height: 20),
            OdinAnimations.fadeUp(
              ScoutSectionLabel(
                'Recommandations IA',
                trailing: TextButton(
                  onPressed: () => context.go('/scout/ai'),
                  child: const Text('Voir tout', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              index: 9,
            ),
            const SizedBox(height: 8),
            if ((dash?.aiRecs ?? []).isEmpty)
              SaasEmptyState(
                title: 'Aucune recommandation',
                subtitle: 'Les suggestions IA apparaîtront ici',
                icon: Icons.auto_awesome,
                compact: true,
                onAction: () => data.refreshDashboard(),
              )
            else
              ...List.generate((dash!.aiRecs.length).clamp(0, 4), (i) {
                final r = dash.aiRecs[i];
                final photo = resolveScoutPhotoUrl(
                  r.name,
                  direct: r.photoUrl,
                  catalog: [
                    ...data.prospects.map((p) => (name: p.name, photoUrl: p.photoUrl)),
                    ...data.watchlist.map((p) => (name: p.name, photoUrl: p.photoUrl)),
                  ],
                );
                return OdinAnimations.fadeUp(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (r.id.isNotEmpty) context.go('/scout/prospect/${r.id}');
                      },
                      child: Row(
                        children: [
                          ScoutPlayerAvatar(name: r.name, photoUrl: photo, flag: r.flag, size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  '${r.pos} · ${r.age} ans · ${r.club}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                ),
                                if (r.reasons.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    r.reasons.first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppColors.accent.withValues(alpha: 0.9), fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${r.score}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  index: 10 + i,
                );
              }),
            const SizedBox(height: 12),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Missions à venir'), index: 14),
            const SizedBox(height: 8),
            if ((dash?.upcomingMissions ?? []).isEmpty)
              GlassCard(
                child: Text(
                  'Aucune mission planifiée',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
              )
            else
              ...List.generate((dash!.upcomingMissions.length).clamp(0, 3), (i) {
                final m = dash.upcomingMissions[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    onTap: () => context.go('/scout/missions'),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.flag_rounded, color: AppColors.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(
                                '${m.date}${m.time != null ? ' · ${m.time}' : ''}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 12),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Pipeline workflow'), index: 18),
            const SizedBox(height: 8),
            GlassCard(
              onTap: () => context.go('/scout/workflow'),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kScoutWorkflowCols.map((col) {
                  final count = dash?.workflowCounts[col.id] ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: col.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: col.color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${col.label} · $count',
                      style: TextStyle(color: col.color, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.name,
    required this.club,
    required this.season,
    required this.email,
    this.logoUrl,
    this.avatarUrl,
    this.uploading = false,
    this.onAvatarTap,
  });

  final String name;
  final String club;
  final String? logoUrl;
  final String season;
  final String email;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onAvatarTap;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(0, 2)).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.28),
            const Color(0xFF16162A),
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        boxShadow: AppShadows.soft(AppColors.accent),
      ),
      child: Stack(
        children: [
          // Logo équipe en fond (comme rôle analyste)
          Positioned(
            right: -4,
            top: -2,
            bottom: -2,
            child: Opacity(
              opacity: 0.18,
              child: ClubLogo(
                clubName: club,
                logoUrl: logoUrl,
                size: 92,
                radius: 18,
                padding: 6,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Row(
            children: [
              // Avatar scout (personne) — tap pour ImgBB
              GestureDetector(
                onTap: uploading ? null : onAvatarTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
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
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: avatarUrl == null
                          ? Text(
                              _initials,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            )
                          : null,
                    ),
                    if (uploading)
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0B0B14), width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$club · Saison $season',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.card,
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut(this.label, this.subtitle, this.icon, this.route, this.color);
  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}
