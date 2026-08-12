import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_settings_sheet.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class CoachShell extends StatelessWidget {
  const CoachShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Séances',
      path: '/coach/entrainements',
    ),
    _TabItem(
      icon: Icons.how_to_reg_outlined,
      activeIcon: Icons.how_to_reg,
      label: 'Présences',
      path: '/coach/presences',
    ),
    _TabItem(
      icon: Icons.sports_soccer_outlined,
      activeIcon: Icons.sports_soccer,
      label: 'Compo',
      path: '/coach/composition',
    ),
    _TabItem(
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
      label: 'Analyse',
      path: '/coach/analyse-match',
    ),
    _TabItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Messages',
      path: '/coach/messages',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: OdinColors.canvas,
      body: navigationShell,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: OdinColors.canvas2,
        onPressed: () => showOdinSettingsSheet(
          context,
          roleLabel: 'Espace Coach',
        ),
        child: Icon(
          Icons.settings_outlined,
          color: OdinColors.textMuted,
          size: 18,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      bottomNavigationBar: _OdinBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        tabs: _tabs,
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}

class _OdinBottomNav extends StatelessWidget {
  const _OdinBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> tabs;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Container(
      decoration: BoxDecoration(
        color: OdinColors.canvas2,
        border: Border(
          top: BorderSide(
            color: OdinColors.panelBorder,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? OdinColors.accent.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          size: 20,
                          color: isActive
                              ? OdinColors.accent
                              : OdinColors.textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? OdinColors.accent
                              : OdinColors.textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
