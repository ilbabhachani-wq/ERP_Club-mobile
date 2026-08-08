import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_notifications.dart';
import '../core/widgets/odin_settings_sheet.dart';
import '../core/widgets/odin_widgets.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../providers/scout_provider.dart';
import '../router/app_router.dart';

class ScoutShell extends StatelessWidget {
  const ScoutShell({super.key, required this.child});

  final Widget child;

  List<OdinNotifItem> _scoutNotifs(ScoutDataProvider data) {
    final items = <OdinNotifItem>[];
    for (final m in data.missions.take(3)) {
      items.add(
        OdinNotifItem(
          id: 'mission-${m.id}',
          title: m.title.isNotEmpty ? m.title : 'Mission scout',
          body: m.location?.isNotEmpty == true ? m.location! : (m.notes ?? 'Mission active'),
          time: m.date,
          unread: true,
          icon: Icons.flag_rounded,
          color: const Color(0xFFEF4444),
          route: '/scout/missions',
        ),
      );
    }
    for (final w in data.watchlist.take(3)) {
      items.add(
        OdinNotifItem(
          id: 'wl-${w.id}',
          title: 'Watchlist — ${w.name}',
          body: 'Priorité ${w.priority} · ${w.club}',
          time: '',
          unread: w.priority.toUpperCase() == 'A',
          icon: Icons.bookmark_rounded,
          color: const Color(0xFFF59E0B),
          route: '/scout/watchlist',
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        const OdinNotifItem(
          id: 'empty',
          title: 'Aucune alerte scout',
          body: 'Missions et watchlist apparaîtront ici.',
          time: '',
          unread: false,
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();
    final location = GoRouterState.of(context).uri.path;
    final index = scoutShellIndexForLocation(location);
    final auth = context.watch<AuthProvider>();
    final scout = context.watch<ScoutDataProvider>();
    final club = auth.user?.organization?.clubName ?? 'Scout Center';
    final notifs = _scoutNotifs(scout);
    final unread = notifs.where((n) => n.unread).length;

    return Scaffold(
      extendBody: true,
      backgroundColor: OdinColors.canvas,
      appBar: OdinProAppBar(
        club: club,
        subtitle: 'Espace Scout · ODIN',
        accentColor: OdinColors.accent,
        showLogo: true,
        logoSize: 58,
        actions: [
          OdinNotificationBell(
            unreadCount: unread,
            onPressed: () => showOdinNotificationsSheet(
              context,
              items: notifs,
              seeAllRoute: '/scout/modules',
            ),
          ),
          OdinSettingsButton(
            roleLabel: 'Espace Scout',
            links: const [
              OdinSettingsLink(
                label: 'Profil & préférences',
                subtitle: 'Zones, budget, alertes',
                route: '/scout/settings',
                icon: Icons.tune_rounded,
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
        onSelected: (i) => goToScoutShellTab(context, i),
        accentColor: OdinColors.accent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.manage_search_rounded),
            label: 'Recherche',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_rounded),
            selectedIcon: Icon(Icons.bookmark_rounded),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Modules',
          ),
        ],
      ),
    );
  }
}
