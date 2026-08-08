import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/club_logo.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/analyste_provider.dart';

/// Match Prediction — résultat ML structuré (plus de dump JSON / overflow).
class AnalystePredictionScreen extends StatefulWidget {
  const AnalystePredictionScreen({super.key});

  static const accent = Color(0xFF8B5CF6);

  @override
  State<AnalystePredictionScreen> createState() => _AnalystePredictionScreenState();
}

class _AnalystePredictionScreenState extends State<AnalystePredictionScreen> {
  List<String> _teams = [];
  String? _home;
  String? _away;
  Map<String, dynamic>? _prediction;
  bool _loadingTeams = true;
  bool _predicting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTeams());
  }

  Future<void> _loadTeams() async {
    setState(() {
      _loadingTeams = true;
      _error = null;
    });
    try {
      final teams = await context.read<AnalysteDataProvider>().api.getPredictionTeams();
      if (!mounted) return;
      final merged = <String>{
        ...teams.where((t) => t.trim().isNotEmpty),
        ...kSelectableClubs,
      }.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _teams = merged.isNotEmpty ? merged : List.of(kSelectableClubs);
        _home = _teams.isNotEmpty ? _teams.first : null;
        _away = _teams.length > 1 ? _teams[1] : _home;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _teams = List.of(kSelectableClubs);
          _home = _teams.first;
          _away = _teams.length > 1 ? _teams[1] : _home;
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loadingTeams = false);
    }
  }

  Future<void> _predict() async {
    if (_home == null || _away == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _predicting = true;
      _error = null;
      _prediction = null;
    });
    try {
      final res = await context.read<AnalysteDataProvider>().api.predictMatch(_home!, _away!);
      if (!mounted) return;
      final pred = res['prediction'];
      setState(() {
        _prediction = pred is Map ? Map<String, dynamic>.from(pred) : res;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _predicting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
        children: [
          OdinAnimations.fadeUp(
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AnalystePredictionScreen.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.psychology_rounded, color: AnalystePredictionScreen.accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Match Prediction', style: tt.headlineMedium),
                      Text(
                        'RF · XGBoost · CatBoost',
                        style: tt.bodyMedium?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            index: 0,
          ),
          const SizedBox(height: AppSpacing.m),
          if (_loadingTeams)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else ...[
            OdinAnimations.fadeUp(
              GlassCard(
                raised: true,
                accentColor: AnalystePredictionScreen.accent,
                child: Column(
                  children: [
                    _TeamDropdown(
                      label: 'Domicile',
                      value: _home,
                      teams: _teams,
                      accent: const Color(0xFFFF7A00),
                      onChanged: (v) => setState(() => _home = v),
                    ),
                    const SizedBox(height: 12),
                    _TeamDropdown(
                      label: 'Extérieur',
                      value: _away,
                      teams: _teams.where((t) => t != _home).toList().isEmpty ? _teams : _teams.where((t) => t != _home).toList(),
                      accent: const Color(0xFF3B82F6),
                      onChanged: (v) => setState(() => _away = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _predicting ? null : _predict,
                        icon: Icon(_predicting ? Icons.hourglass_top_rounded : Icons.psychology_rounded, size: 18),
                        label: Text(
                          _predicting ? 'Calcul ML…' : 'Lancer la prédiction',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AnalystePredictionScreen.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              index: 1,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              GlassCard(
                child: Text(_error!, style: const TextStyle(color: OdinColors.danger, fontSize: 12)),
              ),
            ],
            if (_predicting) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(color: AnalystePredictionScreen.accent),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Analyse des matchs historiques…',
                      style: TextStyle(color: AnalystePredictionScreen.accent.withValues(alpha: 0.9), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
            if (_prediction != null && !_predicting) ...[
              const SizedBox(height: 16),
              _PredictionResultView(
                home: _home ?? 'Domicile',
                away: _away ?? 'Extérieur',
                data: _prediction!,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TeamDropdown extends StatelessWidget {
  const _TeamDropdown({
    required this.label,
    required this.value,
    required this.teams,
    required this.onChanged,
    required this.accent,
  });

  final String label;
  final String? value;
  final List<String> teams;
  final ValueChanged<String?> onChanged;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value != null && teams.contains(value) ? value : null,
          isExpanded: true,
          items: teams
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      ClubLogo(
                        clubName: t,
                        size: 22,
                        radius: 6,
                        padding: 2,
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(t, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: accent.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }
}

class _PredictionResultView extends StatelessWidget {
  const _PredictionResultView({
    required this.home,
    required this.away,
    required this.data,
  });

  final String home;
  final String away;
  final Map<String, dynamic> data;

  int _n(String key) => (data[key] as num?)?.round() ?? 0;
  double _d(String key) => (data[key] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final win = _n('win');
    final draw = _n('draw');
    final loss = _n('loss');
    final xgHome = _d('xgHome');
    final xgAway = _d('xgAway');
    final scores = (data['scores'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];
    final models = (data['models'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];
    final factors = (data['factors'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];
    final keyPlayers = (data['keyPlayers'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];

    final homeShort = home.split(' ').last;
    final awayShort = away.split(' ').last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OdinAnimations.fadeUp(const SectionTitle('Résultat'), index: 2),
        const SizedBox(height: 8),
        OdinAnimations.fadeUp(
          GlassCard(
            raised: true,
            accentColor: AnalystePredictionScreen.accent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$homeShort vs $awayShort',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.gps_fixed_rounded, size: 16, color: AnalystePredictionScreen.accent),
                  ],
                ),
                const SizedBox(height: 14),
                _OutcomeBar(label: 'Victoire $homeShort', value: win, color: const Color(0xFF22C55E)),
                const SizedBox(height: 10),
                _OutcomeBar(label: 'Match nul', value: draw, color: const Color(0xFFF59E0B)),
                const SizedBox(height: 10),
                _OutcomeBar(label: 'Victoire $awayShort', value: loss, color: const Color(0xFF3B82F6)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _XgTile(label: 'xG $homeShort', value: xgHome, color: const Color(0xFF22C55E))),
                    const SizedBox(width: 10),
                    Expanded(child: _XgTile(label: 'xG $awayShort', value: xgAway, color: const Color(0xFF3B82F6))),
                  ],
                ),
              ],
            ),
          ),
          index: 3,
        ),

        if (scores.isNotEmpty) ...[
          const SizedBox(height: 14),
          OdinAnimations.fadeUp(const SectionTitle('Scores probables'), index: 4),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Column(
                children: [
                  for (var i = 0; i < scores.length; i++) ...[
                    _ScoreRow(
                      score: scores[i]['score']?.toString() ?? '—',
                      prob: (scores[i]['prob'] as num?)?.round() ?? 0,
                      highlight: i == 0,
                    ),
                    if (i < scores.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            index: 5,
          ),
        ],

        if (models.isNotEmpty) ...[
          const SizedBox(height: 14),
          OdinAnimations.fadeUp(const SectionTitle('Modèles ML'), index: 6),
          const SizedBox(height: 8),
          ...List.generate(models.length, (i) {
            final m = models[i];
            return OdinAnimations.fadeUp(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['name']?.toString() ?? 'Modèle',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _MiniStat('Win', m['win'], const Color(0xFF22C55E))),
                          Expanded(child: _MiniStat('Draw', m['draw'], const Color(0xFFF59E0B))),
                          Expanded(child: _MiniStat('Loss', m['loss'], const Color(0xFF3B82F6))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              index: 7 + i,
            );
          }),
        ],

        if (factors.isNotEmpty) ...[
          const SizedBox(height: 6),
          OdinAnimations.fadeUp(const SectionTitle('Facteurs'), index: 10),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Column(
                children: [
                  for (final f in factors) ...[
                    _FactorRow(
                      label: f['label']?.toString() ?? 'Facteur',
                      home: (f['home'] as num?)?.round() ?? 0,
                      away: (f['away'] as num?)?.round() ?? 0,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            index: 11,
          ),
        ],

        if (keyPlayers.isNotEmpty) ...[
          OdinAnimations.fadeUp(const SectionTitle('Joueurs clés'), index: 12),
          const SizedBox(height: 8),
          ...List.generate(keyPlayers.length, (i) {
            final p = keyPlayers[i];
            final color = _parseColor(p['color']?.toString()) ?? AnalystePredictionScreen.accent;
            return OdinAnimations.fadeUp(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p['name']?.toString() ?? 'Joueur',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          p['impact']?.toString() ?? '',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              index: 13 + i,
            );
          }),
        ],
      ],
    );
  }
}

class _OutcomeBar extends StatelessWidget {
  const _OutcomeBar({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text('$value%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (value / 100).clamp(0.0, 1.0)),
              duration: 800.ms,
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 88,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: OdinColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _XgTile extends StatelessWidget {
  const _XgTile({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.score, required this.prob, required this.highlight});
  final String score;
  final int prob;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: highlight
                ? AnalystePredictionScreen.accent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            score,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: highlight ? AnalystePredictionScreen.accent : OdinColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (prob / 25).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: highlight ? AnalystePredictionScreen.accent : Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$prob%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: OdinColors.textMuted)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value, this.color);
  final String label;
  final dynamic value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final n = (value as num?)?.round() ?? 0;
    return Column(
      children: [
        Text('$n%', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
      ],
    );
  }
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.label, required this.home, required this.away});
  final String label;
  final int home;
  final int away;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(width: 28, child: Text('$home', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFFF7A00)))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (home / 100).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  color: const Color(0xFFFF7A00),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(width: 28, child: Text('$away', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF3B82F6)))),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (away / 100).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}
