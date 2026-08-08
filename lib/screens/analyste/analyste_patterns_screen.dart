import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/analyste_provider.dart';

/// Patterns IA — Deep Learning insights (aligné web AnalystePatternsPage).
class AnalystePatternsScreen extends StatefulWidget {
  const AnalystePatternsScreen({super.key});

  static const accent = Color(0xFFA855F7);

  @override
  State<AnalystePatternsScreen> createState() => _AnalystePatternsScreenState();
}

class _AnalystePatternsScreenState extends State<AnalystePatternsScreen> {
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
      final data = await context.read<AnalysteDataProvider>().api.getPatterns();
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
        color: AnalystePatternsScreen.accent,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AnalystePatternsScreen.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.auto_awesome, color: AnalystePatternsScreen.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patterns IA', style: tt.headlineMedium),
                        Text(
                          'Deep Learning · Confiance > 75%',
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
                  icon: Icons.auto_awesome,
                  title: 'Patterns indisponibles',
                  subtitle: _error!,
                  actionLabel: 'Réessayer',
                  onAction: _load,
                  compact: true,
                ),
              )
            else
              ..._buildContent(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final data = _data ?? {};
    final summary = data['summary']?.toString() ?? '';
    final patterns = (data['patterns'] as List?)
            ?.whereType<Map>()
            .map((e) => _Pattern.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <_Pattern>[];

    final byCat = <String, int>{};
    for (final p in patterns) {
      byCat[p.category] = (byCat[p.category] ?? 0) + 1;
    }
    final avgConf = patterns.isEmpty
        ? 0
        : (patterns.map((p) => p.confidence).reduce((a, b) => a + b) / patterns.length).round();

    return [
      if (summary.isNotEmpty)
        OdinAnimations.fadeUp(
          GlassCard(
            raised: true,
            accentColor: AnalystePatternsScreen.accent,
            child: Text(
              summary,
              style: TextStyle(fontSize: 13, height: 1.45, color: OdinColors.textSecondary),
            ),
          ),
          index: 1,
        ),
      const SizedBox(height: 12),
      OdinAnimations.fadeUp(
        Row(
          children: [
            Expanded(
              child: _MiniKpi(label: 'Patterns', value: '${patterns.length}', color: AnalystePatternsScreen.accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniKpi(label: 'Confiance moy.', value: '$avgConf%', color: const Color(0xFF22C55E)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniKpi(
                label: 'Catégories',
                value: '${byCat.length}',
                color: const Color(0xFF38BDF8),
              ),
            ),
          ],
        ),
        index: 2,
      ),
      const SizedBox(height: 16),
      OdinAnimations.fadeUp(const SectionTitle('Patterns détectés'), index: 3),
      const SizedBox(height: 8),
      if (patterns.isEmpty)
        const GlassCard(
          child: SaasEmptyState(
            icon: Icons.insights_outlined,
            title: 'Aucun pattern',
            subtitle: 'Les détections apparaîtront après synchronisation',
            compact: true,
          ),
        )
      else
        ...List.generate(patterns.length, (i) {
          final p = patterns[i];
          final cfg = _categoryConfig(p.category);
          return OdinAnimations.fadeUp(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                accentColor: cfg.color,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cfg.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(cfg.icon, color: cfg.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cfg.color.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      cfg.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: cfg.color,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${p.confidence}% confiance',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: cfg.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p.text,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: p.confidence / 100),
                        duration: Duration(milliseconds: 700 + i * 80),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          color: cfg.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            index: 4 + i,
          );
        }),
    ];
  }
}

class _Pattern {
  const _Pattern({
    required this.text,
    required this.confidence,
    required this.category,
  });

  final String text;
  final int confidence;
  final String category;

  factory _Pattern.fromJson(Map<String, dynamic> json) {
    return _Pattern(
      text: json['pattern']?.toString() ??
          json['title']?.toString() ??
          json['name']?.toString() ??
          json['description']?.toString() ??
          'Pattern',
      confidence: (json['confidence'] as num?)?.round() ??
          (json['score'] as num?)?.round() ??
          0,
      category: json['category']?.toString() ?? json['type']?.toString() ?? 'performance',
    );
  }
}

class _CatCfg {
  const _CatCfg(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

_CatCfg _categoryConfig(String category) {
  switch (category.toLowerCase()) {
    case 'injury':
    case 'blessure':
      return const _CatCfg('Blessure', Color(0xFFEF4444), Icons.healing_rounded);
    case 'tactical':
    case 'tactique':
      return const _CatCfg('Tactique', Color(0xFF6366F1), Icons.gps_fixed_rounded);
    case 'performance':
    default:
      return const _CatCfg('Performance', Color(0xFFA855F7), Icons.psychology_rounded);
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
