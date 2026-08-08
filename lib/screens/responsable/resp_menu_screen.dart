import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

const _accent = Color(0xFF22C55E);

class RespMenuScreen extends StatelessWidget {
  const RespMenuScreen({super.key});

  static const _featured = _MenuItem(
    'Messages',
    'Discutez avec le staff & les joueurs',
    Icons.chat_bubble_outline_rounded,
    '/responsable/messages',
    OdinColors.info,
  );

  static const _items = [
    _MenuItem('Dashboard', 'Vue exécutive', Icons.dashboard_rounded, '/responsable', _accent),
    _MenuItem('Validation', 'File de demandes', Icons.fact_check_rounded, '/responsable/validation', Color(0xFFF59E0B)),
    _MenuItem('Équipes', 'Suivi par catégorie', Icons.groups_rounded, '/responsable/equipes', Color(0xFF3B82F6)),
    _MenuItem('Notifications', 'Alertes club', Icons.notifications_outlined, '/responsable/notifications', OdinColors.danger),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          OdinAnimations.fadeUp(
            const Text('Menu', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            index: 0,
          ),
          const SizedBox(height: 4),
          OdinAnimations.fadeUp(
            Text(
              auth.user?.organization?.clubName ?? 'Direction Club',
              style: TextStyle(color: OdinColors.textMuted),
            ),
            index: 1,
          ),
          const SizedBox(height: 20),
          OdinAnimations.fadeUp(_FeaturedTile(item: _featured, onTap: () => context.go(_featured.route)), index: 2),
          const SizedBox(height: 20),
          const SectionTitle('Explorer'),
          const SizedBox(height: 10),
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
                          gradient: LinearGradient(colors: [item.color.withValues(alpha: 0.25), item.color.withValues(alpha: 0.08)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                      const Spacer(),
                      Text(item.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: OdinColors.textMuted),
                      ),
                    ],
                  ),
                ),
                index: i + 3,
              );
            },
          ),
          const SizedBox(height: 20),
          OdinAnimations.fadeUp(
            GlassCard(
              onTap: () {
                HapticFeedback.mediumImpact();
                auth.logout();
              },
              accentColor: OdinColors.danger,
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: OdinColors.danger),
                  SizedBox(width: 12),
                  Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            index: _items.length + 3,
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
  const _MenuItem(this.label, this.subtitle, this.icon, this.route, this.color);
  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}
