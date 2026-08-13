import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/coach_models.dart';
import '../../providers/coach_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/theme_provider.dart';

/// Statuts cyclables (tap badge) — Exemption médicale est verrouillée.
const _clickableCycle = [
  'Présent',
  'Retard',
  'Absent',
  'Sélection nationale',
  'Congé autorisé',
];

class CoachPresencesScreen extends StatefulWidget {
  const CoachPresencesScreen({super.key});

  @override
  State<CoachPresencesScreen> createState() => _CoachPresencesScreenState();
}

class _CoachPresencesScreenState extends State<CoachPresencesScreen> {
  static const _accent = OdinColors.accent;

  String? _sessionId;
  Map<String, String> _att = {};
  String _sessionStatus = 'planned'; // planned | inprogress | done (visuel)
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prov = context.read<CoachProvider>();
      await prov.loadAll();
      if (!mounted) return;
      _initSession(prov);
    });
  }

  void _initSession(CoachProvider prov) {
    final list = prov.trainings.take(5).toList();
    if (list.isEmpty) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todaySession = list.where((s) => s.dateKey == today).toList();
    final selected = todaySession.isNotEmpty ? todaySession.first : list.first;
    _applySession(prov, selected.id);
  }

  void _applySession(CoachProvider prov, String id) {
    final saved = prov.attendanceFor(id);
    final next = <String, String>{};
    for (final p in prov.players) {
      final locked = prov.needsMedicalExemption(p);
      if (locked) {
        next[p.id] = 'Exemption médicale';
        continue;
      }
      final prev = saved[p.id];
      // Ignore stale saved "Exemption médicale" for available players
      if (prev != null && prev != 'Exemption médicale') {
        next[p.id] = prev;
      } else {
        next[p.id] = 'Présent';
      }
    }
    setState(() {
      _sessionId = id;
      _att = next;
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Présent':
        return const Color(0xFF22C55E);
      case 'Retard':
        return const Color(0xFFF59E0B);
      case 'Absent':
        return const Color(0xFFEF4444);
      case 'Exemption médicale':
        return const Color(0xFF3B82F6);
      case 'Sélection nationale':
        return const Color(0xFF8B5CF6);
      case 'Congé autorisé':
        return const Color(0xFF06B6D4);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _showMedicalLockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exemption médicale (blessé / limité) — non modifiable'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  /// Tap badge → cycle Présent → Retard → Absent → Sélection nationale → Congé autorisé
  void _cycle(String playerId, {required bool locked}) {
    if (locked) {
      _showMedicalLockedSnack();
      return;
    }
    final cur = _att[playerId] ?? 'Présent';
    if (cur == 'Exemption médicale') return;
    final idx = _clickableCycle.indexOf(cur);
    final next =
        _clickableCycle[(idx < 0 ? 0 : idx + 1) % _clickableCycle.length];
    setState(() => _att[playerId] = next);
  }

  /// Long-press → bottom sheet picker (mêmes statuts)
  Future<void> _pickStatus(CoachPlayer player, {required bool locked}) async {
    if (locked) {
      _showMedicalLockedSnack();
      return;
    }
    final current = _att[player.id] ?? 'Présent';
    final chosen = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: OdinColors.panelSolid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: OdinColors.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Statut — ${player.fullName}',
                  style: TextStyle(
                    color: OdinColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Appui long pour choisir · tap badge pour cycler',
                  style: TextStyle(
                    color: OdinColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                for (final s in _clickableCycle)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      s == current
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _statusColor(s),
                    ),
                    title: Text(
                      s,
                      style: TextStyle(
                        color: _statusColor(s),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, s),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (chosen != null && mounted) {
      setState(() => _att[player.id] = chosen);
    }
  }

  int get _present => _att.values.where((v) => v == 'Présent').length;
  int get _late => _att.values.where((v) => v == 'Retard').length;
  int get _absent => _att.values.where((v) => v == 'Absent').length;
  int get _medical =>
      _att.values.where((v) => v == 'Exemption médicale').length;
  int get _rate {
    final total = _att.length;
    if (total == 0) return 0;
    return (((_present + _late) / total) * 100).round();
  }

  Color get _rateColor => _rate >= 90
      ? const Color(0xFF22C55E)
      : _rate >= 75
          ? const Color(0xFFF59E0B)
          : const Color(0xFFEF4444);

  Future<void> _save(CoachProvider prov) async {
    if (_sessionId == null) return;
    final session = () {
      for (final s in prov.trainings) {
        if (s.id == _sessionId) return s;
      }
      return null;
    }();
    setState(() => _saving = true);
    await prov.saveAttendanceSheet(
      sessionId: _sessionId!,
      sessionTitle: session?.title ?? 'Séance',
      date: session?.dateKey ?? '',
      rate: _rate,
      records: _att,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Présences sauvegardées'),
        backgroundColor: Color(0xFF22C55E),
      ),
    );
  }

  String get _sessionStatusLabel {
    switch (_sessionStatus) {
      case 'inprogress':
        return 'En cours';
      case 'done':
        return 'Terminée';
      default:
        return 'Planifiée';
    }
  }

  Color get _sessionStatusColor {
    switch (_sessionStatus) {
      case 'inprogress':
        return _accent;
      case 'done':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final prov = context.watch<CoachProvider>();
    final sessions = prov.trainings.take(5).toList();
    final selected = () {
      for (final s in sessions) {
        if (s.id == _sessionId) return s;
      }
      return null;
    }();

    return OdinBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.fabLift(context)),
        child: FloatingActionButton.extended(
          backgroundColor: OdinColors.accent,
          onPressed: _saving || _sessionId == null ? null : () => _save(prov),
          label: Text(_saving ? '...' : 'Sauvegarder', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : sessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucune séance — créez-en une dans Planning des Séances',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: OdinColors.textSecondary),
                    ),
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.bottomNav + 56),
                  children: [
                    // Planifiée / En cours / Terminée (visuel uniquement)
                    Row(
                      children: [
                        _StatusChip(
                          label: 'Planifiée',
                          active: _sessionStatus == 'planned',
                          color: const Color(0xFF3B82F6),
                          onTap: () =>
                              setState(() => _sessionStatus = 'planned'),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: 'En cours',
                          active: _sessionStatus == 'inprogress',
                          color: _accent,
                          onTap: () =>
                              setState(() => _sessionStatus = 'inprogress'),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: 'Terminée',
                          active: _sessionStatus == 'done',
                          color: const Color(0xFF22C55E),
                          onTap: () => setState(() => _sessionStatus = 'done'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const ScoutSectionLabel('Séance d\'entraînement'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 68,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: sessions.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final s = sessions[i];
                          final active = s.id == _sessionId;
                          return GestureDetector(
                            onTap: () => _applySession(prov, s.id),
                            child: Container(
                              width: 196,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? _accent.withValues(alpha: 0.14)
                                    : OdinColors.inputFill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? _accent.withValues(alpha: 0.5)
                                      : OdinColors.panelBorder,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          active ? _accent : OdinColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      s.dateKey,
                                      if (s.eventTime.isNotEmpty) s.eventTime,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          OdinColors.textSecondary.withValues(alpha: 0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 16),
                      // Hero card séance sélectionnée
                      GlassCard(
                        raised: true,
                        accentColor: _accent,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: _accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selected.title,
                                    style: TextStyle(
                                      color: OdinColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (selected.eventTime.isNotEmpty)
                                        selected.eventTime,
                                      if (selected.location.isNotEmpty)
                                        selected.location,
                                      '${prov.players.length} joueurs',
                                    ].join(' · '),
                                    style: TextStyle(
                                      color:
                                          OdinColors.textSecondary.withValues(alpha: 0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _sessionStatusColor
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _sessionStatusLabel,
                                style: TextStyle(
                                  color: _sessionStatusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    // 6 KPIs — grille 2×3
                    _KpiGrid(
                      items: [
                        _KpiItem(
                          'Total',
                          '${_att.length}',
                          _accent,
                        ),
                        _KpiItem(
                          'Présents',
                          '$_present',
                          const Color(0xFF22C55E),
                        ),
                        _KpiItem(
                          'Retards',
                          '$_late',
                          const Color(0xFFF59E0B),
                        ),
                        _KpiItem(
                          'Absents',
                          '$_absent',
                          const Color(0xFFEF4444),
                        ),
                        _KpiItem(
                          'Médicaux',
                          '$_medical',
                          const Color(0xFF3B82F6),
                        ),
                        _KpiItem('% Présence', '$_rate%', _rateColor),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const ScoutSectionLabel('Liste des joueurs'),
                    const SizedBox(height: 6),
                    Text(
                      'Tap badge = cycler · Appui long = choisir',
                      style: TextStyle(
                        color: OdinColors.textMuted.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...prov.players.asMap().entries.map((e) {
                      final p = e.value;
                      final st = _att[p.id] ?? 'Présent';
                      final c = _statusColor(st);
                      final locked = prov.needsMedicalExemption(p);
                      return _PlayerRow(
                        player: p,
                        status: st,
                        color: c,
                        locked: locked,
                        onBadgeTap: () => _cycle(p.id, locked: locked),
                        onLongPress: () =>
                            _pickStatus(p, locked: locked),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: e.key * 30),
                          );
                    }),
                    if (prov.attendanceHistory.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const ScoutSectionLabel('Historique'),
                      const SizedBox(height: 12),
                      ...prov.attendanceHistory.take(8).map((h) {
                        final rate = (h['rate'] as num?)?.toInt() ?? 0;
                        final rc = rate >= 90
                            ? const Color(0xFF22C55E)
                            : rate >= 75
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            accentColor: rc,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${h['sessionTitle'] ?? 'Séance'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: OdinColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if ((h['date'] as String?)?.isNotEmpty ==
                                          true)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '${h['date']}',
                                            style: TextStyle(
                                              color: OdinColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$rate%',
                                  style: TextStyle(
                                    color: rc,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
    ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.18)
                : OdinColors.inputFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? color.withValues(alpha: 0.5)
                  : OdinColors.panelBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : OdinColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiItem {
  const _KpiItem(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.items});
  final List<_KpiItem> items;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    // 2 lignes × 3 colonnes
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: 10),
                Expanded(child: _KpiTile(items[row * 3 + col])),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile(this.item);
  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return GlassCard(
      raised: true,
      accentColor: item.color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.status,
    required this.color,
    required this.locked,
    required this.onBadgeTap,
    required this.onLongPress,
  });
  final CoachPlayer player;
  final String status;
  final Color color;
  final bool locked;
  final VoidCallback onBadgeTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GlassCard(
          accentColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    player.initials,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locked
                            ? '${player.position} · Auto médical'
                            : '${player.position} · tap badge pour cycler',
                        style: TextStyle(
                          color: OdinColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Grand badge coloré — tap = cycle
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBadgeTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (locked)
                            Icon(Icons.lock, size: 14, color: color)
                          else
                            Icon(Icons.sync, size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
