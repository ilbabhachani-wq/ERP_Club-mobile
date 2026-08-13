import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_notifications.dart';
import '../core/widgets/odin_settings_sheet.dart';
import '../core/widgets/odin_widgets.dart';
import '../providers/app_providers.dart';
import '../providers/theme_provider.dart';
import '../router/app_router.dart';

class PlayerShell extends StatefulWidget {
  const PlayerShell({super.key, required this.child});

  final Widget child;

  @override
  State<PlayerShell> createState() => _PlayerShellState();
}

class _PlayerShellState extends State<PlayerShell> {
  List<OdinNotifItem> _joueurNotifs(JoueurDataProvider data) {
    final items = <OdinNotifItem>[];
    for (final inj in data.injuries.take(4)) {
      final title = inj.bodyPart.isNotEmpty ? 'Suivi médical — ${inj.bodyPart}' : 'Suivi médical';
      items.add(
        OdinNotifItem(
          id: 'inj-${inj.id}',
          title: title,
          body: inj.injury.isNotEmpty ? inj.injury : 'Mise à jour dossier médical',
          time: inj.returnDate,
          unread: true,
          icon: Icons.medical_services_outlined,
          color: OdinColors.danger,
          route: '/medical',
        ),
      );
    }
    for (final ev in data.calendarEvents.take(4)) {
      items.add(
        OdinNotifItem(
          id: 'cal-${ev.id}',
          title: ev.title.isNotEmpty ? ev.title : 'Événement',
          body: '${ev.eventType} · ${ev.eventDate}',
          time: ev.eventTime ?? ev.eventDate,
          unread: true,
          icon: Icons.calendar_month_rounded,
          color: OdinColors.info,
          route: '/planning',
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        const OdinNotifItem(
          id: 'empty',
          title: 'Bienvenue sur ODIN',
          body: 'Vos alertes planning et médicales apparaîtront ici.',
          time: 'Maintenant',
          unread: false,
          icon: Icons.notifications_none_rounded,
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
    final index = shellIndexForLocation(location);
    final auth = context.watch<AuthProvider>();
    final joueur = context.watch<JoueurDataProvider>();
    final club = auth.user?.organization?.clubName ?? 'Mon Club';
    final notifs = _joueurNotifs(joueur);
    final unread = notifs.where((n) => n.unread).length;

    return Scaffold(
      extendBody: true,
      backgroundColor: OdinColors.canvas,
      appBar: OdinProAppBar(
        club: club,
        subtitle: 'Espace Joueur · ODIN',
        showLogo: true,
        logoSize: 58,
        accentColor: OdinColors.accent,
        actions: [
          OdinNotificationBell(
            unreadCount: unread,
            onPressed: () => showOdinNotificationsSheet(context, items: notifs),
          ),
          const OdinSettingsButton(
            roleLabel: 'Espace Joueur',
            links: [
              OdinSettingsLink(
                label: 'Mon profil',
                subtitle: 'Carte FIFA, infos',
                route: '/profil',
                icon: Icons.person_outline_rounded,
              ),
            ],
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
        accentColor: OdinColors.accent,
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
