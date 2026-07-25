import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/app_providers.dart';

class ScoutMenuScreen extends StatelessWidget {
  const ScoutMenuScreen({super.key});

  static const _items = [
    _Item('Annuaire', 'Base prospects club', Icons.groups_rounded, '/scout/prospects', Color(0xFF22C55E)),
    _Item('Workflow', 'Pipeline recrutement', Icons.view_kanban_rounded, '/scout/workflow', Color(0xFF3B82F6)),
    _Item('Rapport', 'Nouvelle évaluation', Icons.assignment_rounded, '/scout/report', AppColors.accent),
    _Item('Historique', 'Rapports soumis', Icons.history_rounded, '/scout/reports', Color(0xFF8B5CF6)),
    _Item('Missions', 'Terrain & vidéo', Icons.flag_rounded, '/scout/missions', Color(0xFFEF4444)),
    _Item('ODIN AI', 'Recherche intelligente', Icons.auto_awesome, '/scout/ai', Color(0xFF22D3EE)),
    _Item('Agents', 'Réseau mandataires', Icons.handshake_rounded, '/scout/agents', Color(0xFFF59E0B)),
    _Item('Shortlist', 'Comité recrutement', Icons.star_rounded, '/scout/shortlist', Color(0xFFA855F7)),
    _Item('Mon profil', 'Paramètres scout', Icons.person_rounded, '/scout/settings', Color(0xFF64748B)),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tt = Theme.of(context).textTheme;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
        children: [
          OdinAnimations.fadeUp(
            Text('Modules Scout', style: tt.headlineMedium),
            index: 0,
          ),
          OdinAnimations.fadeUp(
            Text(
              auth.user?.email ?? 'Recrutement & Prospection',
              style: tt.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            index: 1,
          ),
          const SizedBox(height: AppSpacing.m),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 140,
            ),
            itemBuilder: (_, i) {
              final item = _items[i];
              return OdinAnimations.fadeUp(
                SaasModuleCard(
                  title: item.label,
                  subtitle: item.subtitle,
                  icon: item.icon,
                  color: item.color,
                  onTap: () => context.go(item.route),
                ),
                index: i + 2,
              );
            },
          ),
          const SizedBox(height: AppSpacing.m),
          OdinAnimations.fadeUp(
            GlassCard(
              onTap: () {
                HapticFeedback.mediumImpact();
                auth.logout();
              },
              accentColor: AppColors.danger,
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.danger),
                  SizedBox(width: 12),
                  Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            index: 12,
          ),
        ],
      ),
    );
  }
}

class _Item {
  const _Item(this.label, this.subtitle, this.icon, this.route, this.color);
  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;
}
