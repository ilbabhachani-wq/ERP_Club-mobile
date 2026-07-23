import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_widgets.dart';
import '../providers/app_providers.dart';
import '../router/app_router.dart';

class PlayerShell extends StatefulWidget {
  const PlayerShell({super.key, required this.child});

  final Widget child;

  @override
  State<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends State<PlayerShell> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = shellIndexForLocation(location);
    final auth = context.watch<AuthProvider>();
    final club = auth.user?.organization?.clubName ?? 'Mon Club';

    return Scaffold(
      extendBody: true,
      backgroundColor: OdinColors.canvas,
      appBar: OdinProAppBar(
        club: club,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: KeyedSubtree(
        key: ValueKey(location),
        child: widget.child,
      ),
      bottomNavigationBar: OdinGlassNavBar(
        selectedIndex: index,
        onSelected: (i) => goToShellTab(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Perf'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Planning'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'IA'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Menu'),
        ],
      ),
    );
  }
}
