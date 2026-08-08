import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/app_providers.dart';
import '../../providers/preparateur_provider.dart';

const _accent = Color(0xFF6366F1);

class PrepDashboardScreen extends StatelessWidget {
  const PrepDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<PreparateurDataProvider>();
    final charge = data.charge;

    if (data.loading && charge == null) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    final name = auth.user?.fullName ?? auth.user?.email.split('@').first ?? 'Préparateur';
    final club = auth.user?.organization?.clubName ?? 'Club';
    final total = charge?.summary.total ?? 0;
    final avgLoad = charge?.summary.avgLoad ?? 0;
    final critiques = charge?.summary.critiques ?? 0;
    final validated = data.programs.where((p) => p.status == 'valide').length;

    return OdinBackdrop(
      child: RefreshIndicator(
        color: _accent,
        backgroundColor: AppColors.card,
        onRefresh: () => data.load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.scaleIn(
              GlassCard(
                raised: true,
                accentColor: _accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $name',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text),
                    ),
                    const SizedBox(height: 4),
                    Text('$club · Préparation Physique', style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Indicateurs'), index: 1),
            const SizedBox(height: 10),
            SizedBox(
              height: 108,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ScoutKpiCard(label: 'Effectif', value: '$total', icon: Icons.groups_rounded, color: _accent),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Charge moy.',
                    value: '$avgLoad%',
                    icon: Icons.speed_rounded,
                    color: avgLoad >= 75 ? AppColors.danger : AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Critiques',
                    value: '$critiques',
                    icon: Icons.warning_amber_rounded,
                    color: critiques > 0 ? AppColors.danger : AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Programmes validés',
                    value: '$validated',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OdinAnimations.fadeUp(
              Row(
                children: [
                  const Expanded(child: ScoutSectionLabel('Accès rapide')),
                ],
              ),
              index: 2,
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _QuickTile(
                  icon: Icons.fitness_center_rounded,
                  label: 'Programmes',
                  color: _accent,
                  onTap: () => context.go('/preparateur/programmes'),
                ),
                _QuickTile(
                  icon: Icons.speed_rounded,
                  label: 'Charge',
                  color: const Color(0xFFF59E0B),
                  onTap: () => context.go('/preparateur/charge'),
                ),
                _QuickTile(
                  icon: Icons.insights_rounded,
                  label: 'Condition physique',
                  color: AppColors.success,
                  onTap: () => context.go('/preparateur/condition'),
                ),
                _QuickTile(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Assistant IA',
                  color: const Color(0xFF22D3EE),
                  onTap: () => context.go('/preparateur/ia'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      accentColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
