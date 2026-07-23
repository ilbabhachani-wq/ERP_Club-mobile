import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/fifa_card_utils.dart';
import '../../core/widgets/fifa_player_card.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';
import '../../services/joueur_api.dart';

class JoueurProfileScreen extends StatefulWidget {
  const JoueurProfileScreen({super.key});

  @override
  State<JoueurProfileScreen> createState() => _JoueurProfileScreenState();
}

class _JoueurProfileScreenState extends State<JoueurProfileScreen> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _initFields() {
    final p = context.read<JoueurDataProvider>().myPlayer;
    if (p == null) return;
    _height.text = p.height ?? '';
    _weight.text = p.weight ?? '';
  }

  Future<void> _save() async {
    final data = context.read<JoueurDataProvider>();
    if (data.myPlayerId == null) return;
    setState(() => _saving = true);
    try {
      await ClubApi(context.read<AuthProvider>().api).updatePlayerPhysical(
        data.myPlayerId!,
        {'height': _height.text, 'weight': _weight.text},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
        await data.load(context.read<AuthProvider>().user!);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<JoueurDataProvider>();
    final player = data.myPlayer;
    final contract = data.myContract;

    if (player == null) {
      return const Center(child: Text('Chargement...'));
    }

    if (_height.text.isEmpty && (player.height?.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initFields());
    }

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Center(
            child: FifaPlayerCard(
              name: player.name,
              position: player.position,
              ovr: player.ovr,
              age: player.age,
              radar: player.radar,
              number: player.jerseyNumber != null ? '${player.jerseyNumber}' : '—',
              nationality: player.nationality ?? '',
              flag: nationalityFlag(player.nationality),
              club: data.orgProfile?.clubName ?? 'FC Carthage',
              photoUrl: player.photoUrl,
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Informations'),
          GlassCard(
            child: Column(
              children: [
                _infoRow('Position', player.positionFull.isNotEmpty ? player.positionFull : player.position),
                _infoRow('Âge', '${player.age} ans'),
                _infoRow('Pied fort', player.strongFoot ?? '—'),
                _infoRow('Nationalité', player.nationality ?? '—'),
                const SizedBox(height: 12),
                TextField(controller: _height, decoration: const InputDecoration(labelText: 'Taille (cm)')),
                const SizedBox(height: 12),
                TextField(controller: _weight, decoration: const InputDecoration(labelText: 'Poids (kg)')),
                const SizedBox(height: 16),
                OdinPrimaryButton(label: 'Enregistrer', loading: _saving, onPressed: _save),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Contrat — Lecture seule'),
          GlassCard(
            child: Column(
              children: [
                _infoRow('Début', contract?.startDate ?? '—'),
                _infoRow('Fin', contract?.endDate ?? '—'),
                _infoRow('Salaire', contract?.salary ?? '—'),
                _infoRow('Clause libératoire', contract?.releaseClause ?? '—'),
                if (contract != null && contract.consumedPct > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: contract.consumedPct / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      color: OdinColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${contract.consumedPct}% du contrat écoulé', style: const TextStyle(fontSize: 12, color: OdinColors.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Statistiques Saison'),
          Row(
            children: [
              Expanded(child: OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.sports_soccer, label: 'Buts', value: '${data.playerStats?.seasonGoals ?? 0}', color: OdinColors.playerCoral), index: 0)),
              const SizedBox(width: 12),
              Expanded(child: OdinAnimations.fadeUp(JoueurKpiCard(icon: Icons.swap_horiz, label: 'Passes D.', value: '${data.playerStats?.seasonAssists ?? 0}', color: OdinColors.accent), index: 1)),
            ],
          ),
          if (data.awards.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionTitle('Trophées & Récompenses'),
            ...data.awards.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(a.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(a.season, style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: OdinColors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
