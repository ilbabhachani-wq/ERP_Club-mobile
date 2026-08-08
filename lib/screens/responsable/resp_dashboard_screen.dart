import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/app_providers.dart';
import '../../providers/responsable_provider.dart';

class RespDashboardScreen extends StatelessWidget {
  const RespDashboardScreen({super.key});

  Color _tone(String? tone) {
    switch (tone) {
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'danger':
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<ResponsableDataProvider>();
    final dash = data.dashboard;

    if (data.loading && dash == null) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    final name = auth.user?.fullName ?? auth.user?.email.split('@').first ?? 'Responsable';
    final club = dash?.clubName ?? auth.user?.organization?.clubName ?? 'Club';

    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.success,
        backgroundColor: AppColors.card,
        onRefresh: () => data.refreshDashboard(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.scaleIn(
              GlassCard(
                raised: true,
                accentColor: AppColors.success,
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
                    Text(
                      '$club · Vue exécutive',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Indicateurs'), index: 1),
            const SizedBox(height: 10),
            if ((dash?.execKpis ?? []).isEmpty)
              const SaasEmptyState(
                title: 'Pas encore de KPIs',
                subtitle: 'Les indicateurs club apparaîtront ici',
                icon: Icons.dashboard_rounded,
                compact: true,
              )
            else
              SizedBox(
                height: 108,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final kpi in dash!.execKpis) ...[
                      ScoutKpiCard(
                        label: kpi['label'] ?? '',
                        value: kpi['value'] ?? '—',
                        icon: Icons.insights_rounded,
                        color: _tone(kpi['tone']),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),
            if ((dash?.secondaryKpis ?? []).isNotEmpty) ...[
              const SizedBox(height: 16),
              OdinAnimations.fadeUp(const ScoutSectionLabel('Détail effectif'), index: 2),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final kpi in dash!.secondaryKpis.take(3))
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                kpi['value'] ?? '—',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                kpi['label'] ?? '',
                                style: TextStyle(color: AppColors.muted, fontSize: 11),
                              ),
                              Text(
                                kpi['note'] ?? '',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            OdinAnimations.fadeUp(
              Row(
                children: [
                  const Expanded(child: ScoutSectionLabel('File de validation')),
                  TextButton(
                    onPressed: () => context.go('/responsable/validation'),
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              index: 3,
            ),
            const SizedBox(height: 8),
            if ((dash?.validationQueue ?? []).isEmpty)
              const SaasEmptyState(
                title: 'Aucune demande en attente',
                subtitle: 'La file de validation est à jour',
                icon: Icons.fact_check_rounded,
                compact: true,
              )
            else
              ...dash!.validationQueue.take(4).map((v) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    onTap: () => context.go('/responsable/validation'),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.pending_actions_rounded, color: AppColors.warning),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                '${v.type} · ${v.from}',
                                style: TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
