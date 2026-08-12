import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/coach_models.dart';
import '../../providers/coach_provider.dart';
import '../../core/theme/odin_colors.dart';
import '../../providers/theme_provider.dart';

/// Option A — Coach today + slim KPI strip
class CoachEntrainementsScreen extends StatefulWidget {
  const CoachEntrainementsScreen({super.key});

  @override
  State<CoachEntrainementsScreen> createState() =>
      _CoachEntrainementsScreenState();
}

class _CoachEntrainementsScreenState extends State<CoachEntrainementsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _showCreateSession() async {
    final objectiveCtrl = TextEditingController();
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final timeCtrl = TextEditingController(text: '09:00');
    final durationCtrl = TextEditingController(text: '90');
    final locationCtrl = TextEditingController(text: 'Terrain principal');
    final notesCtrl = TextEditingController();
    String type = 'Tactique';
    String intensity = 'Modérée';

    await showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Fermer',
      barrierColor: Colors.black.withValues(alpha: 0.70),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, a1, a2) {
        final prov = context.read<CoachProvider>();
        return SizedBox.expand(
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Center(
                child: StatefulBuilder(
                  builder: (ctx, setSheet) {
                    return Container(
                      width: 400,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(ctx).size.width - 32,
                        maxHeight: MediaQuery.of(ctx).size.height * 0.88,
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.only(
                        left: 18,
                        right: 18,
                        top: 14,
                        bottom: 14 + MediaQuery.of(ctx).viewInsets.bottom,
                      ),
                      decoration: BoxDecoration(
                        color: OdinColors.canvas2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: OdinColors.panelBorder,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Créer une séance',
                                    style: TextStyle(
                                      color: OdinColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(
                                    ctx,
                                    rootNavigator: true,
                                  ).pop(),
                                  icon: Icon(
                                    Icons.close,
                                    color: OdinColors.textMuted,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'TYPE',
                              style: TextStyle(
                                color: OdinColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final t in const [
                                  'Physique',
                                  'Tactique',
                                  'Technique',
                                  'Match',
                                ])
                                  ChoiceChip(
                                    label: Text(t),
                                    selected: type == t,
                                    onSelected: (_) => setSheet(() => type = t),
                                    selectedColor: OdinColors.accent
                                        .withValues(alpha: 0.25),
                                    labelStyle: TextStyle(
                                      color: type == t
                                          ? OdinColors.accent
                                          : OdinColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    backgroundColor:
                                        OdinColors.panelBorder.withValues(alpha: 0.5),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _field('OBJECTIF *', objectiveCtrl, 'Ex: Pressing haut'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _field('DATE *', dateCtrl, 'AAAA-MM-JJ'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _field('HEURE', timeCtrl, '09:00'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _field('DURÉE (min)', durationCtrl, '90'),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'INTENSITÉ',
                                        style: TextStyle(
                                          color: OdinColors.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        initialValue: intensity,
                                        dropdownColor: OdinColors.ink,
                                        style: TextStyle(
                                          color: OdinColors.textPrimary,
                                          fontSize: 13,
                                        ),
                                        decoration: _deco(),
                                        items: const [
                                          'Faible',
                                          'Modérée',
                                          'Élevée',
                                          'Maximale',
                                        ]
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) => setSheet(
                                          () => intensity = v ?? intensity,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _field('LIEU', locationCtrl, 'Terrain principal'),
                            const SizedBox(height: 12),
                            _field('NOTES', notesCtrl, 'Consignes...'),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${prov.disponibles.length} joueurs disponibles',
                                style: const TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(
                                      ctx,
                                      rootNavigator: true,
                                    ).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: OdinColors.textSecondary,
                                      side: BorderSide(
                                        color:
                                            OdinColors.panelBorder.withValues(alpha: 1.5),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text('Annuler'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (objectiveCtrl.text.trim().isEmpty ||
                                          dateCtrl.text.trim().isEmpty) {
                                        return;
                                      }
                                      await prov.addTraining(
                                        title:
                                            '$type — ${objectiveCtrl.text.trim()}',
                                        date: dateCtrl.text.trim(),
                                        time: timeCtrl.text.trim().isEmpty
                                            ? '09:00'
                                            : timeCtrl.text.trim(),
                                        location: locationCtrl.text.trim(),
                                        notes:
                                            'Intensité: $intensity. Durée: ${durationCtrl.text.trim()} min. ${notesCtrl.text.trim()}',
                                      );
                                      if (ctx.mounted) {
                                        Navigator.of(ctx, rootNavigator: true)
                                            .pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: OdinColors.accent,
                                      foregroundColor: OdinColors.textPrimary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text(
                                      'Créer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDetail(CoachSession s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: OdinColors.canvas2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final dispo = context.read<CoachProvider>().disponibles.length;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: OdinColors.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  s.title,
                  style: TextStyle(
                    color: OdinColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _kv('Date', s.dateKey),
                _kv('Heure', s.eventTime.isEmpty ? '—' : s.eventTime),
                _kv('Lieu', s.location.isEmpty ? '—' : s.location),
                _kv('Type', s.eventType),
                if (s.notes != null && s.notes!.isNotEmpty)
                  _kv('Description', s.notes!),
                _kv('Joueurs attendus', '$dispo disponibles'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final prov = context.watch<CoachProvider>();
    final today = prov.todayTraining;
    final upcoming = prov.upcomingTrainings;
    final done = prov.doneTrainings;
    final days = prov.daysToNextMatch;

    return Scaffold(
      backgroundColor: OdinColors.canvas,
      appBar: AppBar(
        backgroundColor: OdinColors.canvas2,
        elevation: 0,
        title: Text(
          'Séances',
          style: TextStyle(
            color: OdinColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showCreateSession,
            icon: const Icon(Icons.add_circle, color: OdinColors.accent, size: 28),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: prov.loading
          ? const Center(
              child: CircularProgressIndicator(color: OdinColors.accent),
            )
          : RefreshIndicator(
              color: OdinColors.accent,
              onRefresh: () => prov.loadAll(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _TodayHero(
                      session: today,
                      onPlan: _showCreateSession,
                      onOpen: today == null ? null : () => _openDetail(today),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SlimKpis(
                      week: '${prov.sessionsThisWeek}',
                      done: '${done.length}',
                      dispo: '${prov.disponibles.length}',
                      match: days != null ? 'J-$days' : '—',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: OdinColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabs,
                        indicator: BoxDecoration(
                          color: OdinColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: OdinColors.accent,
                        unselectedLabelColor: OdinColors.textSecondary,
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: 'À venir (${upcoming.length})'),
                          Tab(text: 'Effectuées (${done.length})'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _SessionList(
                          sessions: upcoming,
                          empty: 'Aucune séance à venir',
                          emptyAction: 'Créer une séance',
                          onEmpty: _showCreateSession,
                          onTap: _openDetail,
                          accent: OdinColors.accent,
                        ),
                        _SessionList(
                          sessions: done,
                          empty: 'Aucune séance effectuée',
                          onTap: _openDetail,
                          accent: const Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController c, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: OdinColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          style: TextStyle(color: OdinColors.textPrimary, fontSize: 13),
          decoration: _deco(hint: hint),
        ),
      ],
    );
  }

  InputDecoration _deco({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: OdinColors.textMuted.withValues(alpha: 0.5),
          fontSize: 12,
        ),
        filled: true,
        fillColor: OdinColors.panelBorder.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                k,
                style: TextStyle(
                  color: OdinColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(color: OdinColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.session,
    required this.onPlan,
    this.onOpen,
  });
  final CoachSession? session;
  final VoidCallback onPlan;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: session == null ? onPlan : onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: session == null
                  ? [
                      OdinColors.inputFill,
                      OdinColors.glassPanel.withValues(alpha: 0.5),
                    ]
                  : [
                      OdinColors.accent.withValues(alpha: 0.22),
                      OdinColors.accent.withValues(alpha: 0.06),
                    ],
            ),
            border: Border.all(
              color: session == null
                  ? OdinColors.panelBorder
                  : OdinColors.accent.withValues(alpha: 0.35),
            ),
          ),
          child: session == null
              ? Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: OdinColors.panelBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_busy,
                        color: OdinColors.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aucune séance aujourd\'hui',
                            style: TextStyle(
                              color: OdinColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Planifier une séance pour aujourd\'hui',
                            style: TextStyle(
                              color: OdinColors.textSecondary.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.add, color: OdinColors.accent),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: OdinColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: OdinColors.accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SÉANCE DU JOUR',
                            style: TextStyle(
                              color: OdinColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session!.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: OdinColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (session!.eventTime.isNotEmpty)
                                session!.eventTime,
                              if (session!.location.isNotEmpty)
                                session!.location,
                            ].join(' · '),
                            style: TextStyle(
                              color: OdinColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: OdinColors.textMuted.withValues(alpha: 0.6),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SlimKpis extends StatelessWidget {
  const _SlimKpis({
    required this.week,
    required this.done,
    required this.dispo,
    required this.match,
  });
  final String week;
  final String done;
  final String dispo;
  final String match;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: OdinColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          _cell('Semaine', week, OdinColors.accent),
          _div(),
          _cell('Faites', done, const Color(0xFF22C55E)),
          _div(),
          _cell('Dispo', dispo, const Color(0xFF3B82F6)),
          _div(),
          _cell('Match', match, const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _div() => Container(
        width: 1,
        height: 28,
        color: OdinColors.panelBorder,
      );

  Widget _cell(String l, String v, Color c) => Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              v,
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            Text(
              l,
              style: TextStyle(
                color: OdinColors.textMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
}

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.sessions,
    required this.empty,
    required this.onTap,
    required this.accent,
    this.emptyAction,
    this.onEmpty,
  });
  final List<CoachSession> sessions;
  final String empty;
  final String? emptyAction;
  final VoidCallback? onEmpty;
  final ValueChanged<CoachSession> onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    if (sessions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 24),
          Text(
            empty,
            textAlign: TextAlign.center,
            style: TextStyle(color: OdinColors.textMuted, fontSize: 14),
          ),
          if (emptyAction != null && onEmpty != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onEmpty,
              child: Text(
                emptyAction!,
                style: const TextStyle(color: OdinColors.accent),
              ),
            ),
          ],
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = sessions[i];
        return GestureDetector(
          onTap: () => onTap(s),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: OdinColors.glassPanel,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: accent, width: 3),
                top: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
                right: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
                bottom: BorderSide(color: OdinColors.panelBorder.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          s.dateKey,
                          if (s.eventTime.isNotEmpty) s.eventTime,
                          if (s.location.isNotEmpty) s.location,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: OdinColors.textMuted.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
      },
    );
  }
}
