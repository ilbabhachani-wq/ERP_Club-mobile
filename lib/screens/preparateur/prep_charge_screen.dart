import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/preparateur_provider.dart';
import '../../services/preparateur_api.dart';

class PrepChargeScreen extends StatefulWidget {
  const PrepChargeScreen({super.key});

  @override
  State<PrepChargeScreen> createState() => _PrepChargeScreenState();
}

class _PrepChargeScreenState extends State<PrepChargeScreen> {
  String _search = '';
  String _filter = 'all';
  String? _adjusting;

  Color _statutColor(String statut) {
    switch (statut) {
      case 'Critique':
        return AppColors.danger;
      case 'Attention':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Future<void> _adjust(String playerId, bool reduce) async {
    final data = context.read<PreparateurDataProvider>();
    setState(() => _adjusting = playerId);
    try {
      if (reduce) {
        await data.reduceCharge(playerId);
      } else {
        await data.increaseCharge(playerId);
      }
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _adjusting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PreparateurDataProvider>();
    final charge = data.charge;
    final summary = charge?.summary ?? PrepChargeSummary();
    var players = charge?.players ?? <PrepChargePlayer>[];

    if (_filter == 'critique') {
      players = players.where((p) => p.statut == 'Critique').toList();
    } else if (_filter == 'attention') {
      players = players.where((p) => p.statut == 'Attention').toList();
    } else if (_filter == 'normal') {
      players = players.where((p) => p.statut == 'Normal').toList();
    }
    if (_search.isNotEmpty) {
      players = players
          .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }

    if (data.loading && charge == null) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: const Color(0xFF6366F1),
        backgroundColor: AppColors.card,
        onRefresh: () => data.refreshCharge(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(const ScoutSectionLabel('Charges d\'entraînement')),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ScoutKpiCard(
                    label: 'Effectif',
                    value: '${summary.total}',
                    icon: Icons.groups_rounded,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Critiques',
                    value: '${summary.critiques}',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Attention',
                    value: '${summary.attentions}',
                    icon: Icons.priority_high_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Charge moy.',
                    value: '${summary.avgLoad}',
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Rechercher joueur…',
                prefixIcon: Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in [
                    ('all', 'Tous'),
                    ('critique', 'Critique'),
                    ('attention', 'Attention'),
                    ('normal', 'Normal'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.$2),
                        selected: _filter == f.$1,
                        onSelected: (_) => setState(() => _filter = f.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (players.isEmpty)
              const SaasEmptyState(
                title: 'Aucune charge',
                subtitle: 'Les charges d\'entraînement apparaîtront ici',
                icon: Icons.speed_rounded,
              )
            else
              ...players.asMap().entries.map((e) {
                final p = e.value;
                final busy = _adjusting == p.id;
                final color = _statutColor(p.statut);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OdinAnimations.fadeUp(
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: color.withValues(alpha: 0.2),
                                child: Text(
                                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    Text(
                                      p.position,
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  p.statut,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _Metric('Charge', p.loadScore, AppColors.accent)),
                              Expanded(child: _Metric('Fatigue', p.fatigueScore, AppColors.danger)),
                              Expanded(child: _Metric('Récup.', p.recoveryScore, AppColors.success)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: busy ? null : () => _adjust(p.id, true),
                                icon: busy
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.remove_rounded, size: 16),
                                label: const Text('Réduire'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: busy ? null : () => _adjust(p.id, false),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Augmenter'),
                              ),
                            ],
                          ),
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

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(label, style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}
