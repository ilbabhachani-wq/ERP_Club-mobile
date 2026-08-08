import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_notifications.dart';
import '../core/widgets/odin_settings_sheet.dart';
import '../core/widgets/odin_widgets.dart';
import '../providers/app_providers.dart';
import '../providers/responsable_provider.dart';
import '../providers/theme_provider.dart';
import '../router/app_router.dart';

class ResponsableShell extends StatelessWidget {
  const ResponsableShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Rebuild shell when theme/locale flip so OdinColors/AppColors refresh in place.
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final location = GoRouterState.of(context).uri.path;
    final index = responsableShellIndexForLocation(location);
    final auth = context.watch<AuthProvider>();
    final data = context.watch<ResponsableDataProvider>();
    final club = auth.user?.organization?.clubName ?? 'Direction Club';
    const accent = Color(0xFF22C55E);
    final unread = data.notifications.where((n) => !n.read).length;

    // Safety net: if cold-start skipped splash load, fetch once here.
    if (auth.isAuthenticated && !data.bootstrapped && !data.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final user = context.read<AuthProvider>().user;
        context.read<ResponsableDataProvider>().load(orgId: user?.organization?.id);
      });
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: OdinColors.canvas,
      appBar: OdinProAppBar(
        club: club,
        subtitle: 'Responsable · ODIN',
        accentColor: accent,
        showLogo: true,
        logoSize: 58,
        actions: [
          OdinNotificationBell(
            unreadCount: unread,
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
                seeAllRoute: '/responsable/notifications',
                onMarkAllRead: () => data.markAllRead(),
                onTapItem: (item) {
                  if (item.unread) data.markRead([item.id]);
                },
              );
            },
          ),
          OdinSettingsButton(
            roleLabel: 'Espace Responsable',
            links: const [
              OdinSettingsLink(
                label: 'Mon profil',
                subtitle: 'Photo, sécurité',
                route: '/responsable/profil',
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
        onSelected: (i) => goToResponsableShellTab(context, i),
        accentColor: accent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Validation',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Équipes',
          ),
        ],
      ),
    );
  }
}
