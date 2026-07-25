import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../models/scout_models.dart';
import '../../providers/scout_provider.dart';

class ScoutProspectsScreen extends StatefulWidget {
  const ScoutProspectsScreen({super.key});

  @override
  State<ScoutProspectsScreen> createState() => _ScoutProspectsScreenState();
}

class _ScoutProspectsScreenState extends State<ScoutProspectsScreen> {
  String _statusFilter = 'all';

  static const _statusChips = [
    ('all', 'Tous'),
    ('new', 'Nouveau'),
    ('analysis', 'Analyse'),
    ('validation', 'Validation'),
    ('signature', 'Signature'),
    ('done', 'Terminé'),
  ];

  List<ScoutProspect> _sorted(List<ScoutProspect> list) {
    final filtered = _statusFilter == 'all'
        ? list
        : list.where((p) => p.status == _statusFilter).toList();
    final copy = List<ScoutProspect>.from(filtered);
    copy.sort((a, b) => b.potential.compareTo(a.potential));
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final data = context.watch<ScoutDataProvider>();
    final prospects = _sorted(data.prospects);

    if (data.loading && data.prospects.isEmpty) {
      return const OdinBackdrop(
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: data.refreshProspects,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(Text('Annuaire', style: tt.headlineMedium), index: 0),
            OdinAnimations.fadeUp(
              Text('${data.prospects.length} prospects en base', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
              index: 1,
            ),
            const SizedBox(height: AppSpacing.m),
            OdinAnimations.fadeUp(
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusChips.map((chip) {
                    final selected = _statusFilter == chip.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(chip.$2),
                        selected: selected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _statusFilter = chip.$1);
                        },
                        selectedColor: AppColors.accent.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.accent,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.accent : AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        side: BorderSide(color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.1)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              index: 2,
            ),
            const SizedBox(height: AppSpacing.m),
            if (prospects.isEmpty)
              SaasEmptyState(
                title: 'Aucun prospect',
                subtitle: 'Modifiez le filtre ou actualisez la liste',
                icon: Icons.groups_outlined,
                onAction: data.refreshProspects,
              )
            else
              ...List.generate(prospects.length, (i) {
                final p = prospects[i];
                return OdinAnimations.fadeUp(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.go('/scout/prospect/${p.id}');
                      },
                      child: Row(
                        children: [
                          ScoutPlayerAvatar(name: p.name, photoUrl: p.photoUrl, flag: p.flag, size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                Text(
                                  '${p.position} · ${p.age} ans · ${p.club}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    ScoutWorkflowBadge(p.status),
                                    if (p.inWatchlist) ...[
                                      const SizedBox(width: 6),
                                      ScoutPriorityBadge(p.priority),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${p.potential}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: AppColors.accent,
                                ),
                              ),
                              Text(
                                p.marketValue,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  index: i + 3,
                );
              }),
          ],
        ),
      ),
    );
  }
}
