import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/odin_colors.dart';
import '../core/widgets/odin_settings_sheet.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class MedecinShell extends StatelessWidget {
  const MedecinShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(
      icon: Icons.folder_shared_outlined,
      activeIcon: Icons.folder_shared,
      label: 'Dossiers',
      path: '/medecin/dossiers',
    ),
    _TabItem(
      icon: Icons.healing_outlined,
      activeIcon: Icons.healing,
      label: 'Blessures',
      path: '/medecin/blessures',
    ),
    _TabItem(
      icon: Icons.medical_services_outlined,
      activeIcon: Icons.medical_services,
      label: 'Traitements',
      path: '/medecin/traitements',
    ),
    _TabItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'Rendez-vous',
      path: '/medecin/rendezvous',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OdinColors.canvas,
      body: navigationShell,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: OdinColors.canvas2,
        onPressed: () => showOdinSettingsSheet(
          context,
          roleLabel: 'Espace Médecin',
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
          initialLocation:
            i == navigationShell.currentIndex,
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
                  child: AnimatedContainer(
                    duration:
                      const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment:
                        MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 200
                          ),
                          padding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          decoration: BoxDecoration(
                            color: isActive
                              ? const Color(0xFFFF7A00)
                                .withValues(alpha: 0.15)
                              : Colors.transparent,
                            borderRadius:
                              BorderRadius.circular(20),
                          ),
                          child: Icon(
                            isActive
                              ? tab.activeIcon
                              : tab.icon,
                            size: 22,
                            color: isActive
                              ? const Color(0xFFFF7A00)
                              : OdinColors.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(
                            milliseconds: 200
                          ),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                            color: isActive
                              ? const Color(0xFFFF7A00)
                              : OdinColors.textMuted.withValues(alpha: 0.7),
                          ),
                          child: Text(tab.label),
                        ),
                      ],
                    ),
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
