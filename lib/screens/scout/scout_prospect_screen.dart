import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../models/scout_models.dart';
import '../../providers/scout_provider.dart';

class ScoutProspectScreen extends StatefulWidget {
  const ScoutProspectScreen({super.key, required this.prospectId});

  final String prospectId;

  @override
  State<ScoutProspectScreen> createState() => _ScoutProspectScreenState();
}

class _ScoutProspectScreenState extends State<ScoutProspectScreen> {
  ScoutProspect? _prospect;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await context.read<ScoutDataProvider>().api.getProspect(widget.prospectId);
      if (mounted) setState(() => _prospect = p);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleWatchlist() async {
    final p = _prospect;
    if (p == null) return;
    HapticFeedback.mediumImpact();
    await context.read<ScoutDataProvider>().toggleWatchlist(p);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (_loading) {
      return const OdinBackdrop(
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_error != null || _prospect == null) {
      return OdinBackdrop(
        child: Center(
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(_error ?? 'Prospect introuvable'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }

    final p = _prospect!;
    final skills = [
      ('Vitesse', p.speed),
      ('Dribble', p.dribble),
      ('Passes', p.passing),
      ('Défense', p.defense),
      ('Physique', p.physical),
      ('Mental', p.mental),
    ];

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
        children: [
          OdinAnimations.scaleIn(
            GlassCard(
              raised: true,
              accentColor: AppColors.accent,
              child: Row(
                children: [
                  ScoutPlayerAvatar(name: p.name, photoUrl: p.photoUrl, flag: p.flag, size: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                        Text(
                          '${p.position} · ${p.age} ans · ${p.nationality}',
                          style: tt.bodyMedium?.copyWith(color: AppColors.muted),
                        ),
                        Text('${p.club} · ${p.league}', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            ScoutWorkflowBadge(p.status),
                            ScoutPriorityBadge(p.priority),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('${p.potential}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.accent)),
                       Text('POTENTIEL', style: TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          OdinAnimations.fadeUp(const ScoutSectionLabel('Profil technique'), index: 1),
          const SizedBox(height: 8),
          ...List.generate(skills.length, (i) {
            final (label, value) = skills[i];
            return OdinAnimations.fadeUp(
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const Spacer(),
                          Text('$value', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value / 100,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              index: i + 2,
            );
          }),
          const SizedBox(height: AppSpacing.m),
          OdinAnimations.fadeUp(const ScoutSectionLabel('Statistiques'), index: 8),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatChip('Buts', '${p.goals}'),
                  _StatChip('Passes D.', '${p.assists}'),
                  _StatChip('Matchs', '${p.matches}'),
                  _StatChip('Score IA', '${p.aiScore}'),
                ],
              ),
            ),
            index: 9,
          ),
          if (p.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            OdinAnimations.fadeUp(const ScoutSectionLabel('Notes'), index: 10),
            const SizedBox(height: 8),
            ...p.notes.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.date, style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(n.text, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          OdinAnimations.fadeUp(
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleWatchlist,
                    icon: Icon(p.inWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                    label: Text(p.inWatchlist ? 'Retirer watchlist' : 'Ajouter watchlist'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.go('/scout/report?prospectId=${p.id}');
                    },
                    icon: const Icon(Icons.assignment_rounded),
                    label: const Text('Rapport'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            index: 11,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.accent)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
      ],
    );
  }
}

/// Route wrapper — reads id from GoRouter pathParameters.
class ScoutProspectRouteScreen extends StatelessWidget {
  const ScoutProspectRouteScreen({super.key, required this.state});

  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    final id = state.pathParameters['id'] ?? '';
    return ScoutProspectScreen(prospectId: id);
  }
}
