import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
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
    final data = context.watch<JoueurDataProvider>();
    final matches = data.matchStats;

    if (data.loading && matches.isEmpty) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    if (matches.isEmpty) {
      return OdinBackdrop(
        child: Center(
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics_outlined, size: 40, color: OdinColors.textMuted.withValues(alpha: 0.7)),
                const SizedBox(height: 12),
                const Text('Aucune analyse disponible', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'Les stats match apparaîtront ici',
                  style: TextStyle(color: OdinColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final idx = _selected.clamp(0, matches.length - 1);
    final m = matches[idx];
    final half1Sprints = (m.sprints * 0.45).round();
    final half2Sprints = m.sprints - half1Sprints;
    final half1Dist = double.parse((m.distance * 0.48).toStringAsFixed(1));
    final half2Dist = double.parse((m.distance * 0.52).toStringAsFixed(1));

    return OdinBackdrop(
      child: RefreshIndicator(
        color: OdinColors.playerCoral,
        backgroundColor: OdinColors.panelSolid,
        onRefresh: () => data.refreshPlayerStats(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            OdinAnimations.fadeUp(
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/performances');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  const Expanded(
                    child: Text(
                      'Analyse Match',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                    ),
                  ),
                ],
              ),
              index: 0,
            ),
            const SizedBox(height: 4),
            OdinAnimations.fadeUp(
              const Text(
                'KPIs physiques · mi-temps · heatmap',
                style: TextStyle(color: OdinColors.textMuted, fontSize: 13),
              ),
              index: 1,
            ),
            const SizedBox(height: 14),
            OdinAnimations.fadeUp(
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: matches.take(8).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final match = matches[i];
                    final selected = i == idx;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: selected
                              ? const LinearGradient(colors: [OdinColors.playerCoral, OdinColors.accent])
                              : null,
                          color: selected ? null : Colors.white.withValues(alpha: 0.05),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : OdinColors.panelBorder,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: OdinColors.playerCoral.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'vs ${match.opponent.split(' ').last} · ${_shortDate(match.matchDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : OdinColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              index: 2,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(m.id.isEmpty ? '${m.opponent}-$idx' : m.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OdinAnimations.fadeUp(
                      GlassCard(
                        raised: true,
                        accentColor: OdinColors.playerCoral,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'vs ${m.opponent}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _longDate(m.matchDate),
                                    style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  m.result,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: OdinColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('Note ', style: TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                                    Text(
                                      m.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: _ratingColor(m.rating),
                                      ),
                                    ),
                                    const Text('/10', style: TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      index: 0,
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.45,
                      children: [
                        _MetricTile(
                          label: 'Distance',
                          value: m.distance.toStringAsFixed(1),
                          unit: ' km',
                          color: OdinColors.accent,
                          index: 0,
                        ),
                        _MetricTile(
                          label: 'Sprints',
                          value: '${m.sprints}',
                          unit: '',
                          color: OdinColors.info,
                          index: 1,
                        ),
                        _MetricTile(
                          label: 'Précision passes',
                          value: m.passAccuracy.toStringAsFixed(0),
                          unit: '%',
                          color: OdinColors.success,
                          index: 2,
                        ),
                        _MetricTile(
                          label: 'Vitesse max',
                          value: m.topSpeed.toStringAsFixed(1),
                          unit: ' km/h',
                          color: OdinColors.warning,
                          index: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.95,
                      children: [
                        _SmallStat(label: 'Buts', value: '${m.goals}', color: OdinColors.success, index: 0),
                        _SmallStat(label: 'Assists', value: '${m.assists}', color: OdinColors.info, index: 1),
                        _SmallStat(label: 'Clés', value: '${m.keyPasses}', color: OdinColors.warning, index: 2),
                        _SmallStat(label: 'Min', value: '${m.minutes}', color: const Color(0xFF8B5CF6), index: 3),
                      ],
                    ),
                    const SizedBox(height: 18),
                    OdinAnimations.fadeUp(const SectionTitle('Heatmap'), index: 4),
                    OdinAnimations.fadeUp(
                      GlassCard(
                        raised: true,
                        child: Column(
                          children: [
                            AspectRatio(
                              aspectRatio: 1.45,
                              child: CustomPaint(
                                painter: _MatchHeatmapPainter(
                                  seed: m.sprints + m.goals * 7 + idx * 3,
                                  biasRight: m.goals + m.assists > 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Zones d\'activité — vs ${m.opponent}',
                              style: const TextStyle(color: OdinColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      index: 5,
                    ),
                    const SizedBox(height: 18),
                    OdinAnimations.fadeUp(const SectionTitle('Sprints & distance par mi-temps'), index: 6),
                    OdinAnimations.fadeUp(
                      GlassCard(
                        child: SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              maxY: [
                                    half1Sprints.toDouble(),
                                    half2Sprints.toDouble(),
                                    half1Dist * 4,
                                    half2Dist * 4,
                                  ].reduce((a, b) => a > b ? a : b) *
                                  1.25,
                              barGroups: [
                                BarChartGroupData(
                                  x: 0,
                                  barsSpace: 6,
                                  barRods: [
                                    BarChartRodData(
                                      toY: half1Sprints.toDouble(),
                                      width: 18,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                      color: OdinColors.accent,
                                    ),
                                    BarChartRodData(
                                      toY: half1Dist * 4,
                                      width: 18,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                      color: OdinColors.info,
                                    ),
                                  ],
                                ),
                                BarChartGroupData(
                                  x: 1,
                                  barsSpace: 6,
                                  barRods: [
                                    BarChartRodData(
                                      toY: half2Sprints.toDouble(),
                                      width: 18,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                      color: OdinColors.accent,
                                    ),
                                    BarChartRodData(
                                      toY: half2Dist * 4,
                                      width: 18,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                      color: OdinColors.info,
                                    ),
                                  ],
                                ),
                              ],
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (v, _) => Text(
                                      v.toInt().toString(),
                                      style: const TextStyle(color: OdinColors.textMuted, fontSize: 10),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final label = v.toInt() == 0 ? '1ère MT' : '2ème MT';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          label,
                                          style: const TextStyle(color: OdinColors.textMuted, fontSize: 11),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      index: 7,
                    ),
                    const SizedBox(height: 10),
                    OdinAnimations.fadeUp(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Legend(color: OdinColors.accent, label: 'Sprints'),
                          const SizedBox(width: 16),
                          _Legend(color: OdinColors.info, label: 'Distance (×4)'),
                        ],
                      ),
                      index: 8,
                    ),
                    const SizedBox(height: 10),
                    OdinAnimations.fadeUp(
                      GlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '1ère MT · $half1Sprints sprints · $half1Dist km',
                                style: const TextStyle(fontSize: 11, color: OdinColors.textSecondary),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '2ème MT · $half2Sprints sprints · $half2Dist km',
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 11, color: OdinColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      index: 9,
                    ),
                    if (data.squadPlayers.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      OdinAnimations.fadeUp(const SectionTitle('Effectif'), index: 10),
                      OdinAnimations.fadeUp(
                        GlassCard(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in data.squadPlayers.take(8))
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: OdinColors.panelBorder),
                                  ),
                                  child: Text(
                                    p.name.split(' ').last,
                                    style: const TextStyle(fontSize: 12, color: OdinColors.textMuted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        index: 11,
                      ),
                    ],
                    const SizedBox(height: 14),
                    OdinAnimations.fadeUp(
                      GlassCard(
                        onTap: () => context.go('/profil'),
                        child: const Row(
                          children: [
                            Text(
                              'Voir ma fiche complète',
                              style: TextStyle(fontWeight: FontWeight.w700, color: OdinColors.accent),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_rounded, color: OdinColors.accent, size: 18),
                          ],
                        ),
                      ),
                      index: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.index,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return OdinAnimations.fadeUp(
      GlassCard(
        accentColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(color: OdinColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) {
                final isInt = unit.isEmpty || unit == '%';
                final shown = isInt && !value.contains('.')
                    ? v.round().toString()
                    : v.toStringAsFixed(value.contains('.') ? 1 : 0);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      shown,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 2),
                      child: Text(unit, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12)),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      index: index,
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.label,
    required this.value,
    required this.color,
    required this.index,
  });

  final String label;
  final String value;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return OdinAnimations.fadeUp(
      GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: OdinColors.textMuted)),
          ],
        ),
      ),
      index: index + 4,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: OdinColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _MatchHeatmapPainter extends CustomPainter {
  _MatchHeatmapPainter({required this.seed, this.biasRight = true});

  final int seed;
  final bool biasRight;

  @override
  void paint(Canvas canvas, Size size) {
    final pitch = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      pitch,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E38), Color(0xFF124028)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final lines = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(pitch.deflate(6), lines);
    canvas.drawLine(Offset(size.width / 2, 6), Offset(size.width / 2, size.height - 6), lines);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 26, lines);
    canvas.drawRect(Rect.fromLTWH(6, size.height * 0.28, size.width * 0.16, size.height * 0.44), lines);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.84 - 6, size.height * 0.28, size.width * 0.16, size.height * 0.44),
      lines,
    );

    final baseX = biasRight ? 0.58 : 0.42;
    final spots = <Offset>[
      Offset(size.width * (baseX + (seed % 5) * 0.02), size.height * 0.36),
      Offset(size.width * (baseX + 0.1), size.height * 0.48),
      Offset(size.width * (baseX - 0.08), size.height * 0.55),
      Offset(size.width * (baseX + 0.14), size.height * 0.64),
      Offset(size.width * (baseX), size.height * 0.72),
      Offset(size.width * 0.5, size.height * 0.5),
    ];

    for (var i = 0; i < spots.length; i++) {
      final o = spots[i];
      final r = 28.0 + (i % 3) * 8;
      canvas.drawCircle(
        o,
        r,
        Paint()
          ..color = OdinColors.playerCoral.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
      canvas.drawCircle(
        o,
        r * 0.45,
        Paint()..color = OdinColors.accent.withValues(alpha: 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MatchHeatmapPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.biasRight != biasRight;
}

Color _ratingColor(double rating) {
  if (rating >= 8) return OdinColors.success;
  if (rating >= 7) return OdinColors.warning;
  return OdinColors.danger;
}

String _shortDate(String raw) {
  if (raw.isEmpty) return '—';
  try {
    final d = DateTime.parse(raw);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  } catch (_) {
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }
}

String _longDate(String raw) {
  if (raw.isEmpty) return '—';
  try {
    final d = DateTime.parse(raw);
    const months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  } catch (_) {
    return raw;
  }
}
