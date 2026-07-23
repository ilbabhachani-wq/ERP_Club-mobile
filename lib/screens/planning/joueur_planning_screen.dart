import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../models/player_models.dart';
import '../../providers/app_providers.dart';

class JoueurPlanningScreen extends StatelessWidget {
  const JoueurPlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<JoueurDataProvider>();
    final locale = context.watch<LocaleProvider>().locale;
    final nextMatch = data.calendarEvents
        .where((e) => e.eventType.toUpperCase() == 'MATCH')
        .firstOrNull;

    if (data.loading && data.calendarEvents.isEmpty && data.playerStats == null) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    return OdinPageScaffold(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (nextMatch != null) ...[
            GlassCard(
              raised: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Prochain Match'),
                  Text(nextMatch.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '${nextMatch.eventDate} ${nextMatch.eventTime ?? ''}',
                    style: const TextStyle(color: OdinColors.textMuted),
                  ),
                  if (nextMatch.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: OdinColors.textMuted),
                        const SizedBox(width: 4),
                        Text(nextMatch.location!, style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  _RollingCountdown(targetDate: _parseDate(nextMatch.eventDate)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _AnimatedLoadCard(
                  icon: Icons.fitness_center,
                  label: 'Charge semaine',
                  percent: (data.playerStats?.trainingLoad ?? 0) / 100,
                  color: OdinColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AnimatedLoadCard(
                  icon: Icons.battery_3_bar,
                  label: 'Fatigue prévue',
                  percent: (data.playerStats?.fatiguePredicted ?? 0) / 100,
                  color: OdinColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle('Calendrier'),
          _SwipeableMonthCalendar(events: data.calendarEvents, locale: locale),
          const SizedBox(height: 20),
          const SectionTitle('Timeline'),
          if (data.calendarEvents.isEmpty)
            GlassCard(
              child: Text(
                'Aucun événement planifié pour le moment.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: OdinColors.textMuted),
              ),
            )
          else
            ...data.calendarEvents.take(8).toList().asMap().entries.map((e) {
              final ev = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OdinAnimations.fadeUp(
                  KeyedSubtree(
                    key: ValueKey('planning-${ev.id}-${e.key}'),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _typeColor(ev.eventType),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ev.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(
                                  '${ev.eventDate} ${ev.eventTime ?? ''}',
                                  style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          _TypeChip(type: ev.eventType),
                        ],
                      ),
                    ),
                  ),
                  index: e.key,
                ),
              );
            }),
        ],
      ),
    );
  }

  static DateTime? _parseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  static Color _typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'MATCH':
        return OdinColors.playerCoral;
      case 'MEDICAL':
        return OdinColors.danger;
      case 'TRAINING':
        return OdinColors.accent;
      default:
        return OdinColors.info;
    }
  }
}

class _RollingCountdown extends StatefulWidget {
  const _RollingCountdown({this.targetDate});
  final DateTime? targetDate;

  @override
  State<_RollingCountdown> createState() => _RollingCountdownState();
}

class _RollingCountdownState extends State<_RollingCountdown> {
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    final target = widget.targetDate;
    if (target != null && mounted) {
      setState(() => _remaining = target.difference(DateTime.now()));
    }
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targetDate == null) return const SizedBox();
    final d = _remaining.inDays;
    final h = _remaining.inHours % 24;
    final m = _remaining.inMinutes % 60;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          RollingDigit(value: '$d', label: 'j'),
          RollingDigit(value: '$h', label: 'h'),
          RollingDigit(value: '$m', label: 'm'),
        ],
      ),
    );
  }
}

class _AnimatedLoadCard extends StatelessWidget {
  const _AnimatedLoadCard({
    required this.icon,
    required this.label,
    required this.percent,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = percent.clamp(0.0, 1.0);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: OdinColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          CountUpInt(
            value: (p * 100).round(),
            suffix: '%',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: p),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearPercentIndicator(
              percent: v,
              lineHeight: 7,
              barRadius: const Radius.circular(4),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              progressColor: color,
              padding: EdgeInsets.zero,
              animation: false,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.12, end: 0);
  }
}

class _SwipeableMonthCalendar extends StatefulWidget {
  const _SwipeableMonthCalendar({required this.events, required this.locale});
  final List<BackendCalendarEvent> events;
  final String locale;

  @override
  State<_SwipeableMonthCalendar> createState() => _SwipeableMonthCalendarState();
}

class _SwipeableMonthCalendarState extends State<_SwipeableMonthCalendar> {
  late final PageController _pageCtrl;
  late DateTime _base;

  @override
  void initState() {
    super.initState();
    _base = DateTime(DateTime.now().year, DateTime.now().month);
    _pageCtrl = PageController(initialPage: 12);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  DateTime _monthFor(int page) => DateTime(_base.year, _base.month + (page - 12));

  String _monthLabel(DateTime date) {
    try {
      return DateFormat.yMMMM(widget.locale).format(date);
    } catch (_) {
      return DateFormat.yMMMM('fr').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 36,
          child: AnimatedBuilder(
            animation: _pageCtrl,
            builder: (_, __) {
              final page = _pageCtrl.hasClients ? (_pageCtrl.page?.round() ?? 12) : 12;
              final month = _monthFor(page);
              return Row(
                children: [
                  IconButton(
                    onPressed: () => _pageCtrl.previousPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    ),
                    icon: const Icon(Icons.chevron_left, color: OdinColors.textMuted),
                  ),
                  Expanded(
                    child: Text(
                      _monthLabel(month),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _pageCtrl.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    ),
                    icon: const Icon(Icons.chevron_right, color: OdinColors.textMuted),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: 25,
            itemBuilder: (_, page) => _MonthGrid(month: _monthFor(page), events: widget.events),
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.events});
  final DateTime month;
  final List<BackendCalendarEvent> events;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final now = DateTime.now();
    final eventDays = events.map((e) {
      try {
        final d = DateTime.parse(e.eventDate);
        if (d.year == month.year && d.month == month.month) return d.day;
      } catch (_) {}
      return -1;
    }).toSet();

    return GlassCard(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: daysInMonth,
        itemBuilder: (_, i) {
          final day = i + 1;
          final hasEvent = eventDays.contains(day);
          final isToday = day == now.day && month.year == now.year && month.month == now.month;
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday
                  ? OdinColors.accent.withValues(alpha: 0.25)
                  : hasEvent
                      ? OdinColors.playerCoral.withValues(alpha: 0.15)
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday ? Border.all(color: OdinColors.accent) : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                fontSize: 12,
                color: hasEvent ? OdinColors.playerCoral : OdinColors.textPrimary,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
