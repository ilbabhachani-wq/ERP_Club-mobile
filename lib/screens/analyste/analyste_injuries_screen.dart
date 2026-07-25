import 'dart:math' as math;
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

/// Injury Lab — prédiction ML 7/14/30j + facteurs (aligné AnalysteBlessuresPage).
class AnalysteInjuriesScreen extends StatefulWidget {
  const AnalysteInjuriesScreen({super.key});

  static const accent = Color(0xFFEF4444);

  @override
  State<AnalysteInjuriesScreen> createState() => _AnalysteInjuriesScreenState();
}

class _AnalysteInjuriesScreenState extends State<AnalysteInjuriesScreen> {
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
      final data = await context.read<AnalysteDataProvider>().api.getInjuries();
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
        color: AnalysteInjuriesScreen.accent,
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
                      color: AnalysteInjuriesScreen.accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.healing_rounded, color: AnalysteInjuriesScreen.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Injury Lab', style: tt.headlineMedium),
                        Text(
                          'Modèle ML — Probabilités 7 / 14 / 30 jours',
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
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: SaasCardSkeleton(height: 140),
                    ),
                  ),
                ),
              )
            else if (_error != null)
              GlassCard(
                child: SaasEmptyState(
                  icon: Icons.healing_outlined,
                  title: 'Prédictions indisponibles',
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
    final predictions = (data['predictions'] as List?)
            ?.whereType<Map>()
            .map((e) => _InjuryPred.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <_InjuryPred>[];

    if (predictions.isEmpty) {
      return [
        const GlassCard(
          child: SaasEmptyState(
            icon: Icons.insights_outlined,
            title: 'Aucune prédiction',
            subtitle: 'Les risques blessure apparaîtront après synchronisation',
            compact: true,
          ),
        ),
      ];
    }

    final highRisk = predictions.where((p) => p.prob7 >= 50).length;
    final avg7 = (predictions.map((p) => p.prob7).reduce((a, b) => a + b) / predictions.length).round();

    return [
      OdinAnimations.fadeUp(
        Row(
          children: [
            Expanded(child: _MiniKpi('Joueurs', '${predictions.length}', AnalysteInjuriesScreen.accent)),
            const SizedBox(width: 10),
            Expanded(child: _MiniKpi('Risque élevé', '$highRisk', const Color(0xFFFF7A00))),
            const SizedBox(width: 10),
            Expanded(child: _MiniKpi('Moy. 7j', '$avg7%', const Color(0xFFF59E0B))),
          ],
        ),
        index: 1,
      ),
      const SizedBox(height: 16),
      OdinAnimations.fadeUp(const SectionTitle('Prédictions'), index: 2),
      const SizedBox(height: 8),
      ...List.generate(predictions.length, (i) {
        final p = predictions[i];
        return OdinAnimations.fadeUp(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              raised: true,
              accentColor: p.prob7 >= 60
                  ? AnalysteInjuriesScreen.accent
                  : p.prob7 >= 40
                      ? const Color(0xFFFF7A00)
                      : const Color(0xFF22C55E),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text(
                    'FACTEURS CONTRIBUTIFS',
                    style: TextStyle(fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700, color: OdinColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  ...p.factors.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(f.label, style: const TextStyle(fontSize: 12, color: OdinColors.textSecondary)),
                                ),
                                Text('${f.value}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: f.color)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: f.value / 100),
                                duration: Duration(milliseconds: 600 + i * 60),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, _) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                                  color: f.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ProbRing(value: p.prob7, color: const Color(0xFFEF4444), label: '7j'),
                      _ProbRing(value: p.prob14, color: const Color(0xFFF59E0B), label: '14j'),
                      _ProbRing(value: p.prob30, color: const Color(0xFF22C55E), label: '30j'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          index: 3 + i,
        );
      }),
    ];
  }
}

class _InjuryPred {
  const _InjuryPred({
    required this.name,
    required this.prob7,
    required this.prob14,
    required this.prob30,
    required this.factors,
  });

  final String name;
  final int prob7;
  final int prob14;
  final int prob30;
  final List<_Factor> factors;

  factory _InjuryPred.fromJson(Map<String, dynamic> json) {
    final factors = (json['factors'] as List?)
            ?.whereType<Map>()
            .map((e) => _Factor.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <_Factor>[];
    return _InjuryPred(
      name: json['name']?.toString() ?? json['player']?.toString() ?? 'Joueur',
      prob7: (json['prob7'] as num?)?.round() ?? (json['risk'] as num?)?.round() ?? 0,
      prob14: (json['prob14'] as num?)?.round() ?? 0,
      prob30: (json['prob30'] as num?)?.round() ?? 0,
      factors: factors,
    );
  }
}

class _Factor {
  const _Factor({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  factory _Factor.fromJson(Map<String, dynamic> json) {
    return _Factor(
      label: json['label']?.toString() ?? 'Facteur',
      value: (json['value'] as num?)?.round() ?? 0,
      color: _parseColor(json['color']?.toString()) ?? const Color(0xFFEF4444),
    );
  }
}

Color? _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  if (v == null) return null;
  return Color(v);
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi(this.label, this.value, this.color);
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
          Text(label, style: const TextStyle(fontSize: 10, color: OdinColors.textMuted)),
        ],
      ),
    );
  }
}

class _ProbRing extends StatelessWidget {
  const _ProbRing({required this.value, required this.color, required this.label});
  final int value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 68,
          height: 68,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value / 100),
            duration: 900.ms,
            curve: Curves.easeOutCubic,
            builder: (_, t, _) => CustomPaint(
              painter: _RingPainter(progress: t, color: color),
              child: Center(
                child: Text(
                  '$value%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: OdinColors.textMuted)),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2 - 4;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
