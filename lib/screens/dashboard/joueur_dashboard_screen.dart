import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/fifa_player_card.dart';
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
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.awards.take(5).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final a = data.awards[i];
                    return GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(a.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 4),
                          Text(a.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
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
    const cardWidth = 210.0;

    return OdinAnimations.fadeUp(
      GlassCard(
        padding: EdgeInsets.zero,
        raised: true,
        accentColor: OdinColors.playerCoral,
        clipContent: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    OdinColors.playerCoral.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
              child: FifaCardShowcase(
                height: cardWidth * 1.5 + 36,
                child: Hero(
                  tag: kFifaCardHeroTag,
                  child: Material(
                    color: Colors.transparent,
                    child: FifaPlayerCard(
                      width: cardWidth,
                      name: player.name,
                      position: player.position,
                      ovr: player.ovr,
                      age: player.age,
                      radar: player.radar,
                      number: player.jerseyNumber != null ? '${player.jerseyNumber}' : '—',
                      nationality: player.nationality ?? '',
                      flag: nationalityFlag(player.nationality),
                      club: club,
                      photoUrl: player.photoUrl,
                      badge: stats != null && stats.form >= 75 ? '🔥 FORME' : null,
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0.82, 0.82),
                          end: const Offset(1, 1),
                          duration: 700.ms,
                          curve: Curves.easeOutBack,
                        )
                        .rotate(begin: -0.04, end: 0, duration: 700.ms, curve: Curves.easeOutCubic)
                        .then()
                        .shimmer(duration: 900.ms, color: Colors.white24),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                children: [
                  if (stats != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(
                            stats.form >= 80
                                ? '🔥 Forme excellente'
                                : stats.form >= 65
                                    ? '📈 Bonne forme'
                                    : '📉 Forme à améliorer',
                            stats.form >= 75 ? OdinColors.playerCoral : OdinColors.warning,
                          ),
                          _pill('${stats.form}% forme', OdinColors.success),
                        ],
                      ),
                    ),
                  Text(
                    'SAISON ${DateTime.now().year - 1}-${DateTime.now().year.toString().substring(2)} · ${player.position}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: OdinColors.playerCoral,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    player.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${nationalityFlag(player.nationality)} ${player.nationality ?? ''} · $club',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                  ),
                  Text(
                    league,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: OdinColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      index: 0,
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
    if (text.contains('excellente') || text.contains('FORME')) {
      return pill
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1, end: 1.04, duration: 1200.ms, curve: Curves.easeInOut);
    }
    return pill;
  }
}
