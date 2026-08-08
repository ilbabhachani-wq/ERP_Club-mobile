import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/analyste_notifications.dart';
import '../core/widgets/odin_settings_sheet.dart';
import '../core/widgets/odin_widgets.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../router/app_router.dart';

class AnalysteShell extends StatelessWidget {
  const AnalysteShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();
    final location = GoRouterState.of(context).uri.path;
    final index = analysteShellIndexForLocation(location);
    final auth = context.watch<AuthProvider>();
    final club = auth.user?.organization?.clubName ?? 'Intelligence Center';

    return Scaffold(
      extendBody: true,
      backgroundColor: OdinColors.canvas,
      appBar: OdinProAppBar(
        club: club,
        subtitle: 'Espace Analyste · ODIN',
        accentColor: OdinColors.accent,
        showLogo: true,
        logoSize: 58,
        actions: [
          const AnalysteNotificationBell(),
          OdinSettingsButton(roleLabel: 'Espace Analyste'),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey(location),
        child: child,
      ),
      bottomNavigationBar: OdinGlassNavBar(
        selectedIndex: index,
        onSelected: (i) => goToAnalysteShellTab(context, i),
        accentColor: OdinColors.accent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.sensors_outlined),
            selectedIcon: Icon(Icons.sensors),
            label: 'Live',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'PPI',
          ),
          NavigationDestination(
            icon: Icon(Icons.watch_outlined),
            selectedIcon: Icon(Icons.watch_rounded),
            label: 'Viiv',
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
