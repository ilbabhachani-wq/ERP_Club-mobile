import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/app_providers.dart';

class AnalysteMenuScreen extends StatelessWidget {
  const AnalysteMenuScreen({super.key});

  static const _items = [
    _Item('Live Match', 'Suivi en temps réel du match', Icons.sensors, '/analyste/live', Color(0xFFEF4444)),
    _Item('Player PPI', 'Score IA FIFA-like', Icons.star_rounded, '/analyste/ppi', Color(0xFFF59E0B)),
    _Item('Viiv GX17', 'Recovery · HRV · GPS', Icons.watch_rounded, '/analyste/viiv', Color(0xFF22D3EE)),
    _Item('Match Prediction', 'RF · XGBoost · CatBoost', Icons.psychology, '/analyste/prediction', AppColors.accent),
    _Item('Team Chemistry', 'Graphe relationnel équipe', Icons.hub_outlined, '/analyste/chemistry', Color(0xFF22C55E)),
    _Item('Patterns IA', 'Détection Deep Learning', Icons.auto_awesome, '/analyste/patterns', Color(0xFFA855F7)),
    _Item('Fatigue', 'Heatmap par intervalles', Icons.local_fire_department, '/analyste/fatigue', AppColors.accent),
    _Item('Injury Lab', 'Prédiction risque ML', Icons.healing, '/analyste/blessures', Color(0xFFEF4444)),
    _Item('Opponent Intel', 'Plan de match adversaire', Icons.shield_outlined, '/analyste/adversaire', AppColors.coral),
    _Item('Executive KPIs', 'Indicateurs direction', Icons.bar_chart_rounded, '/analyste/executive', Color(0xFF22C55E)),
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
            Text('Modules Analyste', style: tt.headlineMedium),
            index: 0,
          ),
          OdinAnimations.fadeUp(
            Text(
              auth.user?.email ?? 'Intelligence Center',
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
            index: 14,
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
