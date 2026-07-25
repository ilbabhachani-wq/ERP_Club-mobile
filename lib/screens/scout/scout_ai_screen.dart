import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../models/scout_models.dart';
import '../../providers/scout_provider.dart';

class ScoutAiScreen extends StatefulWidget {
  const ScoutAiScreen({super.key});

  @override
  State<ScoutAiScreen> createState() => _ScoutAiScreenState();
}

class _ScoutAiScreenState extends State<ScoutAiScreen> {
  final _queryCtrl = TextEditingController();
  final _focus = FocusNode();
  List<String> _suggestions = const [
    'Cherche un BU ≤21 ans, potentiel >85, budget <1.5M',
    'Meilleur MC créateur en Afrique du Nord',
    'DC rapide avec bon jeu aérien ≤24 ans',
    'Ailier gauche technique contrat libre ou <1M',
    'Top 3 profils immédiatement disponibles',
    'Qui a le meilleur rapport potentiel / valeur ?',
  ];
  List<ScoutAiHit> _results = [];
  String _summary = '';
  String _lastQuery = '';
  bool _loadingMeta = true;
  bool _searching = false;
  bool _ran = false;
  String? _error;
  String? _expandedId;
  String _season = '2026-2027';
  int _flashscorePlayers = 800;
  int _prospects = 0;

  static const _rankColors = [
    Color(0xFFF59E0B),
    AppColors.accent,
    Color(0xFF3B82F6),
    AppColors.success,
    Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMeta());
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final meta = await context.read<ScoutDataProvider>().api.getAiMeta();
      final raw = meta['suggestedQueries'] ?? meta['queries'] ?? meta['examples'];
      if (raw is List && raw.isNotEmpty) {
        _suggestions = raw.map((e) => e.toString()).toList();
      }
      _season = meta['season']?.toString() ?? _season;
      final summary = meta['summary'];
      if (summary is Map) {
        _flashscorePlayers = (summary['flashscorePlayers'] as num?)?.toInt() ?? _flashscorePlayers;
        _prospects = (summary['prospects'] as num?)?.toInt() ?? _prospects;
      }
    } catch (_) {
      /* keep defaults */
    } finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _search([String? query]) async {
    final q = (query ?? _queryCtrl.text).trim();
    if (q.isEmpty || _searching) return;
    HapticFeedback.mediumImpact();
    _focus.unfocus();
    setState(() {
      _queryCtrl.text = q;
      _searching = true;
      _error = null;
      _ran = false;
      _results = [];
      _summary = '';
      _lastQuery = q;
      _expandedId = null;
    });
    try {
      final hits = await context.read<ScoutDataProvider>().api.searchAi(q);
      if (mounted) {
        setState(() {
          _results = hits;
          _ran = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
        children: [
          OdinAnimations.fadeUp(_buildHeader(), index: 0),
          const SizedBox(height: 16),
          OdinAnimations.fadeUp(_buildSearchCard(), index: 1),
          if (_error != null) ...[
            const SizedBox(height: 12),
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                ],
              ),
            ),
          ],
          if (_searching) ...[
            const SizedBox(height: 14),
            OdinAnimations.scaleIn(_buildLoadingCard()),
          ],
          if (_ran && _results.isNotEmpty && !_searching) ...[
            const SizedBox(height: 16),
            if (_summary.isNotEmpty) ...[
              GlassCard(child: Text(_summary, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4))),
              const SizedBox(height: 12),
            ],
            Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                children: [
                  TextSpan(text: '${_results.length} résultats pour '),
                  TextSpan(
                    text: '"$_lastQuery"',
                    style: const TextStyle(color: AppColors.accent, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(_results.length, (i) => _buildResultCard(_results[i], i)),
          ] else if (!_searching && !_ran) ...[
            const SizedBox(height: 14),
            OdinAnimations.fadeUp(
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(Icons.psychology_outlined, size: 40, color: AppColors.accent.withValues(alpha: 0.25)),
                      const SizedBox(height: 10),
                      Text(
                        'Utilisez une requête rapide ou tapez votre critère',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.55)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'L\'IA analyse votre effectif, budget et besoins',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                      ),
                    ],
                  ),
                ),
              ),
              index: 3,
            ),
          ] else if (_ran && _results.isEmpty && !_searching) ...[
            const SizedBox(height: 14),
            SaasEmptyState(
              title: 'Aucun résultat',
              subtitle: 'Affinez votre requête ou essayez une suggestion',
              icon: Icons.search_off_rounded,
              onAction: () => _search(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.accent, Color(0xFF4F46E5)],
            ),
            boxShadow: [
              BoxShadow(color: AppColors.accent.withValues(alpha: 0.4), blurRadius: 20),
            ],
          ),
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ODIN AI Scout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                _loadingMeta
                    ? 'Recherche en langage naturel'
                    : 'Flashscore $_season · $_flashscorePlayers+ joueurs · $_prospects prospects',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return GlassCard(
      accentColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Décrivez le profil recherché en langage naturel',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Icon(Icons.psychology_outlined, size: 18, color: AppColors.accent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _queryCtrl,
                          focusNode: _focus,
                          maxLines: 2,
                          minLines: 1,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Ex: Cherche un BU ≤21 ans, potentiel >85, budget <1.5M €',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.28)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _searching ? null : () => _search(),
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: _searching
                            ? [Colors.white24, Colors.white12]
                            : const [AppColors.accent, Color(0xFF4F46E5)],
                      ),
                      boxShadow: [
                        BoxShadow(color: AppColors.accent.withValues(alpha: 0.35), blurRadius: 14),
                      ],
                    ),
                    child: SizedBox(
                      height: 52,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: _searching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.send_rounded, size: 16, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Lancer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!_loadingMeta && _suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestions.take(6).map((s) {
                return InkWell(
                  onTap: () => _search(s),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 12, color: AppColors.accent.withValues(alpha: 0.9)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            s,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF4F46E5)]),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            const Text('ODIN analyse Flashscore…', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: ['Recherche', 'Scoring', 'Classement', 'Analyse']
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(s, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.accent)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ScoutAiHit hit, int i) {
    final rankColor = _rankColors[i % _rankColors.length];
    final expanded = _expandedId == hit.id;

    return OdinAnimations.fadeUp(
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xE00C091E),
            border: Border.all(color: rankColor.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (hit.inDatabase) context.go('/scout/prospect/${hit.id}');
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ScoutPlayerAvatar(name: hit.name, photoUrl: hit.photoUrl, flag: hit.flag, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${hit.flag.isNotEmpty ? '${hit.flag} ' : ''}${hit.name}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${hit.position} · ${hit.age} ans · ${hit.club}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: rankColor.withValues(alpha: 0.1),
                              border: Border.all(color: rankColor, width: 3),
                              boxShadow: [BoxShadow(color: rankColor.withValues(alpha: 0.25), blurRadius: 12)],
                            ),
                            child: Center(
                              child: Text(
                                '${hit.compatibility}%',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: rankColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('Match IA', style: TextStyle(fontSize: 8, color: Colors.white.withValues(alpha: 0.35))),
                        ],
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () => setState(() => _expandedId = expanded ? null : hit.id),
                        icon: Icon(
                          expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: rankColor,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: rankColor.withValues(alpha: 0.12),
                          minimumSize: const Size(32, 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hit.reasoning.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hit.reasoning.take(3).map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '✓ $r',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.success),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (expanded) ...[
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Analyse complète ODIN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                      const SizedBox(height: 8),
                      ...hit.reasoning.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
                            ),
                            child: Text('✓  $r', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
                          ),
                        ),
                      ),
                      if (hit.recommendation.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(hit.recommendation, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
                      ],
                      if (hit.inDatabase) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => context.go('/scout/prospect/${hit.id}'),
                            style: FilledButton.styleFrom(
                              backgroundColor: rankColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Voir profil complet', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      index: i + 4,
    );
  }
}
