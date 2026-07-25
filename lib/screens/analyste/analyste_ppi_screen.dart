import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/analyste_provider.dart';

class AnalystePpiScreen extends StatefulWidget {
  const AnalystePpiScreen({super.key});

  @override
  State<AnalystePpiScreen> createState() => _AnalystePpiScreenState();
}

class _AnalystePpiScreenState extends State<AnalystePpiScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    HapticFeedback.lightImpact();
    try {
      await context.read<AnalysteDataProvider>().load();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AnalysteDataProvider>();
    final players = data.ppiPlayers;
    final tt = Theme.of(context).textTheme;

    if (data.loading && players.isEmpty) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    final sorted = [...players]..sort((a, b) => b.ppi.compareTo(a.ppi));

    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Player PPI', style: tt.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Performance Potential Index — scoring IA',
                          style: tt.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  SaasSyncButton(
                    label: 'Sync',
                    loading: _refreshing,
                    onPressed: _refresh,
                  ),
                ],
              ),
              index: 0,
            ),
            const SizedBox(height: AppSpacing.m),
            if (sorted.isEmpty)
              OdinAnimations.fadeUp(
                GlassCard(
                  child: SaasEmptyState(
                    icon: Icons.insights_outlined,
                    title: 'Aucune donnée PPI disponible',
                    subtitle: 'Les scores IA apparaîtront après synchronisation avec le club.',
                    actionLabel: 'Actualiser',
                    onAction: _refresh,
                  ),
                ),
                index: 1,
              )
            else
              ...List.generate(sorted.length, (i) {
                final p = sorted[i];
                final rank = i + 1;
                final top = i < 3;
                final accent = top ? const Color(0xFFF59E0B) : AppColors.accent;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s),
                  child: OdinAnimations.fadeUp(
                    GlassCard(
                      raised: top,
                      accentColor: accent,
                      padding: const EdgeInsets.all(14),
                      onTap: () => HapticFeedback.selectionClick(),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: AppRadius.smAll,
                              border: Border.all(color: accent.withValues(alpha: 0.28)),
                            ),
                            child: Text(
                              '#$rank',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: accent),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: tt.titleSmall),
                                Text(
                                  [
                                    if (p.position.isNotEmpty) p.position,
                                    if (p.ovr > 0) 'OVR ${p.ovr}',
                                    if (p.trend.isNotEmpty) p.trend,
                                  ].join(' · '),
                                  style: tt.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                p.ppi.toStringAsFixed(p.ppi >= 10 ? 0 : 1),
                                style: tt.titleLarge?.copyWith(color: accent, fontSize: 22),
                              ),
                              Text('PPI', style: tt.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                    index: i + 1,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
