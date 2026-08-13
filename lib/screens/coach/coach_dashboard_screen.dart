import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/app_providers.dart';
import '../../providers/coach_provider.dart';

class CoachDashboardScreen extends StatelessWidget {
  const CoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<CoachProvider>();
    final name = auth.user?.fullName?.split(' ').first ??
        auth.user?.email.split('@').first ??
        'Coach';
    final club = auth.user?.organization?.clubName ?? 'Club';
    final next = data.nextMatch;
    final days = data.daysToNextMatch;
    final today = data.todayTraining;

    if (data.loading && !data.bootstrapped) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: OdinColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: () => data.loadAll(force: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.scaleIn(
              GlassCard(
                raised: true,
                accentColor: OdinColors.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $name',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$club · Briefing coach',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        days == null
                            ? 'Prochain match · ${next.opponent}'
                            : 'Prochain match J-$days · ${next.opponent}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: OdinColors.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Indicateurs'), index: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    label: 'Effectif',
                    value: '${data.players.length}',
                    icon: Icons.groups_rounded,
                    color: OdinColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiTile(
                    label: 'Disponibles',
                    value: '${data.disponibles.length}',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    label: 'Blessés',
                    value: '${data.indisponibles.length}',
                    icon: Icons.healing_rounded,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiTile(
                    label: 'Séances sem.',
                    value: '${data.sessionsThisWeek}',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Séance du jour'), index: 2),
            const SizedBox(height: 10),
            OdinAnimations.fadeUp(
              GlassCard(
                raised: today != null,
                accentColor: OdinColors.accent,
                onTap: () => context.go('/coach/entrainements'),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: OdinColors.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        today == null
                            ? Icons.event_busy_rounded
                            : Icons.fitness_center_rounded,
                        color: OdinColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            today == null
                                ? 'Aucune séance aujourd\'hui'
                                : today.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            today == null
                                ? 'Planifier une séance depuis l\'onglet Séances'
                                : '${today.eventTime} · ${today.location}',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: OdinColors.textMuted),
                  ],
                ),
              ),
              index: 3,
            ),
            const SizedBox(height: 18),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Accès rapide'), index: 4),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: const [
                _QuickTile('Séances', Icons.fitness_center_rounded, OdinColors.accent, '/coach/entrainements'),
                _QuickTile('Présences', Icons.how_to_reg_rounded, AppColors.info, '/coach/presences'),
                _QuickTile('Compo', Icons.sports_soccer, AppColors.success, '/coach/composition'),
                _QuickTile('IA Coach', Icons.auto_awesome_rounded, Color(0xFF22D3EE), '/coach/ia'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: GlassCard(
        raised: true,
        accentColor: color,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile(this.label, this.icon, this.color, this.route);
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.go(route),
      accentColor: color,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
