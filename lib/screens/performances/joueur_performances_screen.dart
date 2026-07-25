import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../models/player_models.dart';
import '../../providers/app_providers.dart';

class JoueurPerformancesScreen extends StatefulWidget {
  const JoueurPerformancesScreen({super.key});

  @override
  State<JoueurPerformancesScreen> createState() => _JoueurPerformancesScreenState();
}

class _JoueurPerformancesScreenState extends State<JoueurPerformancesScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['Vue', 'Tendances', 'Profil', 'Analyse'];
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<JoueurDataProvider>();
    final player = data.myPlayer;
    final stats = data.playerStats;

    if (data.loading && player == null) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }
    if (player == null) {
      return const OdinBackdrop(child: Center(child: Text('Chargement...')));
    }

    return OdinBackdrop(
      child: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: OdinColors.canvas.withValues(alpha: 0.94),
            expandedHeight: 118,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 52),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performances',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.4),
                  ),
                  Text(
                    '${player.name} · OVR ${player.ovr}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: OdinColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: _PillTabs(controller: _tab, labels: _tabs),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          color: OdinColors.playerCoral,
          backgroundColor: OdinColors.panelSolid,
          onRefresh: () => data.refreshPlayerStats(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_tab.index),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                children: [
                  switch (_tab.index) {
                    0 => _VueTab(data: data, player: player, stats: stats),
                    1 => _TendancesTab(data: data, stats: stats),
                    2 => _ProfilTab(data: data, player: player),
                    _ => _AnalyseTab(data: data),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTabs extends StatelessWidget {
  const _PillTabs({required this.controller, required this.labels});

  final TabController controller;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OdinColors.panelBorder),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: const LinearGradient(
            colors: [OdinColors.playerCoral, OdinColors.accent],
          ),
          boxShadow: [
            BoxShadow(
              color: OdinColors.playerCoral.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: OdinColors.textMuted,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: labels.map((l) => Tab(text: l, height: 34)).toList(),
      ),
    );
  }
}

// ─── Vue ─────────────────────────────────────────────────────────────────────

class _VueTab extends StatelessWidget {
  const _VueTab({required this.data, required this.player, required this.stats});

  final JoueurDataProvider data;
  final BackendPlayer player;
  final PlayerStatsPayload? stats;

  @override
  Widget build(BuildContext context) {
    final kpi = [
      (Icons.bolt_rounded, 'Vitesse', stats?.vitesse ?? player.radar.speed, OdinColors.playerCoral),
      (Icons.psychology_rounded, 'Technique', stats?.technique ?? 0, OdinColors.info),
      (Icons.fitness_center_rounded, 'Physique', stats?.physique ?? player.radar.physical, OdinColors.success),
      (Icons.favorite_rounded, 'Mental', stats?.mental ?? 0, OdinColors.warning),
    ];
    final last = data.matchStats.isNotEmpty ? data.matchStats.first : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OdinAnimations.fadeUp(
          Text(
            'Vue d\'ensemble',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          index: 0,
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpi.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (_, i) {
            final item = kpi[i];
            return JoueurKpiCard(
              icon: item.$1,
              label: item.$2,
              value: '${item.$3}',
              color: item.$4,
              index: i,
            );
          },
        ),
        if (last != null) ...[
          const SizedBox(height: 20),
          OdinAnimations.fadeUp(const SectionTitle('Dernier match'), index: 4),
          OdinAnimations.fadeUp(
            GlassCard(
              raised: true,
              accentColor: OdinColors.playerCoral,
              onTap: () => context.go('/analyse'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'vs ${last.opponent}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${last.result} · ${_fmtDate(last.matchDate)}',
                              style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      _RatingBadge(rating: last.rating),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Buts',
                          value: '${last.goals}',
                          color: OdinColors.success,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Assists',
                          value: '${last.assists}',
                          color: OdinColors.info,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Passes clés',
                          value: '${last.keyPasses}',
                          color: OdinColors.warning,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Min',
                          value: "${last.minutes}'",
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.play_circle_fill_rounded, color: OdinColors.playerCoral, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Ouvrir l\'analyse match',
                        style: TextStyle(
                          color: OdinColors.playerCoral,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: OdinColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
            index: 5,
          ),
        ],
        const SizedBox(height: 20),
        OdinAnimations.fadeUp(const SectionTitle('Heatmap saison'), index: 6),
        OdinAnimations.fadeUp(
          GlassCard(
            child: AspectRatio(
              aspectRatio: 1.55,
              child: CustomPaint(
                painter: _SeasonHeatmapPainter(seed: player.ovr + player.radar.speed),
              ),
            ),
          ),
          index: 7,
        ),
        const SizedBox(height: 8),
        OdinAnimations.fadeUp(
          const Center(
            child: Text(
              'Zones d\'activité — saison en cours',
              style: TextStyle(color: OdinColors.textMuted, fontSize: 11),
            ),
          ),
          index: 8,
        ),
      ],
    );
  }
}

// ─── Tendances ───────────────────────────────────────────────────────────────

class _TendancesTab extends StatelessWidget {
  const _TendancesTab({required this.data, required this.stats});

  final JoueurDataProvider data;
  final PlayerStatsPayload? stats;

  @override
  Widget build(BuildContext context) {
    final evolution = stats?.performanceEvolution ?? const <PerfEvolutionPoint>[];
    final fallbackEvo = evolution.isNotEmpty
        ? evolution
        : data.matchStats.take(6).toList().reversed.map((m) {
            final label = m.opponent.split(' ').last;
            return PerfEvolutionPoint(month: label, score: (m.rating * 10).clamp(60, 99));
          }).toList();

    final ratings = data.matchStats.take(6).toList().reversed.toList();
    final totalGoals = data.matchStats.fold<int>(0, (s, m) => s + m.goals);
    final totalAssists = data.matchStats.fold<int>(0, (s, m) => s + m.assists);
    final totalKeys = data.matchStats.fold<int>(0, (s, m) => s + m.keyPasses);
    final pie = (stats?.goalContribution.isNotEmpty ?? false)
        ? stats!.goalContribution
        : [
            GoalContributionSlice(name: 'Buts', value: (totalGoals > 0 ? totalGoals : 1).toDouble(), colorHex: '#FF6B57'),
            GoalContributionSlice(name: 'Assists', value: (totalAssists > 0 ? totalAssists : 1).toDouble(), colorHex: '#3B82F6'),
            GoalContributionSlice(name: 'Passes clés', value: (totalKeys > 0 ? totalKeys : 1).toDouble(), colorHex: '#22C55E'),
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OdinAnimations.fadeUp(const SectionTitle('Évolution de performance'), index: 0),
        OdinAnimations.fadeUp(
          GlassCard(
            raised: true,
            child: SizedBox(
              height: 220,
              child: fallbackEvo.isEmpty
                  ? const Center(child: Text('Données en cours…', style: TextStyle(color: OdinColors.textMuted)))
                  : LineChart(
                      LineChartData(
                        minY: 55,
                        maxY: 100,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: Colors.white.withValues(alpha: 0.06),
                            strokeWidth: 1,
                          ),
                        ),
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
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                if (i < 0 || i >= fallbackEvo.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    fallbackEvo[i].month,
                                    style: const TextStyle(color: OdinColors.textMuted, fontSize: 9),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (_) => OdinColors.panelSolid,
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < fallbackEvo.length; i++)
                                FlSpot(i.toDouble(), fallbackEvo[i].score),
                            ],
                            isCurved: true,
                            color: OdinColors.playerCoral,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (a, b, c, d) => FlDotCirclePainter(
                                radius: 4,
                                color: OdinColors.playerCoral,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  OdinColors.playerCoral.withValues(alpha: 0.28),
                                  OdinColors.playerCoral.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          index: 1,
        ),
        const SizedBox(height: 18),
        OdinAnimations.fadeUp(const SectionTitle('Notes match'), index: 2),
        OdinAnimations.fadeUp(
          GlassCard(
            child: SizedBox(
              height: 180,
              child: ratings.isEmpty
                  ? const Center(child: Text('Aucun match', style: TextStyle(color: OdinColors.textMuted)))
                  : BarChart(
                      BarChartData(
                        maxY: 10,
                        minY: 5,
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
                              reservedSize: 22,
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
                                final i = v.toInt();
                                if (i < 0 || i >= ratings.length) return const SizedBox.shrink();
                                final label = ratings[i].opponent.split(' ').last;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    label.length > 6 ? label.substring(0, 6) : label,
                                    style: const TextStyle(color: OdinColors.textMuted, fontSize: 9),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < ratings.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: ratings[i].rating.clamp(5, 10),
                                  width: 14,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      OdinColors.playerCoral.withValues(alpha: 0.55),
                                      OdinColors.playerCoral,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ),
          index: 3,
        ),
        const SizedBox(height: 18),
        OdinAnimations.fadeUp(const SectionTitle('Contribution offensive'), index: 4),
        OdinAnimations.fadeUp(
          GlassCard(
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 42,
                      sections: [
                        for (final s in pie)
                          PieChartSectionData(
                            value: s.value <= 0 ? 0.1 : s.value,
                            color: _parseHex(s.colorHex),
                            radius: 52,
                            title: s.value.toInt().toString(),
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final s in pie)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _parseHex(s.colorHex),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.name,
                            style: const TextStyle(color: OdinColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          index: 5,
        ),
      ],
    );
  }
}

// ─── Profil ──────────────────────────────────────────────────────────────────

class _ProfilTab extends StatelessWidget {
  const _ProfilTab({required this.data, required this.player});

  final JoueurDataProvider data;
  final BackendPlayer player;

  int _avgAttr(String attr) {
    final squad = data.squadPlayers;
    if (squad.isEmpty) return (player.ovr * 0.95).round();
    final vals = squad.map((p) {
      return switch (attr) {
        'speed' => p.radar.speed,
        'passing' => p.radar.passing,
        'shooting' => p.radar.shooting,
        'physical' => p.radar.physical,
        'vision' => p.radar.vision,
        _ => p.radar.defending,
      };
    }).toList();
    return (vals.reduce((a, b) => a + b) / vals.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final r = player.radar;
    final radarValues = [
      r.speed.toDouble(),
      r.passing.toDouble(),
      r.shooting.toDouble(),
      r.physical.toDouble(),
      r.vision.toDouble(),
      r.defending.toDouble(),
    ];
    final attrs = [
      ('Speed', r.speed, _avgAttr('speed')),
      ('Passing', r.passing, _avgAttr('passing')),
      ('Shooting', r.shooting, _avgAttr('shooting')),
      ('Physical', r.physical, _avgAttr('physical')),
      ('Vision', r.vision, _avgAttr('vision')),
    ];
    final top = data.squadPlayers.fold<BackendPlayer?>(
      null,
      (best, p) => (best == null || p.ovr > best.ovr) ? p : best,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OdinAnimations.fadeUp(const SectionTitle('Radar FIFA'), index: 0),
        OdinAnimations.fadeUp(
          GlassCard(
            raised: true,
            child: SizedBox(
              height: 260,
              child: Center(
                child: AnimatedRadarDraw(
                  values: radarValues,
                  labels: const ['VIT', 'PAS', 'TIR', 'PHY', 'VIS', 'DEF'],
                  size: 240,
                ),
              ),
            ),
          ),
          index: 1,
        ),
        const SizedBox(height: 18),
        OdinAnimations.fadeUp(const SectionTitle('Moi vs moyenne équipe'), index: 2),
        OdinAnimations.fadeUp(
          GlassCard(
            child: SizedBox(
              height: 210,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  barGroups: [
                    for (var i = 0; i < attrs.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: attrs[i].$2.toDouble(),
                            width: 10,
                            color: OdinColors.playerCoral,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: attrs[i].$3.toDouble(),
                            width: 10,
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
                          final i = v.toInt();
                          if (i < 0 || i >= attrs.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              attrs[i].$1.substring(0, 3).toUpperCase(),
                              style: const TextStyle(color: OdinColors.textMuted, fontSize: 9),
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
          index: 3,
        ),
        const SizedBox(height: 10),
        OdinAnimations.fadeUp(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: OdinColors.playerCoral, label: 'Moi'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.white.withValues(alpha: 0.22), label: 'Équipe'),
            ],
          ),
          index: 4,
        ),
        if (top != null && top.id != player.id) ...[
          const SizedBox(height: 18),
          OdinAnimations.fadeUp(
            SectionTitle('Moi vs ${top.name.split(' ').last} (top OVR)'),
            index: 5,
          ),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Column(
                children: [
                  _CompareRow(label: 'OVR', me: player.ovr, other: top.ovr),
                  _CompareRow(label: 'Speed', me: player.radar.speed, other: top.radar.speed),
                  _CompareRow(label: 'Passing', me: player.radar.passing, other: top.radar.passing),
                  _CompareRow(label: 'Shooting', me: player.radar.shooting, other: top.radar.shooting),
                  _CompareRow(label: 'Physical', me: player.radar.physical, other: top.radar.physical),
                  _CompareRow(label: 'Vision', me: player.radar.vision, other: top.radar.vision),
                ],
              ),
            ),
            index: 6,
          ),
        ],
      ],
    );
  }
}

// ─── Analyse ─────────────────────────────────────────────────────────────────

class _AnalyseTab extends StatelessWidget {
  const _AnalyseTab({required this.data});

  final JoueurDataProvider data;

  @override
  Widget build(BuildContext context) {
    final matches = data.matchStats.take(10).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OdinAnimations.fadeUp(
          GlassCard(
            raised: true,
            accentColor: OdinColors.accent,
            onTap: () => context.go('/analyse'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        OdinColors.accent.withValues(alpha: 0.3),
                        OdinColors.playerCoral.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: OdinColors.accent),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analyse Match Pro', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      SizedBox(height: 2),
                      Text(
                        'Heatmap · mi-temps · KPIs physiques',
                        style: TextStyle(color: OdinColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: OdinColors.textMuted),
              ],
            ),
          ),
          index: 0,
        ),
        const SizedBox(height: 18),
        OdinAnimations.fadeUp(const SectionTitle('10 derniers matchs'), index: 1),
        if (matches.isEmpty)
          const GlassCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucun match enregistré', style: TextStyle(color: OdinColors.textMuted)),
              ),
            ),
          )
        else
          ...List.generate(matches.length, (i) {
            final m = matches[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OdinAnimations.fadeUp(
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () => context.go('/analyse'),
                  child: Row(
                    children: [
                      _RatingBadge(rating: m.rating, compact: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('vs ${m.opponent}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              '${m.result} · ${m.goals}G ${m.assists}A · ${m.keyPasses} clés · ${m.minutes}\'',
                              style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: OdinColors.textMuted),
                    ],
                  ),
                ),
                index: i + 2,
              ),
            );
          }),
      ],
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: OdinColors.textMuted)),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, this.compact = false});

  final double rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = _ratingColor(rating);
    final size = compact ? 44.0 : 56.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        rating.toStringAsFixed(1),
        style: TextStyle(fontWeight: FontWeight.w900, color: c, fontSize: compact ? 14 : 18),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: OdinColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.label, required this.me, required this.other});

  final String label;
  final int me;
  final int other;

  @override
  Widget build(BuildContext context) {
    final max = (me > other ? me : other).clamp(1, 100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: OdinColors.textMuted))),
              Text('$me', style: const TextStyle(fontWeight: FontWeight.w800, color: OdinColors.playerCoral)),
              const Text('  /  ', style: TextStyle(color: OdinColors.textMuted)),
              Text('$other', style: const TextStyle(fontWeight: FontWeight.w700, color: OdinColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 6, color: Colors.white.withValues(alpha: 0.08)),
                FractionallySizedBox(
                  widthFactor: other / max,
                  child: Container(height: 6, color: Colors.white.withValues(alpha: 0.2)),
                ),
                FractionallySizedBox(
                  widthFactor: me / max,
                  child: Container(height: 6, color: OdinColors.playerCoral),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeasonHeatmapPainter extends CustomPainter {
  _SeasonHeatmapPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final pitch = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(14),
    );
    canvas.drawRRect(pitch, Paint()..color = const Color(0xFF164A2E));
    final lines = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(pitch.deflate(6), lines);
    canvas.drawLine(Offset(size.width / 2, 6), Offset(size.width / 2, size.height - 6), lines);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 28, lines);

    final rnd = seed;
    final spots = [
      Offset(size.width * (0.55 + (rnd % 7) / 100), size.height * 0.38),
      Offset(size.width * 0.68, size.height * 0.48),
      Offset(size.width * 0.42, size.height * 0.58),
      Offset(size.width * 0.72, size.height * 0.62),
      Offset(size.width * 0.58, size.height * 0.72),
    ];
    for (final o in spots) {
      canvas.drawCircle(
        o,
        36,
        Paint()
          ..color = OdinColors.playerCoral.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
      canvas.drawCircle(o, 14, Paint()..color = OdinColors.accent.withValues(alpha: 0.45));
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonHeatmapPainter oldDelegate) => oldDelegate.seed != seed;
}

Color _ratingColor(double rating) {
  if (rating >= 8) return OdinColors.success;
  if (rating >= 6.5) return OdinColors.accent;
  return OdinColors.danger;
}

Color _parseHex(String hex) {
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFFFF6B57);
}

String _fmtDate(String raw) {
  if (raw.isEmpty) return '—';
  try {
    final d = DateTime.parse(raw);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return raw;
  }
}
