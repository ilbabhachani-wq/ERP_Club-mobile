import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_notifications.dart';
import '../core/widgets/odin_settings_sheet.dart';
import '../core/widgets/odin_widgets.dart';
import '../providers/app_providers.dart';
import '../providers/preparateur_provider.dart';
import '../providers/theme_provider.dart';
import '../router/app_router.dart';

class PreparateurShell extends StatelessWidget {
  const PreparateurShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Rebuild shell when theme/locale flip so OdinColors/AppColors refresh in place.
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    final location = GoRouterState.of(context).uri.path;
    final index = preparateurShellIndexForLocation(location);
    final auth = context.watch<AuthProvider>();
    final prep = context.watch<PreparateurDataProvider>();
    final club = auth.user?.organization?.clubName ?? 'Préparation Physique';
    const accent = Color(0xFF6366F1);

    // Safety net: if cold-start skipped splash load, fetch once here.
    if (auth.isAuthenticated && !prep.bootstrapped && !prep.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.read<PreparateurDataProvider>().load();
      });
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: OdinColors.canvas,
      appBar: OdinProAppBar(
        club: club,
        subtitle: 'Préparateur · ODIN',
        accentColor: accent,
        showLogo: true,
        logoSize: 58,
        actions: [
          OdinNotificationBell(
            unreadCount: prep.unreadNotifications,
            color: OdinColors.textSecondary,
            onPressed: () {
              final items = prep.notifications
                  .map(
                    (n) => OdinNotifItem(
                      id: n.id,
                      title: n.title,
                      body: n.body,
                      time: n.createdAt?.split('T').first ?? '',
                      unread: !n.isRead,
                      color: n.priority == 'haute'
                          ? OdinColors.danger
                          : n.priority == 'moyenne'
                              ? OdinColors.warning
                              : accent,
                    ),
                  )
                  .toList();
              showOdinNotificationsSheet(
                context,
                items: items,
                seeAllRoute: '/preparateur/notifications',
                onMarkAllRead: () => prep.markAllNotificationsRead(),
                onTapItem: (item) {
                  if (item.unread) prep.markNotificationRead(item.id);
                },
              );
            },
          ),
          OdinSettingsButton(
            roleLabel: 'Espace Préparateur',
            links: const [
              OdinSettingsLink(
                label: 'Mon profil',
                subtitle: 'Photo, sécurité',
                route: '/preparateur/profil',
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
        onSelected: (i) => goToPreparateurShellTab(context, i),
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
            label: 'Programmes',
          ),
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed_rounded),
            label: 'Charge',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Perfos',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
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
