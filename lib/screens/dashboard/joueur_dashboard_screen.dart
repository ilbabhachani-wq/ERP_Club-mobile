import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/fifa_card_utils.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

class JoueurDashboardScreen extends StatelessWidget {
  const JoueurDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<JoueurDataProvider>();
    final player = data.myPlayer;

    if (data.loading && player == null) {
      return const Center(child: CircularProgressIndicator(color: OdinColors.accent));
    }
    if (player == null) {
      return const Center(child: Text('Joueur introuvable'));
    }

    final stats = data.playerStats;
    final club = data.orgProfile?.clubName ?? '—';
    final league = data.orgProfile?.league ?? '—';

    return OdinPageScaffold(
      animate: false,
      child: RefreshIndicator(
        color: OdinColors.accent,
        onRefresh: () async {
          final user = context.read<AuthProvider>().user;
          if (user != null) await context.read<JoueurDataProvider>().load(user);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeroSection(player: player, stats: stats, club: club, league: league),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                JoueurKpiCard(
                  icon: Icons.emoji_events_outlined,
                  label: 'Classement poste',
                  value: '#${stats?.positionRanking ?? 0}',
                  subtitle: league,
                  color: OdinColors.warning,
                  index: 0,
                ),
                JoueurKpiCard(
                  icon: Icons.star_outline,
                  label: 'Note Coach',
                  value: stats?.coachRating.toStringAsFixed(1) ?? '—',
                  color: OdinColors.playerCoral,
                  index: 1,
                ),
                JoueurKpiCard(
                  icon: Icons.trending_up,
                  label: 'Valeur marchande',
                  value: stats?.marketValue ?? player.marketValue,
                  subtitle: stats?.marketValueTrend,
                  color: OdinColors.success,
                  index: 2,
                ),
                JoueurKpiCard(
                  icon: Icons.fitness_center,
                  label: 'Charge entraînement',
                  value: '${stats?.trainingLoad ?? 0}%',
                  color: _loadColor(stats?.trainingLoad ?? 0),
                  index: 3,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionTitle('Objectifs Saison'),
            GlassCard(
              child: Column(
                children: [
                  _progressRow('Buts', stats?.seasonGoals ?? 0, 10, OdinColors.playerCoral),
                  const SizedBox(height: 12),
                  _progressRow('Passes D.', stats?.seasonAssists ?? 0, 8, OdinColors.accent),
                  const SizedBox(height: 12),
                  _progressRow('Matchs', stats?.seasonMatches ?? 0, 30, OdinColors.info),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionTitle('Activité Récente'),
            ...data.calendarEvents.take(3).toList().asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OdinAnimations.fadeUp(
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(_iconForType(e.value.eventType), color: OdinColors.accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.value.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(
                                    e.value.location ?? e.value.eventDate,
                                    style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      index: e.key,
                    ),
                  ),
                ),
            if (data.awards.isNotEmpty) ...[
              const SizedBox(height: 12),
              const SectionTitle('Récompenses'),
              SizedBox(
                height: 124,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.awards.take(5).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final a = data.awards[i];
                    final color = _hexColor(a.color);
                    return SizedBox(
                      width: 108,
                      child: GlassCard(
                        accentColor: color,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
                                ),
                                border: Border.all(color: color.withValues(alpha: 0.25)),
                              ),
                              alignment: Alignment.center,
                              child: Text(a.icon, style: const TextStyle(fontSize: 16)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.2),
                            ),
                            if (a.season.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                a.season,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: OdinColors.textMuted),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _hexColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  static Color _loadColor(int load) {
    if (load >= 80) return OdinColors.danger;
    if (load >= 60) return OdinColors.warning;
    return OdinColors.success;
  }

  static IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'MATCH':
        return Icons.sports_soccer;
      case 'MEDICAL':
        return Icons.medical_services_outlined;
      default:
        return Icons.fitness_center;
    }
  }

  static Widget _progressRow(String label, int value, int target, Color color) {
    final pct = (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('$value / $target', style: const TextStyle(color: OdinColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.player,
    required this.stats,
    required this.club,
    required this.league,
  });

  final dynamic player;
  final dynamic stats;
  final String club;
  final String league;

  @override
  Widget build(BuildContext context) {
    final attr = getFifaAttributes(player.radar);

    return OdinAnimations.fadeUp(
      GlassCard(
        raised: true,
        accentColor: OdinColors.accent,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(photoUrl: player.photoUrl, initials: getInitials(player.name)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.1),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _chip('${player.position} · #${player.jerseyNumber ?? '—'}'),
                          _chip(club),
                          _chip(league),
                        ],
                      ),
                      if (stats != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _pill(
                              stats.form >= 80
                                  ? '🔥 Forme excellente'
                                  : stats.form >= 65
                                      ? '📈 Bonne forme'
                                      : '📉 Forme à améliorer',
                              stats.form >= 75 ? OdinColors.accent : OdinColors.warning,
                            ),
                            _pill('${stats.form}% forme', OdinColors.success),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OvrRing(ovr: player.ovr, size: 64, color: OdinColors.accent),
              ],
            ),
            const SizedBox(height: 20),
            SectionTitle('Profil de performance', color: OdinColors.accent),
            Center(
              child: AnimatedRadarDraw(
                values: [
                  attr.pac.toDouble(),
                  attr.sho.toDouble(),
                  attr.pas.toDouble(),
                  attr.dri.toDouble(),
                  attr.def.toDouble(),
                  attr.phy.toDouble(),
                ],
                labels: const ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'],
                color: OdinColors.accent,
                size: 200,
              ),
            ),
          ],
        ),
      ),
      index: 0,
    );
  }

  static Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: OdinColors.panelBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: OdinColors.textSecondary),
      ),
    );
  }

  static Widget _pill(String text, Color color) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
    if (text.contains('excellente')) {
      return pill
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1, end: 1.04, duration: 1200.ms, curve: Curves.easeInOut);
    }
    return pill;
  }
}

class _Avatar extends StatefulWidget {
  const _Avatar({required this.photoUrl, required this.initials});

  final String? photoUrl;
  final String initials;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final showPhoto = widget.photoUrl != null && widget.photoUrl!.isNotEmpty && !_failed;
    return Container(
      width: 72,
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(colors: [OdinColors.accent, OdinColors.accentStrong]),
        border: Border.all(color: OdinColors.panelBorder, width: 2),
      ),
      child: showPhoto
          ? Image.network(
              widget.photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _failed = true);
                });
                return _initialsFallback();
              },
            )
          : _initialsFallback(),
    );
  }

  Widget _initialsFallback() {
    return Center(
      child: Text(
        widget.initials,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}
