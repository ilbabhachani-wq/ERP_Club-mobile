import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../models/scout_models.dart';
import '../../providers/scout_provider.dart';

class ScoutShortlistScreen extends StatefulWidget {
  const ScoutShortlistScreen({super.key});

  @override
  State<ScoutShortlistScreen> createState() => _ScoutShortlistScreenState();
}

class _ScoutShortlistScreenState extends State<ScoutShortlistScreen> {
  final _selected = <String>{};
  bool _priorityAOnly = true;
  bool _submitting = false;

  List<ScoutProspect> _candidates(List<ScoutProspect> all) {
    return all.where((p) {
      final prioOk = !_priorityAOnly || p.priority.toUpperCase() == 'A';
      final statusOk = p.status == 'validation' || p.status == 'signature';
      return prioOk || statusOk;
    }).toList()
      ..sort((a, b) => b.potential.compareTo(a.potential));
  }

  Future<void> _submitCommittee() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un prospect'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      final res = await context.read<ScoutDataProvider>().api.submitCommittee(_selected.toList());
      if (mounted) {
        final msg = res['message']?.toString() ?? '${_selected.length} profil(s) envoyé(s) au comité';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
        setState(() => _selected.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final data = context.watch<ScoutDataProvider>();
    final candidates = _candidates(data.prospects);

    return OdinBackdrop(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OdinAnimations.fadeUp(Text('Shortlist', style: tt.headlineMedium), index: 0),
                OdinAnimations.fadeUp(
                  Text('Comité recrutement · ${_selected.length} sélectionné(s)', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
                  index: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: FilterChip(
              label: const Text('Priorité A uniquement'),
              selected: _priorityAOnly,
              onSelected: (v) {
                HapticFeedback.selectionClick();
                setState(() => _priorityAOnly = v);
              },
              selectedColor: AppColors.accent.withValues(alpha: 0.2),
              checkmarkColor: AppColors.accent,
            ),
          ),
          Expanded(
            child: candidates.isEmpty
                ? SaasEmptyState(
                    title: 'Shortlist vide',
                    subtitle: 'Marquez des prospects en priorité A ou en validation',
                    icon: Icons.star_outline_rounded,
                    onAction: data.refreshProspects,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.m, AppSpacing.page, 100),
                    itemCount: candidates.length,
                    itemBuilder: (_, i) {
                      final p = candidates[i];
                      final checked = _selected.contains(p.id);
                      return OdinAnimations.fadeUp(
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (checked) {
                                  _selected.remove(p.id);
                                } else {
                                  _selected.add(p.id);
                                }
                              });
                            },
                            accentColor: checked ? AppColors.accent : null,
                            child: Row(
                              children: [
                                Icon(
                                  checked ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  color: checked ? AppColors.accent : AppColors.muted,
                                ),
                                const SizedBox(width: 12),
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
                                      Row(
                                        children: [
                                          ScoutPriorityBadge(p.priority),
                                          const SizedBox(width: 6),
                                          ScoutWorkflowBadge(p.status),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text('${p.potential}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 18)),
                              ],
                            ),
                          ),
                        ),
                        index: i,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.bottomNav),
            child: FilledButton.icon(
              onPressed: _submitting || _selected.isEmpty ? null : _submitCommittee,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text('Envoyer au comité (${_selected.length})'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
