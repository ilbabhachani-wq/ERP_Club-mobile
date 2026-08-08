import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/animations/odin_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/saas_widgets.dart';
import '../../providers/preparateur_provider.dart';
import '../../services/preparateur_api.dart';

class PrepProgrammesScreen extends StatefulWidget {
  const PrepProgrammesScreen({super.key});

  @override
  State<PrepProgrammesScreen> createState() => _PrepProgrammesScreenState();
}

class _PrepProgrammesScreenState extends State<PrepProgrammesScreen> {
  String _search = '';

  Color _statusColor(String status) {
    switch (status) {
      case 'envoye':
        return const Color(0xFFF59E0B);
      case 'valide':
        return AppColors.success;
      case 'refuse':
        return AppColors.danger;
      default:
        return AppColors.muted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'envoye':
        return 'Envoyé';
      case 'valide':
        return 'Validé';
      case 'refuse':
        return 'Refusé';
      default:
        return 'Brouillon';
    }
  }

  Color _intensityColor(String intensity) {
    switch (intensity) {
      case 'Haute':
        return AppColors.danger;
      case 'Basse':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _showCreateSheet() async {
    final data = context.read<PreparateurDataProvider>();
    final nameCtrl = TextEditingController();
    final objectiveCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '4 semaines');
    var intensity = 'Moyenne';
    final selected = <String>{};
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nouveau programme',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom *'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: objectiveCtrl,
                      decoration: const InputDecoration(labelText: 'Objectif'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: durationCtrl,
                      decoration: const InputDecoration(labelText: 'Durée'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: intensity,
                      decoration: const InputDecoration(labelText: 'Intensité'),
                      items: const [
                        DropdownMenuItem(value: 'Basse', child: Text('Basse')),
                        DropdownMenuItem(value: 'Moyenne', child: Text('Moyenne')),
                        DropdownMenuItem(value: 'Haute', child: Text('Haute')),
                      ],
                      onChanged: (v) => setModal(() => intensity = v ?? 'Moyenne'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Joueurs assignés',
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.players.map((p) {
                        final on = selected.contains(p.id);
                        return FilterChip(
                          label: Text(p.name.split(' ').first),
                          selected: on,
                          onSelected: (_) => setModal(() {
                            if (on) {
                              selected.remove(p.id);
                            } else {
                              selected.add(p.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty) return;
                              setModal(() => saving = true);
                              try {
                                await data.createProgram({
                                  'name': nameCtrl.text.trim(),
                                  'objective': objectiveCtrl.text.trim(),
                                  'duration': durationCtrl.text.trim().isEmpty
                                      ? '4 semaines'
                                      : durationCtrl.text.trim(),
                                  'intensity': intensity,
                                  'playerIds': selected.toList(),
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Programme créé')),
                                  );
                                }
                              } catch (e) {
                                setModal(() => saving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('$e')),
                                  );
                                }
                              }
                            },
                      child: Text(saving ? 'Création…' : 'Créer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<PreparateurDataProvider>();
    final filtered = data.programs
        .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    if (data.loading && data.programs.isEmpty) {
      return const OdinBackdrop(child: OdinPageSkeleton());
    }

    return OdinBackdrop(
      child: RefreshIndicator(
        color: const Color(0xFF6366F1),
        backgroundColor: AppColors.card,
        onRefresh: () => data.refreshPrograms(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, AppSpacing.bottomNav),
          children: [
            OdinAnimations.fadeUp(
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Rechercher programme…',
                        prefixIcon: Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showCreateSheet();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Créer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (data.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(data.error!, style: const TextStyle(color: AppColors.danger)),
              ),
            if (filtered.isEmpty)
              SaasEmptyState(
                title: data.programs.isEmpty ? 'Aucun programme' : 'Aucun résultat',
                subtitle: data.programs.isEmpty
                    ? 'Créez un programme physique pour vos joueurs'
                    : 'Essayez un autre mot-clé',
                icon: Icons.fitness_center_rounded,
                onAction: data.programs.isEmpty ? _showCreateSheet : () => data.refreshPrograms(),
                actionLabel: data.programs.isEmpty ? 'Créer' : 'Actualiser',
              )
            else
              ...filtered.asMap().entries.map((e) {
                final i = e.key;
                final prog = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OdinAnimations.fadeUp(
                    _ProgramCard(
                      program: prog,
                      statusColor: _statusColor(prog.status),
                      statusLabel: _statusLabel(prog.status),
                      intensityColor: _intensityColor(prog.intensity),
                      onSend: () => data.updateProgramStatus(prog.id, 'envoye'),
                      onValidate: () => data.updateProgramStatus(prog.id, 'valide'),
                      onRefuse: () => data.updateProgramStatus(prog.id, 'refuse'),
                      onDelete: () async {
                        await data.deleteProgram(prog.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Programme supprimé')),
                          );
                        }
                      },
                    ),
                    index: i,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.statusColor,
    required this.statusLabel,
    required this.intensityColor,
    required this.onSend,
    required this.onValidate,
    required this.onRefuse,
    required this.onDelete,
  });

  final PrepProgram program;
  final Color statusColor;
  final String statusLabel;
  final Color intensityColor;
  final VoidCallback onSend;
  final VoidCallback onValidate;
  final VoidCallback onRefuse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.text,
                      ),
                    ),
                    if (program.objective.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        program.objective,
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _Chip(label: program.intensity, color: intensityColor),
                  const SizedBox(height: 4),
                  _Chip(label: statusLabel, color: statusColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Durée : ${program.duration}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (program.assignedPlayers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: program.assignedPlayers
                  .map(
                    (n) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        n.split(' ').first,
                        style: TextStyle(color: Color(0xFF6366F1), fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              if (program.status == 'brouillon')
                _ActionBtn(
                  label: 'Envoyer Coach',
                  icon: Icons.send_rounded,
                  color: AppColors.warning,
                  onTap: onSend,
                ),
              if (program.status == 'envoye') ...[
                _ActionBtn(
                  label: 'Validé',
                  icon: Icons.check_circle_outline,
                  color: AppColors.success,
                  onTap: onValidate,
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  label: 'Refusé',
                  icon: Icons.cancel_outlined,
                  color: AppColors.danger,
                  onTap: onRefuse,
                ),
              ],
              if (program.status == 'valide' || program.status == 'refuse')
                 Text(
                  'Workflow terminé',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              const Spacer(),
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.muted,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
