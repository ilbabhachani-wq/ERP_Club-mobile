import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/analyste_provider.dart';

/// Fatigue Heatmap — rendu SaaS (KPIs + grille + courbes).
class AnalysteFatigueScreen extends StatefulWidget {
  const AnalysteFatigueScreen({super.key});

  static const accent = Color(0xFFFF7A00);

  @override
  State<AnalysteFatigueScreen> createState() => _AnalysteFatigueScreenState();
}

class _AnalysteFatigueScreenState extends State<AnalysteFatigueScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _teamView = true;
  String? _player;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<AnalysteDataProvider>().api.getFatigue();
      if (!mounted) return;
      final players = data['playerHeatmaps'] as List?;
      final first = players != null && players.isNotEmpty
          ? (players.first as Map)['name']?.toString()
          : null;
      setState(() {
        _data = data;
        _player ??= first;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return OdinBackdrop(
      child: RefreshIndicator(
        color: AnalysteFatigueScreen.accent,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(
              Text('Fatigue Heatmap', style: tt.headlineMedium),
              index: 0,
            ),
            OdinAnimations.fadeUp(
              Text('Charge par intervalles', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
              index: 1,
            ),
            const SizedBox(height: AppSpacing.m),
            if (_loading)
              Shimmer.fromColors(
                baseColor: Colors.white.withValues(alpha: 0.06),
                highlightColor: Colors.white.withValues(alpha: 0.14),
                child: Column(
                  children: List.generate(
                    4,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: SaasCardSkeleton(height: 80),
                    ),
                  ),
                ),
              )
            else if (_error != null)
              GlassCard(
                child: SaasEmptyState(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Fatigue indisponible',
                  subtitle: _error!,
                  actionLabel: 'Réessayer',
                  onAction: _load,
                  compact: true,
                ),
              )
            else
              ..._buildContent(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final data = _data ?? {};
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : <String, dynamic>{};
    final team = (data['teamFatigue'] as List?)
            ?.whereType<Map>()
            .map((e) => _Interval.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <_Interval>[];
    final players = (data['playerHeatmaps'] as List?)
            ?.whereType<Map>()
            .map((e) => _PlayerHeat.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <_PlayerHeat>[];

    final maxFatigue = (summary['maxFatigue'] as num?)?.round() ??
        (team.isEmpty ? 0 : team.map((e) => e.fatigue).reduce((a, b) => a > b ? a : b));
    final collapse = summary['collapseRange']?.toString() ??
        summary['crashInterval']?.toString() ??
        '—';
    final errors = (summary['criticalErrors'] as num?)?.round() ?? 0;
    final delta = (summary['actionsDelta'] as num?)?.round() ?? 0;

    _PlayerHeat? selected;
    for (final p in players) {
      if (p.name == _player) {
        selected = p;
        break;
      }
    }
    selected ??= players.isNotEmpty ? players.first : null;

    return [
      OdinAnimations.fadeUp(
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _Kpi('Fatigue max', '$maxFatigue%', const Color(0xFFEF4444), Icons.local_fire_department),
            _Kpi('Effondrement', collapse, AnalysteFatigueScreen.accent, Icons.trending_down_rounded),
            _Kpi('Erreurs critiques', '$errors', const Color(0xFFA855F7), Icons.warning_amber_rounded),
            _Kpi('Δ Actions 75-90', '$delta', const Color(0xFFF59E0B), Icons.timer_outlined),
          ],
        ),
        index: 2,
      ),
      const SizedBox(height: 14),
      OdinAnimations.fadeUp(
        Row(
          children: [
            _ToggleChip(label: 'Équipe', selected: _teamView, onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _teamView = true);
            }),
            const SizedBox(width: 8),
            _ToggleChip(label: 'Individuel', selected: !_teamView, onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _teamView = false);
            }),
          ],
        ),
        index: 3,
      ),
      const SizedBox(height: 14),
      if (_teamView) ..._teamSection(team) else ..._playerSection(players, selected),
    ];
  }

  List<Widget> _teamSection(List<_Interval> team) {
    return [
      OdinAnimations.fadeUp(const SectionTitle('Heatmap équipe'), index: 4),
      const SizedBox(height: 8),
      OdinAnimations.fadeUp(
        GlassCard(
          raised: true,
          accentColor: AnalysteFatigueScreen.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Par tranche de 15 minutes',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (team.isEmpty)
                const Text('Aucune donnée', style: TextStyle(color: OdinColors.textMuted))
              else
                Row(
                  children: [
                    for (final d in team)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: [
                              Text(
                                d.interval,
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: OdinColors.textMuted),
                              ),
                              const SizedBox(height: 6),
                              _HeatCell(value: d.fatigue),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Faible', style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFFF59E0B), Color(0xFFFF7A00), Color(0xFFEF4444)],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Critique', style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
                ],
              ),
            ],
          ),
        ),
        index: 5,
      ),
      const SizedBox(height: 12),
      OdinAnimations.fadeUp(
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Courbe fatigue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(height: 160, child: _FatigueLineChart(points: team)),
            ],
          ),
        ),
        index: 6,
      ),
      const SizedBox(height: 12),
      OdinAnimations.fadeUp(
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Actions & erreurs', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(height: 160, child: _ActionsBarChart(points: team)),
            ],
          ),
        ),
        index: 7,
      ),
      const SizedBox(height: 12),
      OdinAnimations.fadeUp(
        GlassCard(
          accentColor: AnalysteFatigueScreen.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AnalysteFatigueScreen.accent),
                  SizedBox(width: 6),
                  Text('Analyse IA — Zone d’effondrement', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              const _Insight(
                period: '0-45 min',
                text: 'Performance optimale. Intensité élevée maintenue.',
                color: Color(0xFF22C55E),
              ),
              const _Insight(
                period: '45-65 min',
                text: 'Baisse post mi-temps. Fatigue ~74%. Surveiller.',
                color: Color(0xFFFF7A00),
              ),
              const _Insight(
                period: '65-90 min',
                text: 'Effondrement physique. Actions −34%. Remplacements urgents.',
                color: Color(0xFFEF4444),
              ),
            ],
          ),
        ),
        index: 8,
      ),
    ];
  }

  List<Widget> _playerSection(List<_PlayerHeat> players, _PlayerHeat? selected) {
    return [
      OdinAnimations.fadeUp(const SectionTitle('Joueurs'), index: 4),
      const SizedBox(height: 8),
      OdinAnimations.fadeUp(
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: players.map((p) {
            final on = p.name == (selected?.name ?? _player);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _player = p.name);
              },
              child: AnimatedContainer(
                duration: 180.ms,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: on
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: on
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  p.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: on ? const Color(0xFFC4B5FD) : OdinColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        index: 5,
      ),
      const SizedBox(height: 12),
      if (selected == null)
        const GlassCard(child: Text('Aucun joueur', style: TextStyle(color: OdinColors.textMuted)))
      else
        OdinAnimations.fadeUp(
          GlassCard(
            raised: true,
            accentColor: const Color(0xFF8B5CF6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selected.name} — Fatigue par période',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final d in selected.data)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            children: [
                              Text(d.interval, style: const TextStyle(fontSize: 9, color: OdinColors.textMuted, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              _HeatCell(value: d.fatigue),
                              const SizedBox(height: 4),
                              Text('${d.sprints} sp.', style: const TextStyle(fontSize: 9, color: OdinColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 160,
                  child: _PlayerAreaChart(points: selected.data),
                ),
              ],
            ),
          ),
          index: 6,
        ),
    ];
  }
}

class _Interval {
  const _Interval({
    required this.interval,
    required this.fatigue,
    this.actions = 0,
    this.errors = 0,
  });

  final String interval;
  final int fatigue;
  final int actions;
  final int errors;

  factory _Interval.fromJson(Map<String, dynamic> json) {
    return _Interval(
      interval: json['interval']?.toString() ?? '—',
      fatigue: (json['fatigue'] as num?)?.round() ?? 0,
      actions: (json['actions'] as num?)?.round() ?? 0,
      errors: (json['errors'] as num?)?.round() ?? 0,
    );
  }
}

class _PlayerPoint {
  const _PlayerPoint({required this.interval, required this.fatigue, this.sprints = 0});
  final String interval;
  final int fatigue;
  final int sprints;

  factory _PlayerPoint.fromJson(Map<String, dynamic> json) {
    return _PlayerPoint(
      interval: json['interval']?.toString() ?? '—',
      fatigue: (json['fatigue'] as num?)?.round() ?? 0,
      sprints: (json['sprints'] as num?)?.round() ?? 0,
    );
  }
}

class _PlayerHeat {
  const _PlayerHeat({required this.name, required this.data});
  final String name;
  final List<_PlayerPoint> data;

  factory _PlayerHeat.fromJson(Map<String, dynamic> json) {
    final raw = json['data'] as List?;
    return _PlayerHeat(
      name: json['name']?.toString() ?? 'Joueur',
      data: raw
              ?.whereType<Map>()
              .map((e) => _PlayerPoint.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

Color _fatColor(int v) {
  if (v >= 80) return const Color(0xFFEF4444);
  if (v >= 60) return const Color(0xFFFF7A00);
  if (v >= 40) return const Color(0xFFF59E0B);
  return const Color(0xFF22C55E);
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.color, this.icon);
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 14, color: color),
          ),
          const Spacer(),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: OdinColors.textMuted)),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 180.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)])
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : OdinColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = _fatColor(value);
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text('$value%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: c)),
    ).animate().scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 350.ms, curve: Curves.easeOutBack);
  }
}

class _Insight extends StatelessWidget {
  const _Insight({required this.period, required this.text, required this.color});
  final String period;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(period, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: OdinColors.textMuted, height: 1.35)),
        ],
      ),
    );
  }
}

class _FatigueLineChart extends StatelessWidget {
  const _FatigueLineChart({required this.points});
  final List<_Interval> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 25,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: OdinColors.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Text(points[i].interval, style: const TextStyle(fontSize: 8, color: OdinColors.textMuted));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].fatigue.toDouble()),
            ],
            isCurved: true,
            color: const Color(0xFFEF4444),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, _, _) {
                final c = _fatColor(spot.y.round());
                return FlDotCirclePainter(radius: 4, color: c, strokeWidth: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsBarChart extends StatelessWidget {
  const _ActionsBarChart({required this.points});
  final List<_Interval> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: OdinColors.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Text(points[i].interval, style: const TextStyle(fontSize: 8, color: OdinColors.textMuted));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: points[i].actions.toDouble(), color: const Color(0xFF3B82F6).withValues(alpha: 0.75), width: 7, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                BarChartRodData(toY: points[i].errors.toDouble(), color: const Color(0xFFEF4444).withValues(alpha: 0.9), width: 7, borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlayerAreaChart extends StatelessWidget {
  const _PlayerAreaChart({required this.points});
  final List<_PlayerPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 25,
              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: OdinColors.textMuted)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Text(points[i].interval, style: const TextStyle(fontSize: 8, color: OdinColors.textMuted));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].fatigue.toDouble()),
            ],
            isCurved: true,
            color: const Color(0xFF8B5CF6),
            barWidth: 2.5,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
