import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/app_providers.dart';
import '../../providers/medecin_provider.dart';

class MedecinDashboardScreen extends StatelessWidget {
  const MedecinDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<MedecinProvider>();
    final name = auth.user?.fullName?.split(' ').first ??
        auth.user?.email.split('@').first ??
        'Médecin';
    final club = auth.user?.organization?.clubName ?? 'Club';

    if (data.loading && !data.bootstrapped) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: OdinColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: () => data.loadAll(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.scaleIn(
              GlassCard(
                raised: true,
                accentColor: OdinColors.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $name',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$club · Centre médical', style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Indicateurs'), index: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    label: 'Dossiers',
                    value: '${data.players.length}',
                    icon: Icons.folder_shared_rounded,
                    color: OdinColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiTile(
                    label: 'Actives',
                    value: '${data.activeInjuries.length}',
                    icon: Icons.healing_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    label: 'Rééducation',
                    value: '${data.inReeducation.length}',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiTile(
                    label: 'RDV jour',
                    value: '${data.todayEvents.length}',
                    icon: Icons.calendar_month_rounded,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Cas actifs'), index: 2),
            const SizedBox(height: 10),
            if (data.activeInjuries.isEmpty)
              GlassCard(
                child: Text('Aucune blessure active.', style: TextStyle(color: AppColors.muted)),
              )
            else
              ...data.activeInjuries.take(4).map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        onTap: () => context.go('/medecin/blessures'),
                        accentColor: OdinColors.accent,
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: OdinColors.accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.healing_rounded, color: OdinColors.accent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(
                                    '${i.injury} · ${i.bodyPart}',
                                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: OdinColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: GlassCard(
        raised: true,
        accentColor: color,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
