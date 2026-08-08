import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../models/scout_models.dart';
import '../../providers/scout_provider.dart';

class ScoutReportScreen extends StatefulWidget {
  const ScoutReportScreen({super.key, this.initialProspectId});

  final String? initialProspectId;

  @override
  State<ScoutReportScreen> createState() => _ScoutReportScreenState();
}

class _ScoutReportScreenState extends State<ScoutReportScreen> {
  static const _decisions = [
    ('recruit', 'Recruter', AppColors.success),
    ('observe', 'Observer', Color(0xFFF59E0B)),
    ('shortlist', 'Shortlist', Color(0xFF3B82F6)),
    ('refuse', 'Refuser', AppColors.danger),
  ];

  ScoutProspect? _selected;
  String _decision = 'observe';
  bool _submitting = false;

  final _matchCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _opponentCtrl = TextEditingController();
  final _strengthsCtrl = TextEditingController();
  final _weaknessesCtrl = TextEditingController();
  final _recommendationCtrl = TextEditingController();

  double _technique = 50;
  double _physique = 50;
  double _mental = 50;
  double _tactique = 50;
  double _vitesse = 50;

  int get _aiScore => ((_technique + _physique + _mental + _tactique + _vitesse) / 5).round();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<ScoutDataProvider>();
      if (widget.initialProspectId != null) {
        _selected = data.prospects.cast<ScoutProspect?>().firstWhere(
              (p) => p!.id == widget.initialProspectId,
              orElse: () => null,
            );
        if (_selected != null) {
          _technique = _selected!.dribble.toDouble().clamp(0, 100);
          _physique = _selected!.physical.toDouble().clamp(0, 100);
          _mental = _selected!.mental.toDouble().clamp(0, 100);
          _tactique = ((_selected!.defense + _selected!.passing) / 2).clamp(0, 100);
          _vitesse = _selected!.speed.toDouble().clamp(0, 100);
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _matchCtrl.dispose();
    _dateCtrl.dispose();
    _opponentCtrl.dispose();
    _strengthsCtrl.dispose();
    _weaknessesCtrl.dispose();
    _recommendationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un prospect'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      final data = context.read<ScoutDataProvider>();
      await data.api.createReport({
        'prospectId': _selected!.id,
        'prospectName': _selected!.name,
        'matchDate': _dateCtrl.text.trim(),
        'matchObserved': _matchCtrl.text.trim(),
        'opponent': _opponentCtrl.text.trim(),
        'technique': _technique.round(),
        'physique': _physique.round(),
        'mental': _mental.round(),
        'tactique': _tactique.round(),
        'vitesse': _vitesse.round(),
        'strengths': _strengthsCtrl.text.trim(),
        'weaknesses': _weaknessesCtrl.text.trim(),
        'recommendation': _recommendationCtrl.text.trim(),
        'decision': _decision,
        'aiScore': _aiScore,
      });
      await data.refreshReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapport ${_selected!.name} envoyé ✓'), behavior: SnackBarBehavior.floating),
        );
        context.go('/scout/reports');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final prospects = context.watch<ScoutDataProvider>().prospects;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
        children: [
          OdinAnimations.fadeUp(Text('Nouveau rapport', style: tt.headlineMedium), index: 0),
          OdinAnimations.fadeUp(
            Text('Évaluation terrain', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
            index: 1,
          ),
          const SizedBox(height: AppSpacing.m),
          OdinAnimations.fadeUp(
            DropdownButtonFormField<ScoutProspect>(
              initialValue: _selected,
              decoration: InputDecoration(
                labelText: 'Prospect',
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              dropdownColor: AppColors.card,
              items: prospects
                  .map((p) => DropdownMenuItem(value: p, child: Text('${p.flag} ${p.name} · ${p.position}')))
                  .toList(),
              onChanged: (p) => setState(() => _selected = p),
            ),
            index: 2,
          ),
          const SizedBox(height: 12),
          ...[
            ('Match observé', _matchCtrl),
            ('Date', _dateCtrl),
            ('Adversaire', _opponentCtrl),
          ].map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: field.$2,
                  decoration: InputDecoration(
                    labelText: field.$1,
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          OdinAnimations.fadeUp(
            GlassCard(
              accentColor: AppColors.accent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Text('Score IA: $_aiScore/100', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
            ),
            index: 3,
          ),
          const SizedBox(height: 12),
          ...[
            ('Technique', _technique, (v) => setState(() => _technique = v)),
            ('Physique', _physique, (v) => setState(() => _physique = v)),
            ('Mental', _mental, (v) => setState(() => _mental = v)),
            ('Tactique', _tactique, (v) => setState(() => _tactique = v)),
            ('Vitesse', _vitesse, (v) => setState(() => _vitesse = v)),
          ].map((s) => _SliderField(label: s.$1, value: s.$2, onChanged: s.$3)),
          const SizedBox(height: 8),
          TextField(
            controller: _strengthsCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Points forts',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _weaknessesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Points faibles',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _recommendationCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Recommandation',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _decisions.map((d) {
              final selected = _decision == d.$1;
              return ChoiceChip(
                label: Text(d.$2),
                selected: selected,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _decision = d.$1);
                },
                selectedColor: d.$3.withValues(alpha: 0.25),
                labelStyle: TextStyle(
                  color: selected ? d.$3 : AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(color: selected ? d.$3 : Colors.white.withValues(alpha: 0.1)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: const Text('Soumettre le rapport'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text('${value.round()}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent)),
            ],
          ),
          Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: AppColors.accent,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

/// Reads optional prospectId from query parameters.
class ScoutReportRouteScreen extends StatelessWidget {
  const ScoutReportRouteScreen({super.key, required this.state});

  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    return ScoutReportScreen(initialProspectId: state.uri.queryParameters['prospectId']);
  }
}
