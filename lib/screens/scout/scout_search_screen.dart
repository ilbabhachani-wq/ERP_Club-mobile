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

class ScoutSearchScreen extends StatefulWidget {
  const ScoutSearchScreen({super.key});

  @override
  State<ScoutSearchScreen> createState() => _ScoutSearchScreenState();
}

class _ScoutSearchScreenState extends State<ScoutSearchScreen> {
  static const _positions = ['Tous', 'BU', 'MC', 'DC', 'Ailier G', 'DG', 'DD', 'GK'];
  static const _countries = ['Tous', 'Tunisie', 'Algérie', 'Maroc', 'Côte d\'Ivoire', 'Sénégal'];
  static const _ages = ['Tous', '≤18', '19-21', '22-25', '>25'];
  static const _potentials = ['Tous', '≥85', '78-84', '<78'];
  static const _budgets = ['Tous', '<500K €', '500K-1M €', '1M-2M €', '>2M €'];

  final _queryCtrl = TextEditingController();

  String _position = 'Tous';
  String _country = 'Tous';
  String _age = 'Tous';
  String _potential = 'Tous';
  String _budget = 'Tous';

  bool _searching = false;
  ScoutSearchResponse? _response;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  ScoutSearchFilters _buildFilters() {
    return ScoutSearchFilters(
      query: _queryCtrl.text.trim(),
      position: _position == 'Tous' ? null : _position,
      country: _country == 'Tous' ? null : _country,
      ageBand: _age == 'Tous' ? null : _age,
      potentialBand: _potential == 'Tous' ? null : _potential,
      budgetBand: _budget == 'Tous' ? null : _budget,
    );
  }

  Future<void> _search() async {
    HapticFeedback.mediumImpact();
    setState(() => _searching = true);
    try {
      final api = context.read<ScoutDataProvider>().api;
      final res = await api.searchProspects(_buildFilters());
      if (mounted) setState(() => _response = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recherche échouée: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onResultTap(ScoutSearchResult r) {
    HapticFeedback.selectionClick();
    if (r.inDatabase) {
      context.go('/scout/prospect/${r.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${r.name} n\'est pas encore dans l\'annuaire'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.card,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final results = _response?.results ?? [];

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
        children: [
          OdinAnimations.fadeUp(Text('Recherche', style: tt.headlineMedium), index: 0),
          OdinAnimations.fadeUp(
            Text('Filtres avancés & IA', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
            index: 1,
          ),
          const SizedBox(height: AppSpacing.m),
          OdinAnimations.fadeUp(
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    style: TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: 'Nom, club, position…',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _searching ? null : _search,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _searching
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded),
                ),
              ],
            ),
            index: 2,
          ),
          const SizedBox(height: AppSpacing.m),
          ...[
            ('Position', _positions, _position, (v) => setState(() => _position = v)),
            ('Pays', _countries, _country, (v) => setState(() => _country = v)),
            ('Âge', _ages, _age, (v) => setState(() => _age = v)),
            ('Potentiel', _potentials, _potential, (v) => setState(() => _potential = v)),
            ('Budget', _budgets, _budget, (v) => setState(() => _budget = v)),
          ].asMap().entries.map((e) {
            final (label, options, value, onChange) = e.value;
            return OdinAnimations.fadeUp(
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChipGroup(label: label, options: options, value: value, onChange: onChange),
              ),
              index: 3 + e.key,
            );
          }),
          if (_response != null) ...[
            const SizedBox(height: 8),
            OdinAnimations.fadeUp(
              ScoutSectionLabel('Résultats (${results.length})'),
              index: 9,
            ),
            if (_response!.summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(_response!.summary, style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
            if (results.isEmpty)
              SaasEmptyState(
                title: 'Aucun résultat',
                subtitle: 'Modifiez vos filtres ou votre requête',
                icon: Icons.person_search_rounded,
                onAction: _search,
                compact: true,
              )
            else
              ...List.generate(results.length, (i) {
                final r = results[i];
                return OdinAnimations.fadeUp(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      onTap: () => _onResultTap(r),
                      child: Row(
                        children: [
                          ScoutPlayerAvatar(name: r.name, photoUrl: r.photoUrl, flag: r.flag, size: 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                Text(
                                  '${r.position} · ${r.age} ans · ${r.club}',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: (r.potential >= 85 ? AppColors.success : AppColors.accent).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${r.potential}',
                              style: TextStyle(
                                color: r.potential >= 85 ? AppColors.success : AppColors.accent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  index: 10 + i,
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.options,
    required this.value,
    required this.onChange,
  });

  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options.map((opt) {
            final selected = value == opt;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChange(opt);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected ? AppColors.accent : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
