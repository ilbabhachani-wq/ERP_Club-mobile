import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/responsable_provider.dart';

class RespTeamsScreen extends StatelessWidget {
  const RespTeamsScreen({super.key});

  Color _catColor(String cat) {
    switch (cat) {
      case 'Seniors':
        return AppColors.accent;
      case 'U21':
        return AppColors.info;
      case 'U18':
        return AppColors.success;
      default:
        return const Color(0xFFA855F7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<ResponsableDataProvider>();
    final teams = data.teams;

    if (data.loading && teams.isEmpty) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: AppColors.success,
        backgroundColor: AppColors.card,
        onRefresh: () => data.refreshTeams(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(const ScoutSectionLabel('Suivi des équipes')),
            const SizedBox(height: 6),
             Text(
              'Vue par catégories d\'âge — même logique que le web',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            if (teams.isEmpty)
              SaasEmptyState(
                title: 'Aucune équipe',
                subtitle: 'Les catégories apparaîtront dès que l\'effectif est chargé',
                icon: Icons.groups_rounded,
                onAction: () => data.refreshTeams(),
              )
            else
              ...teams.asMap().entries.map((e) {
                final team = e.value;
                final color = _catColor(team.category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OdinAnimations.fadeUp(
                    GlassCard(
                      raised: true,
                      accentColor: color,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  team.category,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                team.ranking,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            team.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.person_rounded,
                                  label: 'Joueurs',
                                  value: '${team.playerCount}',
                                ),
                              ),
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.sports_rounded,
                                  label: 'Coach',
                                  value: team.coach,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.calendar_month_rounded,
                                  label: 'Calendrier',
                                  value: team.calendar,
                                ),
                              ),
                              Expanded(
                                child: _InfoTile(
                                  icon: Icons.badge_rounded,
                                  label: 'Staff',
                                  value: team.staff,
                                ),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.muted, fontSize: 10)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
