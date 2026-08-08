import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/preparateur_provider.dart';
import '../../services/preparateur_api.dart';

class PrepConditionScreen extends StatefulWidget {
  const PrepConditionScreen({super.key});

  @override
  State<PrepConditionScreen> createState() => _PrepConditionScreenState();
}

class _PrepConditionScreenState extends State<PrepConditionScreen> {
  String _search = '';
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PreparateurDataProvider>();
    final profiles = data.condition
        .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    final selected = profiles.cast<PrepPhysicalProfile?>().firstWhere(
          (p) => p!.id == (_selectedId ?? (profiles.isNotEmpty ? profiles.first.id : null)),
          orElse: () => profiles.isNotEmpty ? profiles.first : null,
        );

    if (data.loading && data.condition.isEmpty) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    final avgOvr = data.condition.isEmpty
        ? 0
        : (data.condition.fold<int>(0, (s, p) => s + p.ovr) / data.condition.length).round();

    return OdinBackdrop(
      child: RefreshIndicator(
        color: const Color(0xFF6366F1),
        backgroundColor: AppColors.card,
        onRefresh: () => data.refreshCondition(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(const ScoutSectionLabel('Condition physique')),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ScoutKpiCard(
                    label: 'Joueurs',
                    value: '${data.condition.length}',
                    icon: Icons.groups_rounded,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'OVR moyen',
                    value: '$avgOvr',
                    icon: Icons.star_rounded,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 10),
                  ScoutKpiCard(
                    label: 'Top OVR',
                    value: data.condition.isEmpty
                        ? '—'
                        : '${data.condition.map((p) => p.ovr).reduce((a, b) => a > b ? a : b)}',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
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
            const SizedBox(height: 14),
            if (profiles.isEmpty)
              const SaasEmptyState(
                title: 'Aucune performance',
                subtitle: 'Les profils physiques apparaîtront ici',
                icon: Icons.insights_rounded,
              )
            else ...[
              if (selected != null) ...[
                OdinAnimations.fadeUp(
                  GlassCard(
                    raised: true,
                    accentColor: const Color(0xFF6366F1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selected.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  Text(
                                    selected.position,
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'OVR ${selected.ovr}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatChip('Vitesse', selected.speed, const Color(0xFFFF6B57)),
                            _StatChip('Endurance', selected.endurance, const Color(0xFF6366F1)),
                            _StatChip('Force', selected.force, const Color(0xFFEF4444)),
                            _StatChip('Explosivité', selected.explosivity, const Color(0xFFF59E0B)),
                            _StatChip('Agilité', selected.agility, const Color(0xFF22C55E)),
                            _StatChip('Récupération', selected.recovery, const Color(0xFF3B82F6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const ScoutSectionLabel('Effectif'),
                const SizedBox(height: 10),
              ],
              ...profiles.asMap().entries.map((e) {
                final p = e.value;
                final active = selected?.id == p.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OdinAnimations.fadeUp(
                    GlassCard(
                      raised: active,
                      accentColor: const Color(0xFF6366F1),
                      onTap: () => setState(() => _selectedId = p.id),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            child: Text(
                              p.name.isNotEmpty ? p.name[0] : '?',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w800,
                              ),
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
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  p.position,
                                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${p.ovr}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    index: e.key,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 64) / 3,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
