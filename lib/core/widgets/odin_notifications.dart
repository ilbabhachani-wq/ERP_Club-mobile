import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/odin_colors.dart';

class OdinNotifItem {
  const OdinNotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.unread = true,
    this.icon = Icons.notifications_rounded,
    this.color = OdinColors.accent,
    this.route,
    this.type,
  });

  final String id;
  final String title;
  final String body;
  final String time;
  final bool unread;
  final IconData icon;
  final Color color;
  final String? route;
  final String? type;
}

typedef OdinNotifAction = Future<void> Function();

Future<void> showOdinNotificationsSheet(
  BuildContext context, {
  required List<OdinNotifItem> items,
  String title = 'Notifications',
  String? seeAllRoute,
  OdinNotifAction? onMarkAllRead,
  void Function(OdinNotifItem item)? onTapItem,
}) async {
  HapticFeedback.lightImpact();
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: OdinColors.panelSolid,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      final unread = items.where((n) => n.unread).length;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: OdinColors.panelBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: OdinColors.textPrimary,
                      ),
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: OdinColors.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unread nouvelles',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: OdinColors.accent,
                        ),
                      ),
                    ),
                  if (onMarkAllRead != null && unread > 0)
                    TextButton(
                      onPressed: () async {
                        await onMarkAllRead();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text('Tout lire'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 40, color: OdinColors.textMuted),
                      const SizedBox(height: 10),
                      Text(
                        'Aucune notification',
                        style: TextStyle(color: OdinColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length.clamp(0, 8),
                    separatorBuilder: (_, __) => Divider(height: 1, color: OdinColors.panelBorder),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: n.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(n.icon, color: n.color, size: 20),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.unread ? FontWeight.w900 : FontWeight.w600,
                            color: OdinColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: OdinColors.textMuted, fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(n.time, style: TextStyle(color: OdinColors.textMuted, fontSize: 10)),
                            if (n.unread) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: n.color, shape: BoxShape.circle),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          onTapItem?.call(n);
                          if (n.route != null && n.route!.isNotEmpty) {
                            context.go(n.route!);
                          }
                        },
                      );
                    },
                  ),
                ),
              if (seeAllRoute != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go(seeAllRoute);
                  },
                  child: const Text('Voir toutes les notifications'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class OdinNotificationBell extends StatelessWidget {
  const OdinNotificationBell({
    super.key,
    required this.unreadCount,
    required this.onPressed,
    this.color,
  });

  final int unreadCount;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? OdinColors.textSecondary;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
        backgroundColor: OdinColors.accent,
        child: Icon(Icons.notifications_outlined, color: c),
      ),
    );
  }
}
