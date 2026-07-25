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

class ScoutWatchlistScreen extends StatefulWidget {
  const ScoutWatchlistScreen({super.key});

  @override
  State<ScoutWatchlistScreen> createState() => _ScoutWatchlistScreenState();
}

class _ScoutWatchlistScreenState extends State<ScoutWatchlistScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<ScoutProspect> _filtered(List<ScoutProspect> all, String prio) {
    return all.where((p) => p.priority.toUpperCase() == prio).toList();
  }

  Future<void> _addNote(ScoutProspect p) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Ajouter une note'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Observation terrain…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null || text.isEmpty || !mounted) return;
    await context.read<ScoutDataProvider>().addNote(p.id, text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note ajoutée'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _remove(ScoutProspect p) async {
    HapticFeedback.mediumImpact();
    await context.read<ScoutDataProvider>().toggleWatchlist(p);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${p.name} retiré de la watchlist'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final data = context.watch<ScoutDataProvider>();
    final watchlist = data.watchlist;

    return OdinBackdrop(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OdinAnimations.fadeUp(Text('Watchlist', style: tt.headlineMedium), index: 0),
                OdinAnimations.fadeUp(
                  Text('${watchlist.length} profils suivis', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
                  index: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.muted,
            tabs: const [
              Tab(text: 'Priorité A'),
              Tab(text: 'Priorité B'),
              Tab(text: 'Priorité C'),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.card,
              onRefresh: data.refreshWatchlist,
              child: TabBarView(
                controller: _tabs,
                children: ['A', 'B', 'C'].map((prio) {
                  final items = _filtered(watchlist, prio);
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SaasEmptyState(
                          title: 'Watchlist vide',
                          subtitle: 'Aucun prospect en priorité $prio',
                          icon: Icons.bookmark_border_rounded,
                          onAction: data.refreshWatchlist,
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.m, AppSpacing.page, AppSpacing.bottomNav),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final p = items[i];
                      return OdinAnimations.fadeUp(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onLongPress: () {
                              HapticFeedback.heavyImpact();
                              context.read<ScoutDataProvider>().cyclePriority(p);
                            },
                            child: GlassCard(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.go('/scout/prospect/${p.id}');
                              },
                              child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ScoutPlayerAvatar(name: p.name, photoUrl: p.photoUrl, flag: p.flag, size: 48),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                          Text(
                                            '${p.position} · ${p.club} · Pot. ${p.potential}',
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ScoutPriorityBadge(p.priority),
                                  ],
                                ),
                                if (p.notes.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    p.notes.last.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        context.read<ScoutDataProvider>().cyclePriority(p);
                                      },
                                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                      label: const Text('Priorité'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _addNote(p),
                                      icon: const Icon(Icons.note_add_outlined, size: 16),
                                      label: const Text('Note'),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => _remove(p),
                                      icon: const Icon(Icons.bookmark_remove_rounded, color: AppColors.danger, size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ),
                          ),
                        ),
                        index: i,
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
