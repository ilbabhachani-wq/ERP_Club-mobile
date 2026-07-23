import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

class JoueurAnalysisScreen extends StatefulWidget {
  const JoueurAnalysisScreen({super.key});

  @override
  State<JoueurAnalysisScreen> createState() => _JoueurAnalysisScreenState();
}

class _JoueurAnalysisScreenState extends State<JoueurAnalysisScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final matches = context.watch<JoueurDataProvider>().matchStats;
    if (matches.isEmpty) {
      return OdinBackdrop(child: const Center(child: Text('Aucune analyse disponible')));
    }
    final m = matches[_selected.clamp(0, matches.length - 1)];

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Analyse Match'),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: matches.length,
              itemBuilder: (_, i) {
                final match = matches[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('vs ${match.opponent}', style: const TextStyle(fontSize: 11)),
                    selected: _selected == i,
                    onSelected: (_) => setState(() => _selected = i),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            raised: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('vs ${m.opponent}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text('${m.result} · ${m.matchDate}', style: const TextStyle(color: OdinColors.textMuted)),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.directions_run, label: 'Distance', value: '${m.distance.toStringAsFixed(1)} km', color: OdinColors.info), index: 0),
                    OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.flash_on, label: 'Sprints', value: '${m.sprints}', color: OdinColors.warning), index: 1),
                    OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.swap_horiz, label: 'Précision passes', value: '${m.passAccuracy.toStringAsFixed(0)}%', color: OdinColors.success), index: 2),
                    OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.speed, label: 'Vitesse max', value: '${m.topSpeed.toStringAsFixed(1)} km/h', color: OdinColors.playerCoral), index: 3),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Heatmap'),
          GlassCard(
            child: AspectRatio(
              aspectRatio: 1.4,
              child: CustomPaint(
                painter: _HeatmapPainter(),
                child: const Center(child: Text('Zones d\'activité', style: TextStyle(color: OdinColors.textMuted))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pitch = Paint()..color = const Color(0xFF1a4d2e);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      pitch,
    );
    final heat = Paint()..color = OdinColors.playerCoral.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.4), 40, heat);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.55), 30, heat);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.65), 25, heat);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
