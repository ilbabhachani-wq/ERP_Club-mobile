import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

class JoueurPerformancesScreen extends StatelessWidget {
  const JoueurPerformancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<JoueurDataProvider>();
    final player = data.myPlayer;
    final stats = data.playerStats;

    if (data.loading && player == null) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }
    if (player == null) {
      return const Center(child: Text('Chargement...'));
    }

    final radar = player.radar;
    final radarValues = [
      radar.speed.toDouble(),
      radar.passing.toDouble(),
      radar.shooting.toDouble(),
      radar.physical.toDouble(),
      radar.vision.toDouble(),
      radar.defending.toDouble(),
    ];

    final kpi = [
      (Icons.speed, 'Vitesse', '${stats?.vitesse ?? radar.speed}', OdinColors.info),
      (Icons.sports_soccer, 'Technique', '${stats?.technique ?? 0}', OdinColors.playerCoral),
      (Icons.fitness_center, 'Physique', '${stats?.physique ?? radar.physical}', OdinColors.warning),
      (Icons.psychology, 'Mental', '${stats?.mental ?? 0}', OdinColors.success),
    ];

    return OdinBackdrop(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: OdinColors.canvas.withValues(alpha: 0.92),
            expandedHeight: 72,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 14),
              title: Text(
                'Performances',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(child: const SectionTitle('Vue d\'ensemble')),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = kpi[i];
                  return AnimationConfiguration.staggeredGrid(
                    position: i,
                    columnCount: 2,
                    duration: const Duration(milliseconds: 480),
                    child: SlideAnimation(
                      verticalOffset: 36,
                      child: FadeInAnimation(
                        child: JoueurKpiCard(
                          icon: item.$1,
                          label: item.$2,
                          value: item.$3,
                          color: item.$4,
                          index: i,
                        ),
                      ),
                    ),
                  );
                },
                childCount: kpi.length,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Radar vs Équipe'),
                  GlassCard(
                    child: SizedBox(
                      height: 260,
                      child: Center(
                        child: AnimatedRadarDraw(
                          values: radarValues,
                          labels: const ['VIT', 'PAS', 'TIR', 'PHY', 'DRI', 'DEF'],
                          size: 240,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle('Notes Match — 10 derniers'),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final m = data.matchStats.take(10).toList()[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OdinAnimations.fadeUp(
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _ratingColor(m.rating).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                m.rating.toStringAsFixed(1),
                                style: TextStyle(fontWeight: FontWeight.w900, color: _ratingColor(m.rating)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('vs ${m.opponent}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(
                                    '${m.result} · ${m.goals}G ${m.assists}P · ${m.minutes}\'',
                                    style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      index: i,
                    ),
                  );
                },
                childCount: data.matchStats.take(10).length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _ratingColor(double rating) {
    if (rating >= 8) return OdinColors.success;
    if (rating >= 6.5) return OdinColors.accent;
    return OdinColors.danger;
  }
}
