import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/coach_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/coach_provider.dart';
import '../../core/theme/odin_colors.dart';
import '../../providers/theme_provider.dart';

class CoachAnalyseMatchScreen extends StatefulWidget {
  const CoachAnalyseMatchScreen({super.key});

  @override
  State<CoachAnalyseMatchScreen> createState() =>
      _CoachAnalyseMatchScreenState();
}

class _CoachAnalyseMatchScreenState extends State<CoachAnalyseMatchScreen> {
  static Color get _bg => OdinColors.canvas;
  static Color get _bar => OdinColors.canvas2;
  static const _accent = OdinColors.accent;

  int _index = 0;
  bool _saving = false;
  bool _loadingAnalysis = false;
  String? _loadedMatchId;

  double _teamRating = 6;
  final Map<String, int> _playerRatings = {};
  final Map<String, TextEditingController> _playerComments = {};

  int _goals = 0;
  int _shots = 0;
  int _possession = 50;
  int _corners = 0;
  int _yellow = 0;
  int _red = 0;
  final _coachNotesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<CoachProvider>();
      await prov.loadAll();
      if (!mounted) return;
      _ensurePlayers(prov);
      final items = _matchItems(prov);
      if (items.isNotEmpty) {
        await _selectMatch(prov, 0, items);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _coachNotesCtrl.dispose();
    for (final c in _playerComments.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<_MatchItem> _matchItems(CoachProvider prov) {
    if (prov.matches.isNotEmpty) {
      return prov.matches.map(_MatchItem.fromMatch).toList();
    }
    return prov.matchEvents.map(_MatchItem.fromSession).toList();
  }

  void _ensurePlayers(CoachProvider prov) {
    for (final p in prov.players) {
      _playerRatings.putIfAbsent(p.id, () => 6);
      _playerComments.putIfAbsent(p.id, () => TextEditingController());
    }
  }

  void _resetForm() {
    _goals = 0;
    _shots = 0;
    _possession = 50;
    _corners = 0;
    _yellow = 0;
    _red = 0;
    _coachNotesCtrl.clear();
    _teamRating = 6;
    for (final id in _playerRatings.keys) {
      _playerRatings[id] = 6;
    }
    for (final c in _playerComments.values) {
      c.clear();
    }
  }

  Future<void> _selectMatch(
    CoachProvider prov,
    int index,
    List<_MatchItem> items,
  ) async {
    if (items.isEmpty) return;
    final i = index.clamp(0, items.length - 1);
    final match = items[i];
    setState(() {
      _index = i;
      _loadingAnalysis = true;
      _loadedMatchId = match.id;
      _resetForm();
      _ensurePlayers(prov);
    });

    final data = await prov.loadMatchAnalysis(match.id);
    if (!mounted || _loadedMatchId != match.id) return;

    if (data != null) {
      _applyAnalysis(data, prov);
    }
    setState(() => _loadingAnalysis = false);
  }

  int _clampStat(dynamic v, {int fallback = 0, int max = 99}) {
    final n = (v is num) ? v.toInt() : int.tryParse('$v') ?? fallback;
    return n.clamp(0, max);
  }

  void _applyAnalysis(Map<String, dynamic> data, CoachProvider prov) {
    _goals = _clampStat(data['goals']);
    _shots = _clampStat(data['shotsOnTarget']);
    _possession = _clampStat(data['possession'], fallback: 50, max: 100);
    _corners = _clampStat(data['corners']);
    _yellow = _clampStat(data['yellowCards']);
    _red = _clampStat(data['redCards']);
    _teamRating = ((data['teamRating'] as num?)?.toDouble() ?? 6).clamp(1, 10);
    _coachNotesCtrl.text = data['coachNotes']?.toString() ?? '';

    final notes = data['playerNotes'];
    if (notes is Map) {
      for (final p in prov.players) {
        final entry = notes[p.id];
        if (entry is Map) {
          final r = (entry['rating'] as num?)?.toInt() ?? 6;
          _playerRatings[p.id] = r.clamp(1, 10);
          _playerComments[p.id]?.text = entry['comment']?.toString() ?? '';
        }
      }
    }
  }

  Future<void> _save(CoachProvider prov, _MatchItem match) async {
    setState(() => _saving = true);
    final playerNotes = <String, dynamic>{};
    for (final p in prov.players) {
      playerNotes[p.id] = {
        'rating': _playerRatings[p.id] ?? 6,
        'comment': _playerComments[p.id]?.text.trim() ?? '',
      };
    }
    final data = <String, dynamic>{
      'goals': _goals,
      'shotsOnTarget': _shots,
      'possession': _possession,
      'corners': _corners,
      'yellowCards': _yellow,
      'redCards': _red,
      'teamRating': _teamRating,
      'coachNotes': _coachNotesCtrl.text.trim(),
      'playerNotes': playerNotes,
    };
    try {
      await prov.saveMatchAnalysis(match.id, data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analyse sauvegardée'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _resultColor(String? label) {
    final s = (label ?? '').toLowerCase();
    if (s.contains('victoire') || s == 'w' || s == 'v') {
      return const Color(0xFF22C55E);
    }
    if (s.contains('défaite') || s.contains('defaite') || s == 'l' || s == 'd') {
      return const Color(0xFFEF4444);
    }
    if (s.contains('nul') || s == 'n' || s == 'draw') {
      return const Color(0xFF9CA3AF);
    }
    return _accent;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final prov = context.watch<CoachProvider>();
    final club =
        context.watch<AuthProvider>().user?.organization?.clubName ?? 'Club';
    final items = _matchItems(prov);
    final match =
        items.isEmpty ? null : items[_index.clamp(0, items.length - 1)];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bar,
        elevation: 0,
        title: Text(
          'Analyse de match',
          style: TextStyle(
            color: OdinColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: prov.loading && items.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: _accent),
            )
          : items.isEmpty
              ? Center(
                  child: Text(
                    'Aucun match disponible',
                    style: TextStyle(color: OdinColors.textSecondary),
                  ),
                )
              : Column(
                  children: [
                    _MatchCarousel(
                      index: _index,
                      total: items.length,
                      label: match!.carouselLabel,
                      onPrev: _index > 0
                          ? () => _selectMatch(prov, _index - 1, items)
                          : null,
                      onNext: _index < items.length - 1
                          ? () => _selectMatch(prov, _index + 1, items)
                          : null,
                    ),
                    Expanded(
                      child: _loadingAnalysis
                          ? const Center(
                              child: CircularProgressIndicator(color: _accent),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              children: [
                                _MatchHeader(
                                  club: club,
                                  match: match,
                                  resultColor: _resultColor(match.resultLabel),
                                ),
                                const SizedBox(height: 16),
                                const _SectionTitle('Statistiques'),
                                const SizedBox(height: 12),
                                _StatsGrid(
                                  goals: _goals,
                                  shots: _shots,
                                  possession: _possession,
                                  corners: _corners,
                                  yellow: _yellow,
                                  red: _red,
                                  onGoals: (v) => setState(() => _goals = v),
                                  onShots: (v) => setState(() => _shots = v),
                                  onPossession: (v) =>
                                      setState(() => _possession = v),
                                  onCorners: (v) =>
                                      setState(() => _corners = v),
                                  onYellow: (v) => setState(() => _yellow = v),
                                  onRed: (v) => setState(() => _red = v),
                                ),
                                const SizedBox(height: 16),
                                const _SectionTitle('Note équipe'),
                                const SizedBox(height: 12),
                                _TeamRatingCard(
                                  rating: _teamRating,
                                  onChanged: (v) =>
                                      setState(() => _teamRating = v),
                                ),
                                const SizedBox(height: 16),
                                _SectionTitle(
                                  'Notes joueurs (${prov.players.length})',
                                ),
                                const SizedBox(height: 12),
                                if (prov.players.isEmpty)
                                  Text(
                                    'Aucun joueur dans l\'effectif',
                                    style: TextStyle(
                                      color:
                                          OdinColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  )
                                else
                                  ...prov.players.map((p) {
                                    _playerRatings.putIfAbsent(p.id, () => 6);
                                    _playerComments.putIfAbsent(
                                      p.id,
                                      () => TextEditingController(),
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _PlayerNoteRow(
                                        player: p,
                                        rating: _playerRatings[p.id]!,
                                        commentCtrl: _playerComments[p.id]!,
                                        onRating: (v) => setState(
                                          () => _playerRatings[p.id] = v,
                                        ),
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 4),
                                const _SectionTitle('Notes du coach'),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _coachNotesCtrl,
                                  maxLines: 4,
                                  minLines: 3,
                                  style: TextStyle(
                                    color: OdinColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Observations tactiques, points clés…',
                                    hintStyle: TextStyle(
                                      color:
                                          OdinColors.textMuted.withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor:
                                        OdinColors.panelBorder.withValues(alpha: 0.5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                    ),
                    _StickySaveBar(
                      saving: _saving,
                      onSave: () => _save(prov, match),
                    ),
                  ],
                ),
    );
  }
}

// ─── Match model bridge ──────────────────────────────────────────────────────

class _MatchItem {
  const _MatchItem({
    required this.id,
    required this.opponent,
    required this.competition,
    required this.dateLabel,
    required this.homeAwayLabel,
    this.score,
    this.resultLabel,
  });

  factory _MatchItem.fromMatch(CoachMatch m) => _MatchItem(
        id: m.id,
        opponent: m.opponent,
        competition: m.competition,
        dateLabel: m.matchDate.isNotEmpty ? m.matchDate : m.matchDateISO,
        homeAwayLabel: m.homeAwayLabel,
        score: m.score,
        resultLabel: m.resultLabel,
      );

  factory _MatchItem.fromSession(CoachSession s) => _MatchItem(
        id: s.id,
        opponent: s.title,
        competition: s.location,
        dateLabel: s.dateKey,
        homeAwayLabel: '',
      );

  final String id;
  final String opponent;
  final String competition;
  final String dateLabel;
  final String homeAwayLabel;
  final String? score;
  final String? resultLabel;

  String get carouselLabel {
    final vs = opponent.isEmpty ? 'Match' : opponent;
    final d = dateLabel.isEmpty ? '' : ' · $dateLabel';
    return '$vs$d';
  }
}

// ─── UI pieces ───────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Text(
      text,
      style: TextStyle(
        color: OdinColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _StickySaveBar extends StatelessWidget {
  const _StickySaveBar({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: OdinColors.canvas2,
        border: Border(
          top: BorderSide(color: OdinColors.panelBorder),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: saving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: OdinColors.accent,
            foregroundColor: OdinColors.textPrimary,
            disabledBackgroundColor:
                OdinColors.accent.withValues(alpha: 0.45),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            saving ? 'Sauvegarde…' : 'Sauvegarder',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCarousel extends StatelessWidget {
  const _MatchCarousel({
    required this.index,
    required this.total,
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final int index;
  final int total;
  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: OdinColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OdinColors.panelBorder),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            icon: Icon(
              Icons.chevron_left,
              color: onPrev == null
                  ? OdinColors.panelBorder.withValues(alpha: 1.5)
                  : OdinColors.accent,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OdinColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${index + 1} / $total',
                  style: TextStyle(
                    color: OdinColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right,
              color: onNext == null
                  ? OdinColors.panelBorder.withValues(alpha: 1.5)
                  : OdinColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({
    required this.club,
    required this.match,
    required this.resultColor,
  });

  final String club;
  final _MatchItem match;
  final Color resultColor;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OdinColors.inputFill,
          border: Border(
            left: BorderSide(color: resultColor, width: 3),
            top: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
            right: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
            bottom: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          children: [
            Text(
              '$club  vs  ${match.opponent}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: OdinColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (match.competition.isNotEmpty)
                  _MetaChip(match.competition, const Color(0xFF22D3EE)),
                if (match.dateLabel.isNotEmpty)
                  _MetaChip(match.dateLabel, OdinColors.textSecondary),
                if (match.homeAwayLabel.isNotEmpty)
                  _MetaChip(match.homeAwayLabel, const Color(0xFF8B5CF6)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  match.score?.isNotEmpty == true ? match.score! : '— : —',
                  style: const TextStyle(
                    color: OdinColors.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                if (match.resultLabel?.isNotEmpty == true) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: resultColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match.resultLabel!,
                      style: TextStyle(
                        color: resultColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.goals,
    required this.shots,
    required this.possession,
    required this.corners,
    required this.yellow,
    required this.red,
    required this.onGoals,
    required this.onShots,
    required this.onPossession,
    required this.onCorners,
    required this.onYellow,
    required this.onRed,
  });

  final int goals;
  final int shots;
  final int possession;
  final int corners;
  final int yellow;
  final int red;
  final ValueChanged<int> onGoals;
  final ValueChanged<int> onShots;
  final ValueChanged<int> onPossession;
  final ValueChanged<int> onCorners;
  final ValueChanged<int> onYellow;
  final ValueChanged<int> onRed;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final stats = <(String, int, int, Color, ValueChanged<int>)>[
      ('Buts', goals, 99, const Color(0xFF22C55E), onGoals),
      ('Tirs cadrés', shots, 99, const Color(0xFF22D3EE), onShots),
      ('Possession %', possession, 100, OdinColors.accent, onPossession),
      ('Corners', corners, 99, const Color(0xFF8B5CF6), onCorners),
      ('Jaunes', yellow, 99, const Color(0xFFF59E0B), onYellow),
      ('Rouges', red, 99, const Color(0xFFEF4444), onRed),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final s in stats)
              SizedBox(
                width: w,
                child: _StatStepperTile(
                  label: s.$1,
                  value: s.$2,
                  max: s.$3,
                  color: s.$4,
                  onChanged: s.$5,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatStepperTile extends StatelessWidget {
  const _StatStepperTile({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  void _bump(int delta) {
    onChanged((value + delta).clamp(0, max));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: OdinColors.inputFill,
          border: Border(
            left: BorderSide(color: color, width: 3),
            top: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
            right: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
            bottom: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: OdinColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StepBtn(
                  icon: Icons.remove,
                  enabled: value > 0,
                  color: color,
                  onTap: () => _bump(-1),
                ),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StepBtn(
                  icon: Icons.add,
                  enabled: value < max,
                  color: color,
                  onTap: () => _bump(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled
                ? color.withValues(alpha: 0.18)
                : OdinColors.inputFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? color : OdinColors.textMuted.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _TeamRatingCard extends StatelessWidget {
  const _TeamRatingCard({
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        decoration: BoxDecoration(
          color: OdinColors.inputFill,
          border: Border(
            left: const BorderSide(color: OdinColors.accent, width: 3),
            top: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
            right: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
            bottom: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: OdinColors.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ' /10',
                  style: TextStyle(color: OdinColors.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                _StarRow(rating: rating),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: OdinColors.accent,
                thumbColor: OdinColors.accent,
                inactiveTrackColor: OdinColors.textMuted.withValues(alpha: 0.35),
                trackHeight: 3,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                min: 1,
                max: 10,
                divisions: 18,
                value: rating.clamp(1, 10),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final threshold = (i + 1) * 2.0;
        final IconData icon;
        if (rating >= threshold) {
          icon = Icons.star_rounded;
        } else if (rating >= threshold - 1) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: 16, color: OdinColors.accent);
      }),
    );
  }
}

class _PlayerNoteRow extends StatelessWidget {
  const _PlayerNoteRow({
    required this.player,
    required this.rating,
    required this.commentCtrl,
    required this.onRating,
  });

  final CoachPlayer player;
  final int rating;
  final TextEditingController commentCtrl;
  final ValueChanged<int> onRating;

  Color get _color {
    if (rating >= 8) return const Color(0xFF22C55E);
    if (rating >= 6) return OdinColors.accent;
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final color = _color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: OdinColors.glassPanel,
          border: Border(
            left: BorderSide(color: color, width: 3),
            top: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
            right: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
            bottom: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    player.initials,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        player.position,
                        style: TextStyle(
                          color: OdinColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$rating/10',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (i) {
                final n = i + 1;
                final selected = rating == n;
                return GestureDetector(
                  onTap: () => onRating(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? color
                          : OdinColors.panelBorder.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected
                            ? color
                            : OdinColors.panelBorder,
                      ),
                    ),
                    child: Text(
                      '$n',
                      style: TextStyle(
                        color: selected
                            ? OdinColors.textPrimary
                            : OdinColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              style: TextStyle(color: OdinColors.textPrimary, fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Commentaire (optionnel)',
                hintStyle: TextStyle(
                  color: OdinColors.textMuted.withValues(alpha: 0.45),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: OdinColors.panelBorder.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
