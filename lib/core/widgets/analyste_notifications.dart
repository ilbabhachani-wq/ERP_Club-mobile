import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/odin_colors.dart';

class AnalysteNotification {
  const AnalysteNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    this.route,
    this.unread = true,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  final String? route;
  final bool unread;
}

const kAnalysteNotifications = [
  AnalysteNotification(
    title: 'Fatigue critique',
    body: 'Ahmed Ben Salah — fatigue 95% (75-90′). Remplacement recommandé.',
    time: 'il y a 2 min',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFEF4444),
    route: '/analyste/fatigue',
  ),
  AnalysteNotification(
    title: 'Pattern détecté',
    body: 'Pressing −22% en 2ème mi-temps (confiance 91%).',
    time: 'il y a 18 min',
    icon: Icons.auto_awesome,
    color: Color(0xFFA855F7),
    route: '/analyste/patterns',
  ),
  AnalysteNotification(
    title: 'PPI mis à jour',
    body: '3 joueurs ont changé de rang PPI cette semaine.',
    time: 'il y a 1 h',
    icon: Icons.star_rounded,
    color: Color(0xFFF59E0B),
    route: '/analyste/ppi',
  ),
  AnalysteNotification(
    title: 'Live Match',
    body: 'Simulation disponible — Manchester United vs EST.',
    time: 'il y a 3 h',
    icon: Icons.sensors,
    color: Color(0xFFEF4444),
    route: '/analyste/live',
  ),
  AnalysteNotification(
    title: 'Injury Lab',
    body: 'Risque 7j élevé pour Karim Dridi (58%).',
    time: 'Hier',
    icon: Icons.healing_rounded,
    color: Color(0xFFFF7A00),
    route: '/analyste/blessures',
    unread: false,
  ),
];

Future<void> showAnalysteNotifications(BuildContext context) async {
  HapticFeedback.lightImpact();
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: OdinColors.panelSolid,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      final unread = kAnalysteNotifications.where((n) => n.unread).length;
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: OdinColors.accent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.5,
                child: ListView.separated(
                  itemCount: kAnalysteNotifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = kAnalysteNotifications[i];
                    return Material(
                      color: n.unread
                          ? OdinColors.accent.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(ctx);
                          if (n.route != null && context.mounted) {
                            context.go(n.route!);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: n.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(n.icon, size: 18, color: n.color),
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
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                          ),
                                        ),
                                        if (n.unread)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: OdinColors.accent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.body,
                                      style: const TextStyle(fontSize: 12, color: OdinColors.textSecondary, height: 1.35),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      n.time,
                                      style: const TextStyle(fontSize: 10, color: OdinColors.textMuted, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Cloche app bar avec badge non-lus.
class AnalysteNotificationBell extends StatelessWidget {
  const AnalysteNotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = kAnalysteNotifications.where((n) => n.unread).length;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => showAnalysteNotifications(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, color: OdinColors.textSecondary),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: OdinColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: OdinColors.canvas, width: 1.5),
                ),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
