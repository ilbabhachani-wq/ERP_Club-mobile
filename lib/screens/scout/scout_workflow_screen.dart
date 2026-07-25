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

class ScoutWorkflowScreen extends StatefulWidget {
  const ScoutWorkflowScreen({super.key});

  @override
  State<ScoutWorkflowScreen> createState() => _ScoutWorkflowScreenState();
}

class _ScoutWorkflowScreenState extends State<ScoutWorkflowScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  List<ScoutProspect> _forCol(String colId, List<ScoutProspect> all) {
    return all.where((p) => p.status == colId).toList();
  }

  Future<void> _moveNext(ScoutProspect p) async {
    final idx = kScoutWorkflowCols.indexWhere((c) => c.id == p.status);
    if (idx < 0 || idx >= kScoutWorkflowCols.length - 1) return;
    HapticFeedback.mediumImpact();
    final next = kScoutWorkflowCols[idx + 1].id;
    await context.read<ScoutDataProvider>().updateWorkflow(p.id, next);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} → ${kScoutWorkflowCols[idx + 1].label}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final data = context.watch<ScoutDataProvider>();
    final prospects = data.prospects;

    return OdinBackdrop(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OdinAnimations.fadeUp(Text('Workflow', style: tt.headlineMedium), index: 0),
                OdinAnimations.fadeUp(
                  Text('Pipeline recrutement', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
                  index: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              itemCount: kScoutWorkflowCols.length,
              itemBuilder: (_, i) {
                final col = kScoutWorkflowCols[i];
                final count = _forCol(col.id, prospects).length;
                final selected = _page == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? col.color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? col.color : Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        '${col.label} ($count)',
                        style: TextStyle(
                          color: selected ? col.color : AppColors.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: kScoutWorkflowCols.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, pageIdx) {
                final col = kScoutWorkflowCols[pageIdx];
                final items = _forCol(col.id, prospects);
                if (items.isEmpty) {
                  return SaasEmptyState(
                    title: 'Colonne vide',
                    subtitle: 'Aucun prospect en « ${col.label} »',
                    icon: Icons.inbox_outlined,
                    onAction: data.refreshProspects,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.m, AppSpacing.page, AppSpacing.bottomNav),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final p = items[i];
                    final canAdvance = pageIdx < kScoutWorkflowCols.length - 1;
                    return OdinAnimations.fadeUp(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          accentColor: col.color,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.go('/scout/prospect/${p.id}');
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ScoutPlayerAvatar(name: p.name, photoUrl: p.photoUrl, flag: p.flag, size: 44),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                        Text(
                                          '${p.position} · ${p.club}',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text('${p.potential}', style: TextStyle(fontWeight: FontWeight.w900, color: col.color, fontSize: 18)),
                                ],
                              ),
                              if (canAdvance) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => _moveNext(p),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: kScoutWorkflowCols[pageIdx + 1].color,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: Text('→ ${kScoutWorkflowCols[pageIdx + 1].label}'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      index: i,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
