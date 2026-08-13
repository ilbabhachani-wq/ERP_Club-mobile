import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../models/scout_models.dart';
import '../../providers/scout_provider.dart';

class ScoutMissionsScreen extends StatefulWidget {
  const ScoutMissionsScreen({super.key});

  @override
  State<ScoutMissionsScreen> createState() => _ScoutMissionsScreenState();
}

class _ScoutMissionsScreenState extends State<ScoutMissionsScreen> {
  bool _showForm = false;
  bool _submitting = false;

  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'live';
  ScoutProspect? _prospect;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_titleCtrl.text.trim().isEmpty || _dateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titre et date requis'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      final data = context.read<ScoutDataProvider>();
      await data.api.createMission({
        'title': _titleCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'matchType': _type,
        'notes': _notesCtrl.text.trim(),
        if (_prospect != null) ...{
          'prospectId': _prospect!.id,
          'prospectName': _prospect!.name,
        },
      });
      await data.refreshMissions();
      if (mounted) {
        setState(() {
          _showForm = false;
          _titleCtrl.clear();
          _dateCtrl.clear();
          _locationCtrl.clear();
          _notesCtrl.clear();
          _prospect = null;
          _type = 'live';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission créée ✓'), behavior: SnackBarBehavior.floating),
        );
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
    final data = context.watch<ScoutDataProvider>();
    final missions = data.missions;

    return OdinBackdrop(
      child: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.card,
            onRefresh: data.refreshMissions,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.s, AppSpacing.page, AppSpacing.bottomNav),
              children: [
                OdinAnimations.fadeUp(Text('Missions', style: tt.headlineMedium), index: 0),
                OdinAnimations.fadeUp(
                  Text('${missions.length} missions planifiées', style: tt.bodyMedium?.copyWith(color: AppColors.muted)),
                  index: 1,
                ),
                const SizedBox(height: AppSpacing.m),
                if (_showForm) ...[
                  OdinAnimations.fadeUp(
                    GlassCard(
                      accentColor: AppColors.accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Nouvelle mission', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _titleCtrl,
                            decoration: InputDecoration(
                              labelText: 'Titre',
                              filled: true,
                              fillColor: AppColors.bg2,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _dateCtrl,
                            decoration: InputDecoration(
                              labelText: 'Date (YYYY-MM-DD)',
                              filled: true,
                              fillColor: AppColors.bg2,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'live', label: Text('Live'), icon: Icon(Icons.sensors, size: 16)),
                              ButtonSegment(value: 'video', label: Text('Vidéo'), icon: Icon(Icons.videocam, size: 16)),
                              ButtonSegment(value: 'tour', label: Text('Tour'), icon: Icon(Icons.flight, size: 16)),
                            ],
                            selected: {_type},
                            onSelectionChanged: (s) => setState(() => _type = s.first),
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.resolveWith(
                                (states) => states.contains(WidgetState.selected) ? AppColors.accent : AppColors.muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _locationCtrl,
                            decoration: InputDecoration(
                              labelText: 'Lieu',
                              filled: true,
                              fillColor: AppColors.bg2,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<ScoutProspect?>(
                            initialValue: _prospect,
                            decoration: InputDecoration(
                              labelText: 'Prospect (optionnel)',
                              filled: true,
                              fillColor: AppColors.bg2,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            dropdownColor: AppColors.card,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                              ...data.prospects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))),
                            ],
                            onChanged: (p) => setState(() => _prospect = p),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Notes',
                              filled: true,
                              fillColor: AppColors.bg2,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => _showForm = false),
                                  child: const Text('Annuler'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _submitting ? null : _create,
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                                  child: _submitting
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text('Créer'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    index: 2,
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],
                if (missions.isEmpty && !_showForm)
                  SaasEmptyState(
                    title: 'Aucune mission',
                    subtitle: 'Planifiez votre prochain déplacement terrain',
                    icon: Icons.flag_outlined,
                    actionLabel: 'Créer',
                    onAction: () => setState(() => _showForm = true),
                  )
                else
                  ...List.generate(missions.length, (i) {
                    final m = missions[i];
                    return OdinAnimations.fadeUp(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.flag_rounded, color: AppColors.accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                    Text(
                                      '${m.date}${m.time != null ? ' · ${m.time}' : ''}',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                    ),
                                    if (m.location?.isNotEmpty == true)
                                      Text(m.location!, style: TextStyle(color: AppColors.accent.withValues(alpha: 0.8), fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      index: i + 3,
                    );
                  }),
              ],
            ),
          ),
          Positioned(
            right: AppSpacing.page,
            bottom: AppSpacing.fabBottom(context),
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => _showForm = !_showForm);
              },
              backgroundColor: AppColors.accent,
              child: Icon(_showForm ? Icons.close_rounded : Icons.add_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
