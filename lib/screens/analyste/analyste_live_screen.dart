import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/club_logo.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../models/analyste_models.dart';
import '../../providers/analyste_provider.dart';

/// Live Match — aligné sur `AnalysteLiveMatchPage.tsx` (web).
class AnalysteLiveScreen extends StatefulWidget {
  const AnalysteLiveScreen({super.key});

  @override
  State<AnalysteLiveScreen> createState() => _AnalysteLiveScreenState();
}

class _AnalysteLiveScreenState extends State<AnalysteLiveScreen> {
  bool _live = false;
  bool _busyTick = false;
  int _currentMinute = 0;
  int _homeScore = 0;
  int _awayScore = 0;
  List<AnalysteMinutePoint> _minuteData = const [
    AnalysteMinutePoint(minute: 0, possession: 50, fatigue: 8, winProb: 45, xg: 0.0),
  ];
  List<AnalysteLivePlayer> _players = const [];
  List<AnalysteMatchEvent> _events = const [];
  Timer? _timer;

  String? _homeTeam;
  String? _awayTeam;
  List<String> _teams = List.of(kSelectableClubs);
  bool _teamsBootstrapped = false;
  bool _kickoffReady = false;
  String _feedSource = '';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTeamCatalog();
      await _resetToKickoff();
    });
  }

  Future<void> _loadTeamCatalog() async {
    try {
      final provider = context.read<AnalysteDataProvider>();
      final apiTeams = await provider.api.getPredictionTeams();
      final mlClubs = await provider.api.getMlClubs();
      if (!mounted) return;
      final merged = <String>{
        ...kSelectableClubs,
        ...apiTeams.where((t) => t.trim().isNotEmpty),
        ...mlClubs.where((t) => t.trim().isNotEmpty),
      }.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() => _teams = merged);
    } catch (_) {
      // keep curated list
    }
  }

  Future<void> _resetToKickoff({String? home, String? away}) async {
    _timer?.cancel();
    final h = home ?? _homeTeam ?? context.read<AnalysteDataProvider>().liveMatch?.homeTeam ?? 'Real Madrid';
    final a = away ?? _awayTeam ?? context.read<AnalysteDataProvider>().liveMatch?.awayTeam ?? 'Ajax';
    setState(() {
      _live = false;
      _busyTick = false;
      _homeTeam = h;
      _awayTeam = a;
      _currentMinute = 0;
      _homeScore = 0;
      _awayScore = 0;
      _minuteData = const [
        AnalysteMinutePoint(minute: 0, possession: 50, fatigue: 8, winProb: 45, xg: 0.0),
      ];
      _kickoffReady = false;
    });
    await context.read<AnalysteDataProvider>().refreshLive(home: h, away: a, minute: 0);
    if (!mounted) return;
    final match = context.read<AnalysteDataProvider>().liveMatch;
    if (match == null) return;
    setState(() {
      _homeTeam = match.homeTeam;
      _awayTeam = match.awayTeam;
      _currentMinute = 0;
      _homeScore = match.homeScore;
      _awayScore = match.awayScore;
      _feedSource = match.source;
      _minuteData = match.minuteData.isNotEmpty
          ? List.of(match.minuteData)
          : const [AnalysteMinutePoint(minute: 0, possession: 50, fatigue: 8, winProb: 45, xg: 0.0)];
      _players = List.of(match.players);
      _events = List.of(match.events);
      _kickoffReady = true;
      _teamsBootstrapped = true;
      _ensureTeamInList(_homeTeam);
      _ensureTeamInList(_awayTeam);
    });
  }

  void _ensureTeamInList(String? name) {
    if (name == null || name.trim().isEmpty) return;
    if (_teams.any((t) => t.toLowerCase() == name.toLowerCase())) return;
    _teams = [..._teams, name]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<void> _pickTeam({required bool home}) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: OdinColors.panelSolid,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => _TeamPickerSheet(
        title: home ? 'Équipe domicile' : 'Équipe extérieur',
        teams: _teams,
        selected: home ? (_homeTeam ?? '') : (_awayTeam ?? ''),
        excluded: home ? _awayTeam : _homeTeam,
      ),
    );
    if (selected == null || !mounted) return;
    HapticFeedback.selectionClick();
    final h = home ? selected : (_homeTeam ?? 'Real Madrid');
    final a = home ? (_awayTeam ?? 'Ajax') : selected;
    await _resetToKickoff(home: h, away: a);
  }

  Future<void> _swapTeams() async {
    HapticFeedback.lightImpact();
    final h = _awayTeam;
    final a = _homeTeam;
    if (h == null || a == null) return;
    await _resetToKickoff(home: h, away: a);
  }

  Future<void> _toggleLive() async {
    if (_live) {
      _timer?.cancel();
      setState(() => _live = false);
      return;
    }
    if (!_kickoffReady) {
      await _resetToKickoff();
    }
    setState(() => _live = true);
    _timer = Timer.periodic(const Duration(milliseconds: 700), (_) => _advanceMinute());
  }

  Future<void> _advanceMinute() async {
    if (!_live || _busyTick || !mounted) return;
    if (_currentMinute >= 90) {
      _timer?.cancel();
      setState(() {
        _live = false;
        _currentMinute = 90;
      });
      return;
    }
    _busyTick = true;
    final next = _currentMinute + 1;
    final h = _homeTeam;
    final a = _awayTeam;
    try {
      final match = await context.read<AnalysteDataProvider>().api.getLiveMatch(
            home: h,
            away: a,
            minute: next,
          );
      if (!mounted) return;
      await context.read<AnalysteDataProvider>().applyLiveMatch(match);
      setState(() {
        _currentMinute = next;
        _homeScore = match.homeScore;
        _awayScore = match.awayScore;
        _feedSource = match.source;
        _players = List.of(match.players);
        _events = List.of(match.events);
        _minuteData = match.minuteData.isNotEmpty
            ? List.of(match.minuteData)
            : [
                ..._minuteData,
                AnalysteMinutePoint(
                  minute: next,
                  possession: 50,
                  fatigue: (8 + next * 0.85).clamp(0, 99),
                  winProb: 45,
                  xg: next * 0.03,
                ),
              ];
      });
    } catch (_) {
      // keep last frame
    } finally {
      _busyTick = false;
    }
  }

  double _asPct(double v) => v <= 1.5 ? v * 100 : v;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalysteDataProvider>();
    final match = provider.liveMatch;

    if (provider.loading && match == null && !_kickoffReady) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }
    if (match == null && !_kickoffReady) {
      return const OdinBackdrop(child: Center(child: Text('Aucun match live')));
    }

    final homeName = _homeTeam ?? match?.homeTeam ?? 'Domicile';
    final awayName = _awayTeam ?? match?.awayTeam ?? 'Extérieur';

    final series = _minuteData.isNotEmpty ? _minuteData : (match?.minuteData ?? const <AnalysteMinutePoint>[]);
    final displayed = series.where((d) => d.minute <= _currentMinute).toList();
    final current = displayed.isNotEmpty
        ? displayed.last
        : AnalysteMinutePoint(
            minute: _currentMinute,
            possession: 50,
            fatigue: 8 + _currentMinute * 0.8,
            winProb: 45,
            xg: _currentMinute * 0.03,
          );

    final playersLive = _players.isNotEmpty ? _players : (match?.players ?? const <AnalysteLivePlayer>[]);
    final events = _events.isNotEmpty
        ? _events.where((e) => e.minute <= _currentMinute).toList()
        : (match?.events ?? const <AnalysteMatchEvent>[]).where((e) => e.minute <= _currentMinute).toList();

    final winPct = _asPct(current.winProb);
    final drawPct = _asPct(current.drawProb > 0 ? current.drawProb : (match?.drawPct ?? 0));
    final awayPct = _asPct(current.awayProb > 0 ? current.awayProb : (match?.awayWinPct ?? 0));
    final fatPct = _asPct(current.fatigue);
    final possPct = _asPct(current.possession);

    // Affiche le scénario 1X2 le plus probable (pas seulement P(victoire))
    String oneXTwoLabel = '1X2 · Victoire';
    double oneXTwoPct = winPct;
    Color oneXTwoColor = const Color(0xFFFF7A00);
    if (drawPct >= winPct && drawPct >= awayPct) {
      oneXTwoLabel = '1X2 · Nul';
      oneXTwoPct = drawPct;
      oneXTwoColor = const Color(0xFF3B82F6);
    } else if (awayPct > winPct && awayPct > drawPct) {
      oneXTwoLabel = '1X2 · Extérieur';
      oneXTwoPct = awayPct;
      oneXTwoColor = const Color(0xFFEF4444);
    } else if (winPct >= 55) {
      oneXTwoLabel = '1X2 · Victoire';
      oneXTwoColor = const Color(0xFF22C55E);
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: const Color(0xFFEF4444),
        backgroundColor: OdinColors.panelSolid,
        onRefresh: () async {
          await _resetToKickoff();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            // ── Header score + simulate ───────────────────────────────────
            OdinAnimations.fadeUp(
              GlassCard(
                raised: true,
                accentColor: const Color(0xFFEF4444),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _PulseRadio(active: _live),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '$homeName vs $awayName',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_live) ...[
                                    const SizedBox(width: 8),
                                    _LivePill(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _feedSource == 'api-football'
                                    ? 'LIVE réel · API-Football — touchez un crest'
                                    : _feedSource == 'sim'
                                        ? 'Sim unique match · ML — touchez un crest'
                                        : 'Live Match · ML — touchez un crest',
                                style: TextStyle(fontSize: 11, color: OdinColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Inverser',
                          onPressed: _swapTeams,
                          icon: Icon(Icons.swap_horiz_rounded, color: OdinColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TeamSidePicker(
                            name: homeName,
                            onTap: () => _pickTeam(home: true),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            children: [
                              Text(
                                '$_homeScore  -  $_awayScore',
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  "$_currentMinute'",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _TeamSidePicker(
                            name: awayName,
                            onTap: () => _pickTeam(home: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _toggleLive,
                        icon: Icon(_live ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                        label: Text(
                          _live ? 'Pause' : 'Simuler Live',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _live
                              ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                              : const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: _live
                                ? BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.5))
                                : BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              index: 0,
            ),

            const SizedBox(height: 12),

            // ── KPI grid ──────────────────────────────────────────────────
            OdinAnimations.fadeUp(
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.55,
                children: [
                  _KpiTile(
                    label: oneXTwoLabel,
                    value: '${oneXTwoPct.round()}%',
                    color: oneXTwoColor,
                    icon: Icons.trending_up_rounded,
                    pulse: _live,
                  ),
                  _KpiTile(
                    label: '1X2 détail',
                    value: '${winPct.round()}/${drawPct.round()}/${awayPct.round()}',
                    color: const Color(0xFFA78BFA),
                    icon: Icons.percent_rounded,
                    pulse: _live,
                  ),
                  _KpiTile(
                    label: 'Fatigue équipe',
                    value: '${fatPct.round()}%',
                    color: fatPct >= 70 ? const Color(0xFFEF4444) : const Color(0xFFFF7A00),
                    icon: Icons.warning_amber_rounded,
                    pulse: _live,
                  ),
                  _KpiTile(
                    label: 'Possession',
                    value: '${possPct.round()}%',
                    color: const Color(0xFF3B82F6),
                    icon: Icons.groups_rounded,
                    pulse: _live,
                  ),
                ],
              ),
              index: 1,
            ),

            const SizedBox(height: 14),

            // ── Win prob chart ────────────────────────────────────────────
            OdinAnimations.fadeUp(
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1X2 en temps réel (ML calibré)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                     Text(
                      'Vert = victoire domicile · Bleu = nul · Rouge = extérieur',
                      style: TextStyle(fontSize: 10, color: OdinColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 170,
                      child: displayed.length < 2
                          ? Center(child: Text('En attente de données…', style: TextStyle(color: OdinColors.textMuted, fontSize: 12)))
                          : LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: 100,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
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
                                      interval: 25,
                                      getTitlesWidget: (v, _) => Text(
                                        '${v.toInt()}',
                                        style: TextStyle(color: OdinColors.textMuted, fontSize: 9),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      interval: 15,
                                      getTitlesWidget: (v, _) => Text(
                                        "${v.toInt()}'",
                                        style: TextStyle(color: OdinColors.textMuted, fontSize: 9),
                                      ),
                                    ),
                                  ),
                                ),
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (_) => const Color(0xF5050816),
                                    getTooltipItems: (spots) => spots
                                        .map((s) => LineTooltipItem(
                                              '${s.y.round()}%',
                                              TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: [
                                      for (final p in displayed)
                                        FlSpot(p.minute.toDouble(), _asPct(p.winProb)),
                                    ],
                                    isCurved: true,
                                    color: const Color(0xFF22C55E),
                                    barWidth: 2.5,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: [
                                      for (final p in displayed)
                                        FlSpot(
                                          p.minute.toDouble(),
                                          _asPct(p.drawProb > 0 ? p.drawProb : (100 - p.winProb - p.awayProb).clamp(0, 100)),
                                        ),
                                    ],
                                    isCurved: true,
                                    color: const Color(0xFF3B82F6),
                                    barWidth: 2.2,
                                    dotData: const FlDotData(show: false),
                                  ),
                                  LineChartBarData(
                                    spots: [
                                      for (final p in displayed)
                                        FlSpot(p.minute.toDouble(), _asPct(p.awayProb)),
                                    ],
                                    isCurved: true,
                                    color: const Color(0xFFEF4444),
                                    barWidth: 2.0,
                                    dotData: const FlDotData(show: false),
                                  ),
                                ],
                              ),
                              duration: Duration.zero,
                            ),
                    ),
                  ],
                ),
              ),
              index: 2,
            ),

            const SizedBox(height: 12),

            // ── Fatigue & Possession ──────────────────────────────────────
            OdinAnimations.fadeUp(
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fatigue & Possession',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _LegendDot(color: const Color(0xFFEF4444), label: 'Fatigue'),
                        const SizedBox(width: 14),
                        _LegendDot(color: const Color(0xFF3B82F6), label: 'Possession'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 170,
                      child: displayed.length < 2
                          ? const SizedBox.shrink()
                          : LineChart(
                              LineChartData(
                                minY: 0,
                                maxY: 100,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (_) => FlLine(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    strokeWidth: 1,
                                    dashArray: [4, 4],
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
                                        '${v.toInt()}',
                                        style: TextStyle(color: OdinColors.textMuted, fontSize: 9),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 22,
                                      interval: 15,
                                      getTitlesWidget: (v, _) => Text(
                                        "${v.toInt()}'",
                                        style: TextStyle(color: OdinColors.textMuted, fontSize: 9),
                                      ),
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: [
                                      for (final p in displayed)
                                        FlSpot(p.minute.toDouble(), _asPct(p.fatigue)),
                                    ],
                                    isCurved: true,
                                    color: const Color(0xFFEF4444),
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                    ),
                                  ),
                                  LineChartBarData(
                                    spots: [
                                      for (final p in displayed)
                                        FlSpot(p.minute.toDouble(), _asPct(p.possession)),
                                    ],
                                    isCurved: true,
                                    color: const Color(0xFF3B82F6),
                                    barWidth: 2,
                                    dotData: const FlDotData(show: false),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                    ),
                                  ),
                                ],
                              ),
                              duration: Duration.zero,
                            ),
                    ),
                  ],
                ),
              ),
              index: 3,
            ),

            const SizedBox(height: 12),

            // ── Events ────────────────────────────────────────────────────
            OdinAnimations.fadeUp(
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Événements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 10),
                    if (events.isEmpty)
                       Text('Aucun événement encore', style: TextStyle(color: OdinColors.textMuted, fontSize: 12))
                    else
                      ...events.map((ev) {
                        final color = switch (ev.type.toLowerCase()) {
                          'goal' || 'but' => const Color(0xFF22C55E),
                          'card' || 'carton' => const Color(0xFFF59E0B),
                          'sub' || 'remplacement' => const Color(0xFF3B82F6),
                          _ => const Color(0xFF8B5CF6),
                        };
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${ev.minute}'",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ev.player, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                      if (ev.desc.isNotEmpty)
                                        Text(ev.desc, style: TextStyle(color: OdinColors.textMuted, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              index: 4,
            ),

            const SizedBox(height: 12),

            // ── AI substitutions ──────────────────────────────────────────
            OdinAnimations.fadeUp(
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Remplacement suggéré IA',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.sensors, size: 10, color: Color(0xFFEF4444)),
                              SizedBox(width: 4),
                              Text('Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
                            ],
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .fade(begin: 1, end: 0.45, duration: 1200.ms)
                            .then()
                            .fade(begin: 0.45, end: 1, duration: 1200.ms),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...playersLive.map((p) {
                      final fatigue = _asPct(p.fatigue);
                      final fColor = fatigue >= 75
                          ? const Color(0xFFEF4444)
                          : fatigue >= 60
                              ? const Color(0xFFFF7A00)
                              : const Color(0xFF22C55E);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: p.shouldSub
                                ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                                : Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: p.shouldSub
                                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                    Text(
                                      'Fatigue ${fatigue.round()}% · Risk ${_asPct(p.risk).round()}%',
                                      style: TextStyle(fontSize: 10, color: fColor, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              if (p.shouldSub)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '↗ Remplacer',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                                  ),
                                )
                                    .animate(onPlay: (c) => c.repeat(reverse: true))
                                    .scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.06, 1.06),
                                      duration: 900.ms,
                                    ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              index: 5,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamSidePicker extends StatelessWidget {
  const _TeamSidePicker({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            children: [
              ClubLogo(
                clubName: name,
                size: 48,
                radius: 14,
                padding: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.92),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, height: 1.2),
              ),
              const SizedBox(height: 2),
              const Text(
                'Changer',
                style: TextStyle(fontSize: 9, color: OdinColors.accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamPickerSheet extends StatefulWidget {
  const _TeamPickerSheet({
    required this.title,
    required this.teams,
    required this.selected,
    this.excluded,
  });

  final String title;
  final List<String> teams;
  final String selected;
  final String? excluded;

  @override
  State<_TeamPickerSheet> createState() => _TeamPickerSheetState();
}

class _TeamPickerSheetState extends State<_TeamPickerSheet> {
  late final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toLowerCase();
    final filtered = widget.teams.where((t) {
      if (widget.excluded != null && t.toLowerCase() == widget.excluded!.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) return true;
      return t.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              '${filtered.length} club${filtered.length > 1 ? 's' : ''} · monde entier',
              style: TextStyle(fontSize: 12, color: OdinColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher un club…',
                prefixIcon: Icon(Icons.search_rounded, color: OdinColors.textMuted),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final team = filtered[i];
                  final selected = team.toLowerCase() == widget.selected.toLowerCase();
                  return Material(
                    color: selected
                        ? OdinColors.accent.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, team),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            ClubLogo(
                              clubName: team,
                              size: 36,
                              radius: 10,
                              padding: 3,
                              backgroundColor: Colors.white.withValues(alpha: 0.92),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                team,
                                style: TextStyle(
                                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle_rounded, color: OdinColors.accent, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared analyste UI ───────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.pulse = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    Widget iconBox = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 16, color: color),
    );
    if (pulse) {
      iconBox = iconBox
          .animate(onPlay: (c) => c.repeat())
          .boxShadow(
            begin: BoxShadow(color: color.withValues(alpha: 0), blurRadius: 0),
            end: BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14),
            duration: 1200.ms,
          )
          .then()
          .boxShadow(
            begin: BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14),
            end: BoxShadow(color: color.withValues(alpha: 0), blurRadius: 0),
            duration: 1200.ms,
          );
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          iconBox,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  key: ValueKey(value),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 9, color: OdinColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRadio extends StatelessWidget {
  const _PulseRadio({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    Widget box = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.sensors, color: Color(0xFFEF4444), size: 20),
    );
    if (!active) return box;
    return box
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12), duration: 700.ms);
  }
}

class _LivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '● LIVE',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .fade(begin: 1, end: 0.4, duration: 900.ms)
        .then()
        .fade(begin: 0.4, end: 1, duration: 900.ms);
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
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
      ],
    );
  }
}
