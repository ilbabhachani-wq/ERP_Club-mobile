import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_notifications.dart';
import '../core/widgets/odin_settings_sheet.dart';
import '../core/widgets/odin_widgets.dart';
import '../providers/app_providers.dart';
import '../providers/medecin_provider.dart';
import '../providers/theme_provider.dart';
import '../router/app_router.dart';

class MedecinShell extends StatelessWidget {
  const MedecinShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final location = GoRouterState.of(context).uri.path;
    final index = medecinShellIndexForLocation(location);
    final auth = context.watch<AuthProvider>();
    final data = context.watch<MedecinProvider>();
    final club = auth.user?.organization?.clubName ?? 'Espace Médecin';
    const accent = OdinColors.accent;

    if (auth.isAuthenticated && !data.bootstrapped && !data.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.read<MedecinProvider>().loadAll();
      });
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: OdinColors.canvas,
      appBar: OdinProAppBar(
        club: club,
        subtitle: 'Espace Médecin · ODIN',
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
                seeAllRoute: '/medecin/notifications',
                onMarkAllRead: () => data.markAllRead(),
                onTapItem: (item) {
                  if (item.unread) data.markRead([item.id]);
                },
              );
            },
          ),
          const OdinSettingsButton(
            roleLabel: 'Espace Médecin',
            links: [
              OdinSettingsLink(
                label: 'Mon profil',
                subtitle: 'Photo, sécurité',
                route: '/medecin/profil',
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
        onSelected: (i) => goToMedecinShellTab(context, i),
        accentColor: accent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared_rounded),
            label: 'Dossiers',
          ),
          NavigationDestination(
            icon: Icon(Icons.healing_outlined),
            selectedIcon: Icon(Icons.healing_rounded),
            label: 'Blessures',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services_rounded),
            label: 'Traitements',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'RDV',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'IA',
          ),
        ],
      ),
    );
  }
}
