import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/analyste_provider.dart';

/// Écran générique pour modules analyste (chemistry, patterns, fatigue…).
class AnalysteModuleScreen extends StatefulWidget {
  const AnalysteModuleScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.loader,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Future<Map<String, dynamic>> Function(AnalysteDataProvider) loader;

  @override
  State<AnalysteModuleScreen> createState() => _AnalysteModuleScreenState();
}

class _AnalysteModuleScreenState extends State<AnalysteModuleScreen> {
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
      final provider = context.read<AnalysteDataProvider>();
      final data = await widget.loader(provider);
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
        color: widget.accent,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(
              Text(widget.title, style: tt.headlineMedium),
              index: 0,
            ),
            OdinAnimations.fadeUp(
              Text(widget.subtitle, style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
              index: 1,
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
                      child: SaasCardSkeleton(height: 88),
                    ),
                  ),
                ),
              )
            else if (_error != null)
              GlassCard(
                child: SaasEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Impossible de charger',
                  subtitle: _error!,
                  actionLabel: 'Réessayer',
                  onAction: _load,
                  compact: true,
                ),
              )
            else
              ..._buildCards(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCards() {
    final data = _data ?? {};
    final cards = <Widget>[];

    void addSection(String title, List<Widget> children) {
      if (children.isEmpty) return;
      cards.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SectionTitle(title),
      ));
      cards.addAll(children);
      cards.add(const SizedBox(height: 8));
    }

    final patterns = data['patterns'] as List<dynamic>?;
    if (patterns != null) {
      addSection(
        'Patterns',
        patterns.take(12).whereType<Map<String, dynamic>>().map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              accentColor: widget.accent,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['pattern']?.toString() ??
                        p['title']?.toString() ??
                        p['name']?.toString() ??
                        'Pattern',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if ((p['confidence'] ?? p['score']) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${p['confidence'] ?? p['score']}% confiance',
                        style: TextStyle(color: widget.accent, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  if ((p['description'] ?? p['desc']) != null)
                    Text(
                      '${p['description'] ?? p['desc']}',
                      style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    final summary = data['summary'];
    if (summary is Map<String, dynamic>) {
      addSection('Résumé', [
        GlassCard(
          raised: true,
          accentColor: widget.accent,
          child: Column(
            children: [
              for (final e in summary.entries.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(e.key, style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _prettyValue(e.value),
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ]);
    } else if (summary is String && summary.isNotEmpty) {
      cards.add(GlassCard(child: Text(summary, style: const TextStyle(fontSize: 13, height: 1.4))));
      cards.add(const SizedBox(height: 8));
    }

    final kpis = data['kpis'] as List<dynamic>?;
    if (kpis != null) {
      addSection(
        'KPIs',
        kpis.take(10).whereType<Map<String, dynamic>>().map((k) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      k['label']?.toString() ?? k['name']?.toString() ?? 'KPI',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${k['value'] ?? k['score'] ?? '—'}',
                    style: TextStyle(fontWeight: FontWeight.w900, color: widget.accent, fontSize: 18),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    final preds = data['predictions'] as List<dynamic>?;
    if (preds != null) {
      addSection(
        'Prédictions',
        preds.take(12).whereType<Map<String, dynamic>>().map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              accentColor: OdinColors.danger,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['player']?.toString() ?? p['name']?.toString() ?? 'Joueur',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    p['risk']?.toString() ?? p['injury']?.toString() ?? p['type']?.toString() ?? '',
                    style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    final intel = data['intel'] as Map<String, dynamic>?;
    if (intel != null) {
      addSection('Intel', [
        GlassCard(
          raised: true,
          accentColor: widget.accent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final e in intel.entries.take(12))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ]);
    }

    final recos = data['recommendations'] as List<dynamic>?;
    if (recos != null) {
      addSection(
        'Recommandations IA',
        recos.take(8).map((r) {
          final text = r is Map
              ? (r['title'] ?? r['text'] ?? r['description'] ?? r).toString()
              : r.toString();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(child: Text(text, style: const TextStyle(fontSize: 13))),
          );
        }).toList(),
      );
    }

    if (cards.isEmpty) {
      cards.add(
        const GlassCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Données chargées', style: TextStyle(color: OdinColors.textMuted)),
            ),
          ),
        ),
      );
      for (final e in data.entries.take(8)) {
        if (e.value is List || e.value is Map) continue;
        cards.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: Text('${e.key}', style: const TextStyle(color: OdinColors.textMuted))),
                  Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        );
      }
    }

    return cards;
  }

  String _prettyValue(dynamic v) {
    if (v == null) return '—';
    if (v is num || v is bool || v is String) return '$v';
    if (v is Map) {
      final a = v['a'];
      final b = v['b'];
      final score = v['score'];
      if (a != null && b != null) {
        return score != null ? '$a ↔ $b ($score)' : '$a ↔ $b';
      }
      if (v['label'] != null && v['value'] != null) return '${v['label']}: ${v['value']}';
      if (v['name'] != null) return '${v['name']}${v['score'] != null ? ' · ${v['score']}' : ''}';
      return v.entries.take(3).map((e) => '${e.key}: ${e.value}').join(' · ');
    }
    if (v is List) {
      if (v.isEmpty) return '—';
      return v.take(4).map(_prettyValue).join(', ');
    }
    return v.toString();
  }
}
