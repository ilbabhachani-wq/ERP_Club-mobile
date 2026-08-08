import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/preparateur_provider.dart';

class PrepNotificationsScreen extends StatefulWidget {
  const PrepNotificationsScreen({super.key});

  @override
  State<PrepNotificationsScreen> createState() => _PrepNotificationsScreenState();
}

class _PrepNotificationsScreenState extends State<PrepNotificationsScreen> {
  String _filter = 'Toutes';

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'haute':
        return AppColors.danger;
      case 'moyenne':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  IconData _typeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('bless')) return Icons.healing_rounded;
    if (t.contains('fatigue') || t.contains('charge')) return Icons.bolt_rounded;
    if (t.contains('program')) return Icons.fitness_center_rounded;
    if (t.contains('recup') || t.contains('récup')) return Icons.spa_rounded;
    if (t.contains('wellness')) return Icons.favorite_rounded;
    return Icons.notifications_rounded;
  }

  String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PreparateurDataProvider>();
    final all = data.notifications;
    final filtered = _filter == 'Toutes'
        ? all
        : _filter == 'Non lues'
            ? all.where((n) => !n.isRead).toList()
            : all.where((n) => n.type.toLowerCase().contains(_filter.toLowerCase())).toList();
    final unread = data.unreadNotifications;

    if (data.loading && all.isEmpty) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: const Color(0xFF6366F1),
        backgroundColor: AppColors.card,
        onRefresh: () => data.refreshNotifications(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(
              Row(
                children: [
                  const Expanded(child: ScoutSectionLabel('Notifications')),
                  if (unread > 0)
                    TextButton.icon(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        await data.markAllNotificationsRead();
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: Text('Tout lire ($unread)'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ScoutKpiCard(
                    label: 'Total',
                    value: '${all.length}',
                    icon: Icons.notifications_rounded,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Non lues',
                    value: '$unread',
                    icon: Icons.mark_email_unread_rounded,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in ['Toutes', 'Non lues', 'blessure', 'fatigue', 'programme', 'recuperation', 'wellness'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f[0].toUpperCase() + f.substring(1)),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              SaasEmptyState(
                title: 'Aucune notification',
                subtitle: 'Les alertes charge / blessure / programmes apparaîtront ici',
                icon: Icons.notifications_none_rounded,
                onAction: () => data.refreshNotifications(),
              )
            else
              ...filtered.asMap().entries.map((e) {
                final n = e.value;
                final color = _priorityColor(n.priority);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OdinAnimations.fadeUp(
                    GlassCard(
                      raised: !n.isRead,
                      accentColor: color,
                      onTap: n.isRead
                          ? null
                          : () async {
                              await data.markNotificationRead(n.id);
                            },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_typeIcon(n.type), color: color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: TextStyle(
                                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w900,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => data.deleteNotification(n.id),
                                      icon: Icon(Icons.close_rounded, size: 16, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                                if (n.body.isNotEmpty)
                                  Text(n.body, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                const SizedBox(height: 8),
                                Text(
                                  [
                                    n.type,
                                    if (n.playerName != null && n.playerName!.isNotEmpty) n.playerName!,
                                    _fmtDate(n.createdAt),
                                  ].where((s) => s.isNotEmpty).join(' · '),
                                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    index: e.key,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
