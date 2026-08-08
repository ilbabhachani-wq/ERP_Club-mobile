import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/club_logo.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/analyste_provider.dart';

/// Opponent Intel — plan de match (aligné AnalysteAdversairePage).
class AnalysteOpponentScreen extends StatefulWidget {
  const AnalysteOpponentScreen({super.key});

  static const accent = Color(0xFFFF6B57);

  @override
  State<AnalysteOpponentScreen> createState() => _AnalysteOpponentScreenState();
}

class _AnalysteOpponentScreenState extends State<AnalysteOpponentScreen> {
  Map<String, dynamic>? _data;
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
      final data = await context.read<AnalysteDataProvider>().api.getOpponent();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return OdinBackdrop(
      child: RefreshIndicator(
        color: AnalysteOpponentScreen.accent,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            if (_loading)
              Shimmer.fromColors(
                baseColor: Colors.white.withValues(alpha: 0.06),
                highlightColor: Colors.white.withValues(alpha: 0.14),
                child: Column(
                  children: List.generate(
                    4,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: SaasCardSkeleton(height: 88),
                    ),
                  ),
                ),
              )
            else if (_error != null)
              GlassCard(
                child: SaasEmptyState(
                  icon: Icons.shield_outlined,
                  title: 'Intel indisponible',
                  subtitle: _error!,
                  actionLabel: 'Réessayer',
                  onAction: _load,
                  compact: true,
                ),
              )
            else
              ..._buildContent(tt),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(TextTheme tt) {
    final raw = _data?['intel'];
    if (raw is! Map) {
      return [
        const GlassCard(
          child: SaasEmptyState(
            icon: Icons.shield_outlined,
            title: 'Aucune intel',
            subtitle: 'Les données adversaire seront synchronisées bientôt',
            compact: true,
          ),
        ),
      ];
    }
    final intel = _Intel.fromJson(Map<String, dynamic>.from(raw));
    final attacks = [
      _Attack('Gauche', intel.leftPct, const Color(0xFFEF4444)),
      _Attack('Centre', intel.centerPct, const Color(0xFFF59E0B)),
      _Attack('Droit', intel.rightPct, const Color(0xFF6366F1)),
    ];

    return [
      OdinAnimations.fadeUp(
        Row(
          children: [
            ClubLogo(
              clubName: intel.name,
              size: 48,
              radius: 14,
              padding: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.92),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Opponent Intel', style: tt.headlineMedium),
                  Text(
                    '${intel.name} · Plan de match IA',
                    style: tt.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        index: 0,
      ),
      const SizedBox(height: AppSpacing.m),

      // Plan IA + advice chips
      OdinAnimations.fadeUp(
        GlassCard(
          raised: true,
          accentColor: const Color(0xFF8B5CF6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.gps_fixed_rounded, size: 16, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 8),
                  Text('Plan de match IA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${intel.name} attaque ${intel.leftPct}% gauche, ${intel.centerPct}% centre, ${intel.rightPct}% droite.',
                style: TextStyle(fontSize: 13, height: 1.4, color: OdinColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: intel.advice
                    .map(
                      (a) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          a,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFC4B5FD)),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        index: 1,
      ),
      const SizedBox(height: 14),

      // Attack distribution
      OdinAnimations.fadeUp(const SectionTitle('Répartition attaques'), index: 2),
      const SizedBox(height: 8),
      OdinAnimations.fadeUp(
        GlassCard(
          child: Column(
            children: [
              for (final a in attacks) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(a.zone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: a.pct / 100),
                          duration: 800.ms,
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 14,
                            backgroundColor: Colors.white.withValues(alpha: 0.06),
                            color: a.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${a.pct}%', style: TextStyle(fontWeight: FontWeight.w900, color: a.color)),
                  ],
                ),
                if (a != attacks.last) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        index: 3,
      ),
      const SizedBox(height: 14),

      // Danger zones
      OdinAnimations.fadeUp(const SectionTitle('Zones dangereuses'), index: 4),
      const SizedBox(height: 8),
      OdinAnimations.fadeUp(
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            for (final z in intel.dangerZones)
              GlassCard(
                padding: const EdgeInsets.all(14),
                accentColor: Color.fromRGBO(239, 68, 68, (z.intensity / 200).clamp(0.15, 0.55)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      z.zone,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${z.intensity}%',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: _threatColor(z.intensity),
                      ),
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.85, end: 1, duration: 1600.ms),
          ],
        ),
        index: 5,
      ),
      const SizedBox(height: 14),

      // Key players
      OdinAnimations.fadeUp(const SectionTitle('Joueurs clés'), index: 6),
      const SizedBox(height: 8),
      ...List.generate(intel.keyPlayers.length, (i) {
        final p = intel.keyPlayers[i];
        return OdinAnimations.fadeUp(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _threatColor(p.threat).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      p.role,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _threatColor(p.threat)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: TextStyle(fontWeight: FontWeight.w800)),
                        Text(p.role, style: TextStyle(fontSize: 11, color: OdinColors.textMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${p.threat}',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _threatColor(p.threat)),
                      ),
                       Text('Menace', style: TextStyle(fontSize: 9, color: OdinColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          index: 7 + i,
        );
      }),
      const SizedBox(height: 6),

      // Weaknesses
      OdinAnimations.fadeUp(const SectionTitle('Faiblesses'), index: 12),
      const SizedBox(height: 8),
      OdinAnimations.fadeUp(
        GlassCard(
          accentColor: const Color(0xFFF59E0B),
          child: Column(
            children: [
              for (final w in intel.weaknesses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(w, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        index: 13,
      ),
    ];
  }
}

class _Intel {
  const _Intel({
    required this.name,
    required this.leftPct,
    required this.centerPct,
    required this.rightPct,
    required this.advice,
    required this.keyPlayers,
    required this.weaknesses,
    required this.dangerZones,
  });

  final String name;
  final int leftPct;
  final int centerPct;
  final int rightPct;
  final List<String> advice;
  final List<_KeyPlayer> keyPlayers;
  final List<String> weaknesses;
  final List<_DangerZone> dangerZones;

  factory _Intel.fromJson(Map<String, dynamic> json) {
    return _Intel(
      name: json['name']?.toString() ?? 'Adversaire',
      leftPct: (json['leftPct'] as num?)?.round() ?? 0,
      centerPct: (json['centerPct'] as num?)?.round() ?? 0,
      rightPct: (json['rightPct'] as num?)?.round() ?? 0,
      advice: (json['advice'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      keyPlayers: (json['keyPlayers'] as List?)
              ?.whereType<Map>()
              .map((e) => _KeyPlayer.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      weaknesses: (json['weaknesses'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      dangerZones: (json['dangerZones'] as List?)
              ?.whereType<Map>()
              .map((e) => _DangerZone.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

class _KeyPlayer {
  const _KeyPlayer({required this.name, required this.role, required this.threat});
  final String name;
  final String role;
  final int threat;

  factory _KeyPlayer.fromJson(Map<String, dynamic> json) {
    return _KeyPlayer(
      name: json['name']?.toString() ?? '—',
      role: json['role']?.toString() ?? '—',
      threat: (json['threat'] as num?)?.round() ?? 0,
    );
  }
}

class _DangerZone {
  const _DangerZone({required this.zone, required this.intensity});
  final String zone;
  final int intensity;

  factory _DangerZone.fromJson(Map<String, dynamic> json) {
    return _DangerZone(
      zone: json['zone']?.toString() ?? 'Zone',
      intensity: (json['intensity'] as num?)?.round() ?? 0,
    );
  }
}

class _Attack {
  const _Attack(this.zone, this.pct, this.color);
  final String zone;
  final int pct;
  final Color color;
}

Color _threatColor(int v) {
  if (v >= 85) return const Color(0xFFEF4444);
  if (v >= 70) return const Color(0xFFFF7A00);
  if (v >= 50) return const Color(0xFFF59E0B);
  return const Color(0xFF22C55E);
}
