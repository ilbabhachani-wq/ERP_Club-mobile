import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/medecin_provider.dart';
import '../../models/medecin_models.dart';
import '../../core/theme/odin_colors.dart';

class MedecinRendezVousScreen extends StatefulWidget {
  const MedecinRendezVousScreen({super.key});

  @override
  State<MedecinRendezVousScreen> createState() =>
    _MedecinRendezVousScreenState();
}

class _MedecinRendezVousScreenState
  extends State<MedecinRendezVousScreen> {

  String _filter = 'Tous';
  static const _filters = [
    'Tous', 'Aujourd\'hui', 'À venir', 'Passés'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedecinProvider>().loadAll();
    });
  }

  bool _isToday(MedecinEvent e) {
    final now = DateTime.now();
    return _parseDate(e.eventDate)?.year == now.year
      && _parseDate(e.eventDate)?.month == now.month
      && _parseDate(e.eventDate)?.day == now.day;
  }

  bool _isFuture(MedecinEvent e) {
    final d = _parseDate(e.eventDate);
    if (d == null) return false;
    final now = DateTime.now();
    return d.isAfter(
      DateTime(now.year, now.month, now.day)
    );
  }

  bool _isPast(MedecinEvent e) {
    final d = _parseDate(e.eventDate);
    if (d == null) return false;
    final now = DateTime.now();
    return d.isBefore(
      DateTime(now.year, now.month, now.day)
    );
  }

  DateTime? _parseDate(String s) {
    try {
      if (s.contains('/')) {
        final p = s.split('/');
        if (p.length >= 3) {
          return DateTime(
            int.parse(p[2].split(' ')[0]),
            int.parse(p[1]),
            int.parse(p[0]),
          );
        }
      }
      return DateTime.parse(s.split('T')[0]);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(String s) {
    final d = _parseDate(s);
    if (d == null) return s;
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr',
      'Mai', 'Jun', 'Jul', 'Aoû',
      'Sep', 'Oct', 'Nov', 'Déc',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MedecinProvider>();

    final medicalEvents = prov.allEvents.where((e) {
      final t = e.eventType.toUpperCase();
      return t.contains('MEDICAL') ||
        t.contains('SOIN') ||
        t.contains('RDV') ||
        t.contains('REND') ||
        t.isEmpty; // include all if no type filter
    }).toList();

    final filtered = medicalEvents.where((e) {
      if (_filter == 'Aujourd\'hui') {
        return _isToday(e);
      }
      if (_filter == 'À venir') {
        return _isFuture(e) && !_isToday(e);
      }
      if (_filter == 'Passés') {
        return _isPast(e);
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final da = _parseDate(a.eventDate);
        final db = _parseDate(b.eventDate);
        if (da == null || db == null) return 0;
        return da.compareTo(db);
      });

    final todayCount = medicalEvents
      .where(_isToday).length;
    final upcomingCount = medicalEvents
      .where((e) => _isFuture(e) && !_isToday(e))
      .length;

    return Scaffold(
      backgroundColor: OdinColors.canvas,
      appBar: AppBar(
        backgroundColor: OdinColors.canvas2,
        elevation: 0,
        title: Text(
          'Rendez-vous',
          style: TextStyle(
            color: OdinColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () =>
              _showAddEventSheet(context, prov),
            icon: const Icon(
              Icons.add,
              color: Color(0xFFFF7A00),
            ),
          ),
        ],
      ),
      body: prov.loading
        ? const _LoadingWidget()
        : prov.error != null
        ? _ErrorWidget(
            error: prov.error!,
            onRetry: prov.loadAll,
          )
        : CustomScrollView(
            slivers: [

              // KPIs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _KpiCard(
                        label: "Aujourd'hui",
                        value: '$todayCount',
                        color: const Color(0xFFFF7A00),
                        icon: Icons.today,
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        label: 'À venir',
                        value: '$upcomingCount',
                        color: const Color(0xFF3B82F6),
                        icon: Icons.upcoming,
                      ),
                      const SizedBox(width: 8),
                      _KpiCard(
                        label: 'Total',
                        value:
                          '${medicalEvents.length}',
                        color: const Color(0xFF8B5CF6),
                        icon: Icons.calendar_month,
                      ),
                    ],
                  ).animate().fadeIn(),
                ),
              ),

              // Filter pills
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                      const EdgeInsets.symmetric(
                        horizontal: 12
                      ),
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) =>
                      const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(
                          () => _filter = f
                        ),
                        child: Container(
                          padding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          decoration: BoxDecoration(
                            color: active
                              ? const Color(
                                  0xFFFF7A00
                                )
                              : OdinColors.panelBorder.withValues(alpha: 0.5),
                            borderRadius:
                              BorderRadius.circular(
                                99
                              ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: active
                                ? OdinColors.textPrimary
                                : OdinColors.textSecondary.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 12)
              ),

              // Events list
              filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize:
                          MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                              .calendar_today_outlined,
                            color: OdinColors.textMuted,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'Tous'
                              ? 'Aucun rendez-vous'
                              : 'Aucun rendez-vous '
                                '${_filter.toLowerCase()}',
                            style: TextStyle(
                              color: OdinColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () =>
                              _showAddEventSheet(
                                context, prov
                              ),
                            child: Container(
                              padding:
                                const EdgeInsets
                                  .symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              decoration:
                                BoxDecoration(
                                color: const Color(
                                  0xFFFF7A00
                                ).withValues(
                                  alpha: 0.12
                                ),
                                borderRadius:
                                  BorderRadius
                                    .circular(99),
                                border: Border.all(
                                  color: const Color(
                                    0xFFFF7A00
                                  ).withValues(
                                    alpha: 0.30
                                  ),
                                ),
                              ),
                              child: const Text(
                                '+ Ajouter un RDV',
                                style: TextStyle(
                                  color: Color(
                                    0xFFFF7A00
                                  ),
                                  fontSize: 12,
                                  fontWeight:
                                    FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate:
                      SliverChildBuilderDelegate(
                      (_, i) {
                        final e = filtered[i];
                        final isToday = _isToday(e);
                        final isPast = _isPast(e);
                        return Padding(
                          padding:
                            const EdgeInsets.fromLTRB(
                              12, 0, 12, 6
                            ),
                          child: _EventCard(
                            event: e,
                            isToday: isToday,
                            isPast: isPast,
                            formattedDate:
                              _formatDate(
                                e.eventDate
                              ),
                          ),
                        ).animate().fadeIn(
                          delay: Duration(
                            milliseconds: i * 60
                          )
                        ).slideY(
                          begin: 0.05, end: 0
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 32)
              ),
            ],
          ),
    );
  }

  void _showAddEventSheet(
    BuildContext context,
    MedecinProvider prov,
  ) {
    final titleCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Fermer',
      barrierColor: Colors.black.withValues(alpha: 0.70),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim, secondaryAnim) {
        final maxH = MediaQuery.of(ctx).size.height * 0.85;
        return SizedBox.expand(
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Center(
                child: Container(
                  width: 400,
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(ctx).size.width - 40,
                    maxHeight: maxH,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
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
                              'Nouveau rendez-vous',
                              style: TextStyle(
                                color: OdinColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(ctx, rootNavigator: true).pop(),
                            icon: Icon(
                              Icons.close,
                              color: OdinColors.textMuted,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SheetField(
                        label: 'TITRE',
                        controller: titleCtrl,
                        hint: 'Ex: Consultation, IRM...',
                      ),
                      const SizedBox(height: 14),
                      _SheetField(
                        label: 'DATE (JJ/MM/AAAA)',
                        controller: dateCtrl,
                        hint: 'Ex: 20/07/2026',
                        keyboardType: TextInputType.datetime,
                      ),
                      const SizedBox(height: 14),
                      _SheetField(
                        label: 'HEURE',
                        controller: timeCtrl,
                        hint: 'Ex: 09:00',
                        keyboardType: TextInputType.datetime,
                      ),
                      const SizedBox(height: 14),
                      _SheetField(
                        label: 'LIEU',
                        controller: locationCtrl,
                        hint: 'Ex: Cabinet médical...',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleCtrl.text.isEmpty ||
                                dateCtrl.text.isEmpty) {
                              return;
                            }
                            Navigator.of(ctx, rootNavigator: true).pop();
                            final payload = {
                              'title': titleCtrl.text.trim(),
                              'eventDate': dateCtrl.text.trim(),
                              'eventTime': timeCtrl.text.trim(),
                              'location': locationCtrl.text.trim(),
                              'eventType': 'MEDICAL',
                            };
                            try {
                              await prov.addEvent(payload);
                            } catch (e) {
                              if (e.toString().contains('403') ||
                                  e.toString().contains('Permission')) {
                                prov.addLocalEvent({
                                  'id': DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  ...payload,
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A00),
                            foregroundColor: OdinColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Créer le rendez-vous',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}

// ─── Event Card ───────────────────────────────────

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isToday,
    required this.isPast,
    required this.formattedDate,
  });

  final MedecinEvent event;
  final bool isToday;
  final bool isPast;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final Color c = isToday
        ? const Color(0xFFFF7A00)
        : isPast
            ? const Color(0xFF6B7280)
            : const Color(0xFF3B82F6);

    final subtitleParts = <String>[
      if (event.eventTime.isNotEmpty) event.eventTime,
      if (event.location.isNotEmpty) event.location,
    ];
    final subtitle = subtitleParts.isEmpty
        ? formattedDate
        : subtitleParts.join(' · ');

    final badgeLabel = isToday
        ? "Aujourd'hui"
        : isPast
            ? 'Passé'
            : null;

    return SizedBox(
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8,
          ),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.06),
            border: Border(
              left: BorderSide(color: c, width: 3),
              top: BorderSide(color: c.withValues(alpha: 0.15)),
              right: BorderSide(color: c.withValues(alpha: 0.15)),
              bottom: BorderSide(color: c.withValues(alpha: 0.15)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedDate.split(' ').first,
                      style: TextStyle(
                        color: c,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      formattedDate.split(' ').length > 1
                          ? formattedDate.split(' ')[1]
                          : '',
                      style: TextStyle(
                        color: c.withValues(alpha: 0.80),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: OdinColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: OdinColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: c,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
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

// ─── Small Widgets ────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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
  Widget build(BuildContext context) =>
    Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border(
            left: BorderSide(color: color, width: 3),
            top: BorderSide(
              color: color.withValues(alpha: 0.20)
            ),
            right: BorderSide(
              color: color.withValues(alpha: 0.20)
            ),
            bottom: BorderSide(
              color: color.withValues(alpha: 0.20)
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: OdinColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 8,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      ),
    );
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: OdinColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: OdinColors.textPrimary, fontSize: 13
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: OdinColors.textMuted.withValues(alpha: 0.5),
              fontSize: 13,
            ),
            filled: true,
            fillColor: OdinColors.panelBorder.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12
              ),
          ),
        ),
      ],
    );
}

// ─── Loading / Error ─────────────────────────────

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();
  @override
  Widget build(BuildContext context) =>
    Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFF7A00), strokeWidth: 2
          ),
          SizedBox(height: 12),
          Text(
            'Chargement des rendez-vous...',
            style: TextStyle(
              color: OdinColors.textSecondary, fontSize: 13
            ),
          ),
        ],
      ),
    );
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
    Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFEF4444), size: 40
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(
              color: OdinColors.textSecondary, fontSize: 13
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Réessayer',
              style: TextStyle(
                color: Color(0xFFFF7A00)
              ),
            ),
          ),
        ],
      ),
    );
}
