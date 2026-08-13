import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/coach_provider.dart';
import '../../providers/medecin_provider.dart';
import '../../services/responsable_api.dart';

class CoachNotificationsScreen extends StatelessWidget {
  const CoachNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<CoachProvider>();
    return _ClubNotifList(
      items: data.notifications,
      loading: data.loading,
      onRefresh: () => data.refreshNotifications(),
      onMarkAll: data.markAllRead,
    );
  }
}

class MedecinNotificationsScreen extends StatelessWidget {
  const MedecinNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MedecinProvider>();
    return _ClubNotifList(
      items: data.notifications,
      loading: data.loading,
      onRefresh: () => data.refreshNotifications(),
      onMarkAll: data.markAllRead,
    );
  }
}

class _ClubNotifList extends StatelessWidget {
  const _ClubNotifList({
    required this.items,
    required this.loading,
    required this.onRefresh,
    required this.onMarkAll,
  });

  final List<ClubNotificationItem> items;
  final bool loading;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onMarkAll;

  @override
  Widget build(BuildContext context) {
    return OdinBackdrop(
      child: RefreshIndicator(
        color: OdinColors.accent,
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ),
                TextButton(onPressed: onMarkAll, child: const Text('Tout lu')),
              ],
            ),
            const SizedBox(height: 12),
            if (loading && items.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (items.isEmpty)
              GlassCard(child: Text('Aucune notification.', style: TextStyle(color: OdinColors.textMuted)))
            else
              ...items.map(
                (n) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w900)),
                        if (n.body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(n.body, style: TextStyle(color: OdinColors.textMuted, fontSize: 13)),
                        ],
                        if (n.date.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(n.date, style: TextStyle(color: OdinColors.textMuted, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
