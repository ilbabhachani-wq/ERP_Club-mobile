import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static const _featured = _MenuItem(
    'Viiv GX17',
    'Smartwatch · Sync live',
    Icons.watch_rounded,
    '/viiv',
    Color(0xFF22D3EE),
    featured: true,
  );

  static const _items = [
    _MenuItem('Profil', '', Icons.person_outline_rounded, '/profil', OdinColors.playerCoral),
    _MenuItem('Médical', '', Icons.medical_services_outlined, '/medical', OdinColors.danger),
    _MenuItem('Messages', '', Icons.chat_bubble_outline_rounded, '/messages', OdinColors.info),
    _MenuItem('Effectif', '', Icons.groups_outlined, '/liste', OdinColors.accent),
    _MenuItem('Comparer', '', Icons.compare_arrows_rounded, '/comparer', OdinColors.warning),
    _MenuItem('Formation', '', Icons.grid_on_outlined, '/formation', OdinColors.success),
    _MenuItem('Transferts', '', Icons.swap_horiz_rounded, '/transferts', OdinColors.playerCoral),
    _MenuItem('Documents', '', Icons.folder_open_outlined, '/documents', OdinColors.info),
    _MenuItem('Entraînement', '', Icons.fitness_center_rounded, '/entrainement', OdinColors.accent),
    _MenuItem('Analyse Match', '', Icons.analytics_outlined, '/analyse', OdinColors.warning),
    _MenuItem('Récompenses', '', Icons.emoji_events_outlined, '/recompenses', Color(0xFFD99A1F)),
    _MenuItem('Chimie', '', Icons.hub_outlined, '/chimie', OdinColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return OdinPageScaffold(
      animate: false,
      child: ListView(
        children: [
          OdinAnimations.fadeUp(
            const Text(
              'Modules',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            index: 0,
          ),
          const SizedBox(height: 4),
          OdinAnimations.fadeUp(
            const Text('Toutes vos fonctionnalités joueur', style: TextStyle(color: OdinColors.textMuted)),
            index: 1,
          ),
          const SizedBox(height: 20),
          OdinAnimations.fadeUp(_FeaturedTile(item: _featured, onTap: () => context.go(_featured.route)), index: 2),
          const SizedBox(height: 20),
          const SectionTitle('Explorer'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              return OdinAnimations.fadeUp(
                GlassCard(
                  onTap: () => context.go(item.route),
                  accentColor: item.color,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [item.color.withValues(alpha: 0.25), item.color.withValues(alpha: 0.08)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                      const Spacer(),
                      Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                index: i + 3,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile({required this.item, required this.onTap});
  final _MenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      raised: true,
      accentColor: item.color,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [item.color.withValues(alpha: 0.35), item.color.withValues(alpha: 0.05)]),
              border: Border.all(color: item.color.withValues(alpha: 0.4)),
            ),
            child: Icon(item.icon, color: item.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text(item.subtitle, style: TextStyle(color: item.color, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: item.color.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.label, this.subtitle, this.icon, this.route, this.color, {this.featured = false});
  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
  final bool featured;
}
