import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/animations/odin_animations.dart';
import '../../../core/theme/odin_colors.dart';
import '../../../core/widgets/odin_widgets.dart';
import '../../../models/viiv_metrics.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/viiv_provider.dart';
import 'widgets/viiv_watch_widget.dart';

class ViivSmartwatchScreen extends StatefulWidget {
  const ViivSmartwatchScreen({super.key});

  @override
  State<ViivSmartwatchScreen> createState() => _ViivSmartwatchScreenState();
}

class _ViivSmartwatchScreenState extends State<ViivSmartwatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viiv = context.read<ViivProvider>();
      final joueur = context.read<JoueurDataProvider>();
      if (viiv.metrics == null) viiv.load(joueur);
    });
  }

  Future<void> _sync() async {
    await context.read<ViivProvider>().sync(context.read<JoueurDataProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final viiv = context.watch<ViivProvider>();
    final joueur = context.watch<JoueurDataProvider>();
    final m = viiv.metrics;

    if (viiv.loading && m == null) {
      return const OdinBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF22D3EE), strokeWidth: 2.5),
              SizedBox(height: 14),
              Text('Connexion Viiv GX17…', style: TextStyle(color: OdinColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    if (m == null) {
      return OdinBackdrop(child: Center(child: Text(viiv.error ?? 'Aucune donnée Viiv')));
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: const Color(0xFF22D3EE),
        onRefresh: _sync,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            ViivHeroProfile(
              metrics: m,
              player: joueur.myPlayer,
              syncing: viiv.syncing,
              onSync: _sync,
            ),
            const SizedBox(height: 18),
            const SectionTitle('Scores principaux', color: Color(0xFF22D3EE)),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                OdinAnimations.fadeUp(
                  ViivGlassMetric(
                    label: 'Recovery',
                    value: m.recovery,
                    suffix: '%',
                    progress: m.recovery,
                    color: viivRecoveryColor(m.recovery),
                    delta: '${m.recoveryDelta >= 0 ? '+' : ''}${m.recoveryDelta}%',
                  ),
                  index: 0,
                ),
                OdinAnimations.fadeUp(
                  ViivGlassMetric(label: 'Strain', value: m.strain.toStringAsFixed(1), suffix: '/${m.strainTarget.toStringAsFixed(0)}', color: OdinColors.accent),
                  index: 1,
                ),
                OdinAnimations.fadeUp(
                  ViivGlassMetric(label: 'Énergie Viiv', value: m.viivEnergy, suffix: '%', progress: m.viivEnergy, color: viivEnergyColor(m.viivEnergy)),
                  index: 2,
                ),
                OdinAnimations.fadeUp(
                  ViivGlassMetric(label: 'Readiness', value: m.readiness, color: viivRecoveryColor(m.recovery)),
                  index: 3,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DeviceDetailsCard(m: m),
            const SizedBox(height: 16),
            const SectionTitle('Santé & Sommeil', color: Color(0xFF22D3EE)),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.0,
              children: [
                ViivGlassMetric(label: 'HRV', value: m.hrv, suffix: ' ms', delta: 'Baseline ${m.hrvBaseline}', color: const Color(0xFF34D399)),
                ViivGlassMetric(label: 'FC repos', value: m.restingHr, suffix: ' bpm', color: const Color(0xFFEF4444)),
                ViivGlassMetric(label: 'Sommeil', value: m.sleepHours.toStringAsFixed(1), suffix: 'h', progress: m.sleepPerformance, color: const Color(0xFF818CF8)),
                ViivGlassMetric(label: 'SpO₂', value: m.spo2, suffix: '%', color: const Color(0xFF22D3EE)),
                ViivGlassMetric(label: 'Stress', value: m.stress, suffix: '%', color: OdinColors.warning),
                ViivGlassMetric(label: 'Temp. peau', value: m.skinTemp.toStringAsFixed(1), suffix: '°C', color: OdinColors.playerCoral),
              ],
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stades de sommeil', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _SleepBar('Éveil', m.sleepStages.awake, const Color(0xFF64748B)),
                  _SleepBar('Léger', m.sleepStages.light, const Color(0xFF818CF8)),
                  _SleepBar('Profond', m.sleepStages.sws, const Color(0xFF4F46E5)),
                  _SleepBar('REM', m.sleepStages.rem, const Color(0xFF22D3EE)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Activité & GPS GX17', color: Color(0xFF22D3EE)),
            Row(
              children: [
                Expanded(child: ViivGlassMetric(label: 'Pas', value: _fmt(m.steps), color: OdinColors.success)),
                const SizedBox(width: 10),
                Expanded(child: ViivGlassMetric(label: 'Calories', value: _fmt(m.calories), suffix: ' kcal', color: OdinColors.accent)),
              ],
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed, color: Color(0xFF22D3EE)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.gpsActivity, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('VO₂ max ${m.vo2Max.toStringAsFixed(1)} ml/kg/min', style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Strain · Recovery (7j)', color: Color(0xFF22D3EE)),
            GlassCard(
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.06))),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final i = v.toInt();
                            if (i < 0 || i >= m.weeklyStrain.length) return const SizedBox();
                            return Text(m.weeklyStrain[i].day, style: const TextStyle(fontSize: 10, color: OdinColors.textMuted));
                          },
                        ),
                      ),
                    ),
                    barGroups: m.weeklyStrain.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(toY: e.value.strain, color: OdinColors.accent, width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                          BarChartRodData(toY: e.value.recovery / 6, color: const Color(0xFF34D399), width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('FC horaire', color: Color(0xFF22D3EE)),
            GlassCard(
              child: SizedBox(
                height: 160,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.06))),
                    borderData: FlBorderData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: m.hourlyHr.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.bpm.toDouble())).toList(),
                        isCurved: true,
                        color: const Color(0xFFEF4444),
                        barWidth: 2.5,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: const Color(0xFFEF4444).withValues(alpha: 0.12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Zones FC', color: Color(0xFF22D3EE)),
            ...m.zones.map((z) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _hex(z.color), shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(z.zone, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text('${z.minutes} min', style: const TextStyle(color: OdinColors.textMuted)),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            const SectionTitle('Journal sync GX17', color: Color(0xFF22D3EE)),
            ...m.syncLog.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          e.status == 'ok' ? Icons.check_circle : Icons.warning_amber,
                          color: e.status == 'ok' ? OdinColors.success : OdinColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(e.type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                        Text(e.time, style: const TextStyle(color: OdinColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF22D3EE)),
                      const SizedBox(width: 8),
                      Text('AI Coach Viiv · ${m.aiConfidence}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(m.aiInsight, style: const TextStyle(color: OdinColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 12),
                  ...m.aiRecommendations.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $r', style: const TextStyle(fontSize: 13, color: OdinColors.textMuted)),
                      )),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 12),
            _FitBadge(fit: m.fitToPlay, risk: m.injuryRisk),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  static Color _hex(String h) {
    final hex = h.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class _DeviceDetailsCard extends StatelessWidget {
  const _DeviceDetailsCard({required this.m});
  final ViivMetrics m;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF22D3EE)),
              SizedBox(width: 8),
              Text('Appareil', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          _row('Modèle', m.deviceModel),
          _row('ID Appareil', m.deviceId, mono: true),
          _row('Firmware', m.firmware),
          _row('Dernière sync', '${m.lastSync} · ${m.lastSyncAt}'),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 100, child: Text(k, style: const TextStyle(color: OdinColors.textMuted, fontSize: 12))),
            Expanded(
              child: Text(
                v,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, fontFamily: mono ? 'monospace' : null),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
}

class _SleepBar extends StatelessWidget {
  const _SleepBar(this.label, this.hours, this.color);
  final String label;
  final double hours;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${hours.toStringAsFixed(1)}h', style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (hours / 8).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FitBadge extends StatelessWidget {
  const _FitBadge({required this.fit, required this.risk});
  final bool fit;
  final String risk;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Icon(fit ? Icons.check_circle : Icons.pause_circle, color: fit ? OdinColors.success : OdinColors.warning, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fit ? 'Fit to Play ✓' : 'Repos recommandé', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('Risque blessure: $risk', style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
