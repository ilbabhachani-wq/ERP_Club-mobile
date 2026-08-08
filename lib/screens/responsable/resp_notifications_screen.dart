import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/responsable_provider.dart';
import '../../services/responsable_api.dart';

class RespNotificationsScreen extends StatefulWidget {
  const RespNotificationsScreen({super.key});

  @override
  State<RespNotificationsScreen> createState() => _RespNotificationsScreenState();
}

class _RespNotificationsScreenState extends State<RespNotificationsScreen> {
  String _filter = 'Toutes';

  Color _levelColor(ClubNotificationItem n) {
    final level = (n.level ?? n.type).toLowerCase();
    if (level.contains('crit') || level.contains('danger')) return AppColors.danger;
    if (level.contains('warn') || level.contains('alerte')) return AppColors.warning;
    if (level.contains('succ')) return AppColors.success;
    return AppColors.info;
  }

  IconData _typeIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('contrat')) return Icons.description_outlined;
    if (t.contains('finance') || t.contains('budget')) return Icons.account_balance_wallet_outlined;
    if (t.contains('médical') || t.contains('medical')) return Icons.medical_services_outlined;
    if (t.contains('valid')) return Icons.fact_check_outlined;
    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ResponsableDataProvider>();
    final all = data.notifications;
    final filtered = _filter == 'Toutes'
        ? all
        : all.where((n) => n.type.toLowerCase().contains(_filter.toLowerCase())).toList();
    final unread = all.where((n) => !n.read).length;

    if (data.loading && all.isEmpty) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.success,
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
                        await data.markAllRead();
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: Text('Tout lire ($unread)'),
                    ),
                  IconButton(
                    tooltip: 'Supprimer lues',
                    onPressed: () async {
                      await data.clearRead();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notifications lues supprimées')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_sweep_outlined),
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
                  for (final f in ['Toutes', 'Contrat', 'Finance', 'Médical', 'Système', 'Validation', 'Info'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              const SaasEmptyState(
                title: 'Aucune notification',
                subtitle: 'Votre boîte de notifications est vide',
                icon: Icons.notifications_none_rounded,
              )
            else
              ...filtered.asMap().entries.map((e) {
                final n = e.value;
                final color = _levelColor(n);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OdinAnimations.fadeUp(
                    GlassCard(
                      raised: !n.read,
                      accentColor: color,
                      onTap: n.read
                          ? null
                          : () async {
                              await data.markRead([n.id]);
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
                                          fontWeight: n.read ? FontWeight.w600 : FontWeight.w900,
                                          color: AppColors.text,
                                        ),
                                      ),
                                    ),
                                    if (!n.read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                if (n.body.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    n.body,
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  '${n.type}${n.date.isNotEmpty ? ' · ${n.date}' : ''}',
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
