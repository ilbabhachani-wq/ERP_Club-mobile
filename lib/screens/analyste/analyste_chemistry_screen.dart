import 'dart:math' as math;
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

/// Team Chemistry — rendu SaaS (plus de dump JSON brut).
class AnalysteChemistryScreen extends StatefulWidget {
  const AnalysteChemistryScreen({super.key});

  static const accent = Color(0xFF22C55E);

  @override
  State<AnalysteChemistryScreen> createState() => _AnalysteChemistryScreenState();
}

class _AnalysteChemistryScreenState extends State<AnalysteChemistryScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String? _focusPlayer;
  _ChemPair? _selected;

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
      final data = await context.read<AnalysteDataProvider>().api.getChemistry();
      if (!mounted) return;
      final summary = data['summary'];
      _ChemPair? best;
      if (summary is Map && summary['bestPair'] is Map) {
        best = _ChemPair.fromJson(Map<String, dynamic>.from(summary['bestPair'] as Map));
      }
      setState(() {
        _data = data;
        _selected = best;
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
        color: AnalysteChemistryScreen.accent,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(
              Text('Team Chemistry', style: tt.headlineMedium),
              index: 0,
            ),
            OdinAnimations.fadeUp(
              Text('Graphe relationnel', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
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
                      child: SaasCardSkeleton(height: 72),
                    ),
                  ),
                ),
              )
            else if (_error != null)
              GlassCard(
                child: SaasEmptyState(
                  icon: Icons.hub_outlined,
                  title: 'Chimie indisponible',
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
    final summary = data['summary'];
    final summaryMap = summary is Map ? Map<String, dynamic>.from(summary) : <String, dynamic>{};
    final teamAvg = (summaryMap['teamAvg'] as num?)?.round() ?? 0;
    final best = _ChemPair.tryParse(summaryMap['bestPair']);
    final worst = _ChemPair.tryParse(summaryMap['worstPair']);
    final topDuos = (summaryMap['topDuos'] as List?)
            ?.whereType<Map>()
            .map((e) => _ChemPair.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <_ChemPair>[];
    final players = (data['players'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
    final matrix = (data['matrix'] as List?)
            ?.whereType<Map>()
            .map((e) => _ChemPair.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        topDuos;
    final positionsRaw = data['nodePositions'];
    final positions = <String, Offset>{};
    if (positionsRaw is Map) {
      for (final e in positionsRaw.entries) {
        final v = e.value;
        if (v is Map) {
          final x = (v['x'] as num?)?.toDouble() ?? 50;
          final y = (v['y'] as num?)?.toDouble() ?? 50;
          positions[e.key.toString()] = Offset(x / 100, y / 100);
        }
      }
    }

    final avgColor = _chemColor(teamAvg.toDouble());
    final selected = _selected ?? best;
    final graphPlayers = players.isNotEmpty
        ? players
        : {...matrix.expand((m) => [m.a, m.b])}.toList();

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
            _Kpi(
              label: 'Chimie moyenne',
              value: '$teamAvg%',
              color: avgColor,
              icon: Icons.groups_rounded,
            ),
            _Kpi(
              label: 'Meilleur duo',
              value: best == null ? '—' : '${best.a} ↔ ${best.b}',
              color: AnalysteChemistryScreen.accent,
              icon: Icons.link_rounded,
            ),
            _Kpi(
              label: 'Score top duo',
              value: best == null ? '—' : '${best.score}%',
              color: AnalysteChemistryScreen.accent,
              icon: Icons.trending_up_rounded,
            ),
            _Kpi(
              label: 'À améliorer',
              value: worst == null ? '—' : '${worst.a} ↔ ${worst.b}',
              color: const Color(0xFFEF4444),
              icon: Icons.link_off_rounded,
            ),
          ],
        ),
        index: 2,
      ),
      const SizedBox(height: 16),
      OdinAnimations.fadeUp(const SectionTitle('Graphe relationnel'), index: 3),
      const SizedBox(height: 8),
      OdinAnimations.fadeUp(
        GlassCard(
          raised: true,
          accentColor: const Color(0xFF8B5CF6),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (graphPlayers.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: graphPlayers.map((p) {
                    final on = _focusPlayer == p;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _focusPlayer = on ? null : p);
                      },
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: on
                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: on
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: on ? const Color(0xFFC4B5FD) : OdinColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 220,
                child: CustomPaint(
                  painter: _ChemGraphPainter(
                    players: graphPlayers,
                    links: matrix,
                    positions: positions,
                    focus: _focusPlayer,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        index: 4,
      ),
      const SizedBox(height: 16),
      OdinAnimations.fadeUp(const SectionTitle('Top duos'), index: 5),
      const SizedBox(height: 8),
      ...List.generate(topDuos.length, (i) {
        final duo = topDuos[i];
        final selectedDuo = selected?.a == duo.a && selected?.b == duo.b;
        return OdinAnimations.fadeUp(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selected = duo);
                },
                child: GlassCard(
                  accentColor: selectedDuo ? AnalysteChemistryScreen.accent : null,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _chemColor(duo.score.toDouble()).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _chemColor(duo.score.toDouble()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${duo.a}  ↔  ${duo.b}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: duo.score / 100,
                                minHeight: 5,
                                backgroundColor: Colors.white.withValues(alpha: 0.06),
                                color: _chemColor(duo.score.toDouble()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${duo.score}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _chemColor(duo.score.toDouble()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          index: 6 + i,
        );
      }),
      if (selected != null) ...[
        const SizedBox(height: 8),
        OdinAnimations.fadeUp(const SectionTitle('Détail duo'), index: 12),
        const SizedBox(height: 8),
        OdinAnimations.fadeUp(
          GlassCard(
            raised: true,
            accentColor: AnalysteChemistryScreen.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selected.a} ↔ ${selected.b}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 14),
                _MetricBar(label: 'Global', value: selected.score, color: _chemColor(selected.score.toDouble())),
                _MetricBar(label: 'Passes', value: selected.passing, color: const Color(0xFF38BDF8)),
                _MetricBar(label: 'Mouvement', value: selected.movement, color: const Color(0xFFA855F7)),
                _MetricBar(label: 'Pressing', value: selected.pressing, color: const Color(0xFFFF7A00)),
                _MetricBar(label: 'Historique', value: selected.history, color: const Color(0xFFF59E0B)),
              ],
            ),
          ),
          index: 13,
        ),
      ],
      if (worst != null) ...[
        const SizedBox(height: 16),
        OdinAnimations.fadeUp(const SectionTitle('Duo à améliorer'), index: 14),
        const SizedBox(height: 8),
        OdinAnimations.fadeUp(
          GlassCard(
            accentColor: const Color(0xFFEF4444),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.priority_high_rounded, color: Color(0xFFEF4444), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${worst.a} ↔ ${worst.b}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Score ${worst.score}% — travail de combinaison recommandé',
                        style: TextStyle(color: OdinColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          index: 15,
        ),
      ],
    ];
  }
}

class _ChemPair {
  const _ChemPair({
    required this.a,
    required this.b,
    required this.score,
    this.passing = 0,
    this.movement = 0,
    this.pressing = 0,
    this.history = 0,
  });

  final String a;
  final String b;
  final int score;
  final int passing;
  final int movement;
  final int pressing;
  final int history;

  factory _ChemPair.fromJson(Map<String, dynamic> json) {
    return _ChemPair(
      a: json['a']?.toString() ?? '—',
      b: json['b']?.toString() ?? '—',
      score: (json['score'] as num?)?.round() ?? 0,
      passing: (json['passing'] as num?)?.round() ?? 0,
      movement: (json['movement'] as num?)?.round() ?? 0,
      pressing: (json['pressing'] as num?)?.round() ?? 0,
      history: (json['history'] as num?)?.round() ?? 0,
    );
  }

  static _ChemPair? tryParse(dynamic v) {
    if (v is Map) return _ChemPair.fromJson(Map<String, dynamic>.from(v));
    return null;
  }
}

Color _chemColor(double score) {
  if (score >= 85) return const Color(0xFF22C55E);
  if (score >= 70) return const Color(0xFFF59E0B);
  if (score >= 55) return const Color(0xFFFF7A00);
  return const Color(0xFFEF4444);
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

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
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: OdinColors.textMuted))),
              Text('$value', style: TextStyle(fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
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

class _ChemGraphPainter extends CustomPainter {
  _ChemGraphPainter({
    required this.players,
    required this.links,
    required this.positions,
    this.focus,
  });

  final List<String> players;
  final List<_ChemPair> links;
  final Map<String, Offset> positions;
  final String? focus;

  Offset _pos(String name, Size size) {
    final p = positions[name];
    if (p != null) return Offset(p.dx * size.width, p.dy * size.height);
    final i = players.indexOf(name);
    if (i < 0 || players.isEmpty) return Offset(size.width / 2, size.height / 2);
    final angle = (i / players.length) * math.pi * 2 - math.pi / 2;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide * 0.36;
    return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );

    for (final link in links) {
      final active = focus == null || link.a == focus || link.b == focus;
      if (!active) continue;
      final a = _pos(link.a, size);
      final b = _pos(link.b, size);
      final color = _chemColor(link.score.toDouble());
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color.withValues(alpha: focus == null ? 0.35 : 0.75)
          ..strokeWidth = focus == null ? 1.5 : 2.4
          ..style = PaintingStyle.stroke,
      );
    }

    for (final name in players) {
      final p = _pos(name, size);
      final on = focus == null || focus == name;
      canvas.drawCircle(p, on ? 14 : 10, Paint()..color = on ? const Color(0xFF8B5CF6) : const Color(0xFF334155));
      canvas.drawCircle(
        p,
        on ? 14 : 10,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final label = name.length > 6 ? '${name.substring(0, 5)}…' : name;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: on ? Colors.white : OdinColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy + 16));
    }
  }

  @override
  bool shouldRepaint(covariant _ChemGraphPainter oldDelegate) {
    return oldDelegate.focus != focus || oldDelegate.links != links || oldDelegate.players != players;
  }
}
