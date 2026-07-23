import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

class JoueurTrainingScreen extends StatelessWidget {
  const JoueurTrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<JoueurDataProvider>();
    final stats = data.playerStats;
    final load = stats?.trainingLoad ?? 0;
    final fatigue = stats?.fatiguePredicted ?? 0;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Centre d\'Entraînement'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.check_circle_outline, label: 'Présence', value: '4/5', color: OdinColors.success), index: 0),
              OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.fitness_center, label: 'Charge', value: '$load%', color: _loadColor(load)), index: 1),
              OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.battery_3_bar, label: 'Fatigue', value: '$fatigue%', color: OdinColors.warning), index: 2),
              OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.trending_up, label: 'Intensité', value: 'Moyenne', color: OdinColors.accent), index: 3),
            ],
          ),
          const SizedBox(height: 20),
          const SectionTitle('Joueurs en forme'),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.squadPlayers.take(6).length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = data.squadPlayers[i];
                return GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OvrRing(ovr: p.ovr, size: 48, color: OdinColors.playerCoral),
                      const SizedBox(height: 4),
                      Text(p.name.split(' ').last, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('Évolution charge'),
          GlassCard(
            child: SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.08))),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 55), const FlSpot(1, 62), const FlSpot(2, 58), const FlSpot(3, 70), const FlSpot(4, 65), FlSpot(5, load.toDouble()),
                      ],
                      isCurved: true,
                      color: OdinColors.accent,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: OdinColors.accent.withValues(alpha: 0.12)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _loadColor(int load) {
    if (load >= 80) return OdinColors.danger;
    if (load >= 60) return OdinColors.warning;
    return OdinColors.success;
  }
}
