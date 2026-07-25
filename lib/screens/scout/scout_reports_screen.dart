import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/scout_provider.dart';

class ScoutReportsScreen extends StatelessWidget {
  const ScoutReportsScreen({super.key});

  static const _decisionLabels = {
    'recruit': ('Recruter', AppColors.success),
    'observe': ('Observer', Color(0xFFF59E0B)),
    'shortlist': ('Shortlist', Color(0xFF3B82F6)),
    'refuse': ('Refuser', AppColors.danger),
  };

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final data = context.watch<ScoutDataProvider>();
    final reports = data.reports;

    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: data.refreshReports,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(Text('Historique', style: tt.headlineMedium), index: 0),
            OdinAnimations.fadeUp(
              Text('${reports.length} rapports soumis', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
              index: 1,
            ),
            const SizedBox(height: AppSpacing.m),
            if (reports.isEmpty)
              SaasEmptyState(
                title: 'Aucun rapport',
                subtitle: 'Vos évaluations apparaîtront ici',
                icon: Icons.assignment_outlined,
                onAction: data.refreshReports,
              )
            else
              ...List.generate(reports.length, (i) {
                final r = reports[i];
                return OdinAnimations.fadeUp(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.prospectName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ),
                              if (r.aiScore != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'IA ${r.aiScore}',
                                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${r.matchObserved ?? r.matchDate ?? '—'}${r.opponent != null ? ' vs ${r.opponent}' : ''}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _DecisionBadge(r.decision),
                              const Spacer(),
                              Text(
                                r.createdAt,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                              ),
                            ],
                          ),
                          if (r.strengths?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              r.strengths!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  index: i + 2,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _DecisionBadge extends StatelessWidget {
  const _DecisionBadge(this.decision);
  final String decision;

  @override
  Widget build(BuildContext context) {
    final meta = ScoutReportsScreen._decisionLabels[decision] ?? (decision, AppColors.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: meta.$2.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: meta.$2.withValues(alpha: 0.35)),
      ),
      child: Text(meta.$1, style: TextStyle(color: meta.$2, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
