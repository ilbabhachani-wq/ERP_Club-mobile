import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/responsable_provider.dart';
import '../../services/responsable_api.dart';

class RespValidationScreen extends StatefulWidget {
  const RespValidationScreen({super.key});

  @override
  State<RespValidationScreen> createState() => _RespValidationScreenState();
}

class _RespValidationScreenState extends State<RespValidationScreen> {
  String _filter = 'Tous';
  String? _busyId;

  Color _statusColor(String status) {
    switch (status) {
      case 'Validé':
        return AppColors.success;
      case 'Refusé':
        return AppColors.danger;
      case 'Retour':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.warning;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Critique':
        return AppColors.danger;
      case 'Haute':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  Future<void> _decide(ValidationRequest req, String action) async {
    final data = context.read<ResponsableDataProvider>();
    setState(() => _busyId = req.id);
    try {
      await data.decide(req.id, action);
      HapticFeedback.mediumImpact();
      if (mounted) {
        final label = action == 'approve'
            ? 'Validé'
            : action == 'reject'
                ? 'Refusé'
                : 'Retour demandé';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ResponsableDataProvider>();
    final all = data.validation;
    final filtered = _filter == 'Tous' ? all : all.where((r) => r.status == _filter).toList();

    final pending = all.where((r) => r.status == 'En attente').length;
    final approved = all.where((r) => r.status == 'Validé').length;
    final rejected = all.where((r) => r.status == 'Refusé').length;
    final returned = all.where((r) => r.status == 'Retour').length;

    if (data.loading && all.isEmpty) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.success,
        backgroundColor: AppColors.card,
        onRefresh: () => data.refreshValidation(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(const ScoutSectionLabel('Validation de demandes')),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ScoutKpiCard(label: 'En attente', value: '$pending', icon: Icons.schedule_rounded, color: AppColors.warning),
                  const SizedBox(width: 10),
                  ScoutKpiCard(label: 'Validés', value: '$approved', icon: Icons.check_circle_rounded, color: AppColors.success),
                  const SizedBox(width: 10),
                  ScoutKpiCard(label: 'Refusés', value: '$rejected', icon: Icons.cancel_rounded, color: AppColors.danger),
                  const SizedBox(width: 10),
                  ScoutKpiCard(label: 'Retour', value: '$returned', icon: Icons.replay_rounded, color: const Color(0xFF8B5CF6)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in ['Tous', 'En attente', 'Validé', 'Refusé', 'Retour'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (filtered.isEmpty)
              const SaasEmptyState(
                title: 'Aucune demande',
                subtitle: 'Les demandes de validation apparaîtront ici',
                icon: Icons.fact_check_rounded,
              )
            else
              ...filtered.asMap().entries.map((e) {
                final req = e.value;
                final pendingReq = req.status == 'En attente';
                final busy = _busyId == req.id;
                final statusColor = _statusColor(req.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OdinAnimations.fadeUp(
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  req.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  req.status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${req.type} · ${req.from}',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                          if (req.detail.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              req.detail,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _MetaChip(req.priority, _priorityColor(req.priority)),
                              if (req.amount != null && req.amount!.isNotEmpty)
                                _MetaChip(req.amount!, AppColors.success),
                              if (req.date.isNotEmpty) _MetaChip(req.date, AppColors.info),
                            ],
                          ),
                          if (pendingReq) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: busy ? null : () => _decide(req, 'approve'),
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Valider'),
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: busy ? null : () => _decide(req, 'reject'),
                                    icon: const Icon(Icons.close_rounded, size: 16),
                                    label: const Text('Refuser'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: busy ? null : () => _decide(req, 'return'),
                                  icon: busy
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.replay_rounded),
                                  tooltip: 'Retour',
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    index: e.key,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
