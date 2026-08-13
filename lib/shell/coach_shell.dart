import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_notifications.dart';
import '../core/widgets/odin_settings_sheet.dart';
import '../core/widgets/odin_widgets.dart';
import '../providers/app_providers.dart';
import '../providers/coach_provider.dart';
import '../providers/theme_provider.dart';
import '../router/app_router.dart';

class CoachShell extends StatelessWidget {
  const CoachShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final location = GoRouterState.of(context).uri.path;
    final index = coachShellIndexForLocation(location);
    final auth = context.watch<AuthProvider>();
    final data = context.watch<CoachProvider>();
    final club = auth.user?.organization?.clubName ?? 'Espace Coach';
    const accent = OdinColors.accent;

    if (auth.isAuthenticated && !data.bootstrapped && !data.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.read<CoachProvider>().loadAll();
      });
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: OdinColors.canvas,
      appBar: OdinProAppBar(
        club: club,
        subtitle: 'Espace Coach · ODIN',
        accentColor: accent,
        showLogo: true,
        logoSize: 58,
        actions: [
          OdinNotificationBell(
            unreadCount: data.unreadNotifications,
            color: OdinColors.textSecondary,
            onPressed: () {
              final items = data.notifications
                  .map(
                    (n) => OdinNotifItem(
                      id: n.id,
                      title: n.title,
                      body: n.body,
                      time: n.date,
                      unread: !n.read,
                      type: n.type,
                      color: accent,
                    ),
                  )
                  .toList();
              showOdinNotificationsSheet(
                context,
                items: items,
                seeAllRoute: '/coach/notifications',
                onMarkAllRead: () => data.markAllRead(),
                onTapItem: (item) {
                  if (item.unread) data.markRead([item.id]);
                },
              );
            },
          ),
          const OdinSettingsButton(
            roleLabel: 'Espace Coach',
            links: [
              OdinSettingsLink(
                label: 'Mon profil',
                subtitle: 'Photo, sécurité',
                route: '/coach/profil',
                icon: Icons.person_outline_rounded,
              ),
            ],
          ),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey(location),
        child: child,
      ),
      bottomNavigationBar: OdinGlassNavBar(
        selectedIndex: index,
        onSelected: (i) => goToCoachShellTab(context, i),
        accentColor: accent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center_rounded),
            label: 'Séances',
          ),
          NavigationDestination(
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg_rounded),
            label: 'Présences',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Compo',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Analyse',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'IA',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
        ],
      ),
    );
  }
}
