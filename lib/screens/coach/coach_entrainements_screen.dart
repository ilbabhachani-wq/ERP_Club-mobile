import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/coach_models.dart';
import '../../providers/coach_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_form_sheet.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
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

    try {
      await showOdinFormSheet<void>(
        context: context,
        title: 'Créer une séance',
        builder: (ctx) {
          final prov = context.read<CoachProvider>();
          return StatefulBuilder(
            builder: (ctx, setSheet) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: OdinColors.textSecondary,
                                      side: BorderSide(
                                        color: OdinColors.panelBorder,
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
                                        Navigator.of(ctx).pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: OdinColors.accent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
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
              );
            },
          );
        },
      );
    } finally {
      objectiveCtrl.dispose();
      dateCtrl.dispose();
      timeCtrl.dispose();
      durationCtrl.dispose();
      locationCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  void _openDetail(CoachSession s) {
    final dispo = context.read<CoachProvider>().disponibles.length;
    showOdinFormSheet<void>(
      context: context,
      title: s.title,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Date', s.dateKey),
          _kv('Heure', s.eventTime.isEmpty ? '—' : s.eventTime),
          _kv('Lieu', s.location.isEmpty ? '—' : s.location),
          _kv('Type', s.eventType),
          if (s.notes != null && s.notes!.isNotEmpty) _kv('Description', s.notes!),
          _kv('Joueurs attendus', '$dispo disponibles'),
        ],
      ),
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

    return OdinBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.fabLift(context)),
        child: FloatingActionButton.small(
          backgroundColor: OdinColors.accent,
          onPressed: _showCreateSession,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
      body: prov.loading
          ? const Center(
              child: CircularProgressIndicator(color: OdinColors.accent),
            )
          : RefreshIndicator(
              color: OdinColors.accent,
              onRefresh: () => prov.loadAll(force: true),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: ScoutSectionLabel('Indicateurs'),
                  ),
                  const SizedBox(height: 10),
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
    return GlassCard(
      raised: true,
      accentColor: session == null ? OdinColors.panelBorder : OdinColors.accent,
      onTap: session == null ? onPlan : onOpen,
      padding: const EdgeInsets.all(18),
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
    final tiles = [
      ('Semaine', week, OdinColors.accent, Icons.calendar_view_week_rounded),
      ('Faites', done, const Color(0xFF22C55E), Icons.check_circle_outline_rounded),
      ('Dispo', dispo, const Color(0xFF3B82F6), Icons.groups_rounded),
      ('Match', match, const Color(0xFF8B5CF6), Icons.sports_soccer_rounded),
    ];
    Widget tile((String, String, Color, IconData) t) => Expanded(
          child: SizedBox(
            height: 112,
            child: GlassCard(
              raised: true,
              accentColor: t.$3,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: t.$3.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t.$4, color: t.$3, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    t.$2,
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.$1,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Column(
      children: [
        Row(children: [tile(tiles[0]), const SizedBox(width: 10), tile(tiles[1])]),
        const SizedBox(height: 10),
        Row(children: [tile(tiles[2]), const SizedBox(width: 10), tile(tiles[3])]),
      ],
    );
  }
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, AppSpacing.bottomNav),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = sessions[i];
        return GlassCard(
          onTap: () => onTap(s),
          accentColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
      },
    );
  }
}
