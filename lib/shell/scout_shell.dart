import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_widgets.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';

class ScoutShell extends StatelessWidget {
  const ScoutShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = scoutShellIndexForLocation(location);
    final auth = context.watch<AuthProvider>();
    final club = auth.user?.organization?.clubName ?? 'Scout Center';

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
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout_rounded, color: OdinColors.textSecondary),
            onPressed: () => auth.logout(),
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
