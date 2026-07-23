import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../models/player_models.dart';
import '../../providers/app_providers.dart';

class JoueurCompareScreen extends StatefulWidget {
  const JoueurCompareScreen({super.key});

  @override
  State<JoueurCompareScreen> createState() => _JoueurCompareScreenState();
}

class _JoueurCompareScreenState extends State<JoueurCompareScreen> {
  BackendPlayer? _a;
  BackendPlayer? _b;

  @override
  Widget build(BuildContext context) {
    final squad = context.watch<JoueurDataProvider>().squadPlayers;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Comparer deux joueurs'),
          _playerPicker('Joueur 1', _a, squad, (p) => setState(() => _a = p)),
          const SizedBox(height: 12),
          _playerPicker('Joueur 2', _b, squad, (p) => setState(() => _b = p)),
          if (_a != null && _b != null) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  _compareRow('OVR', _a!.ovr, _b!.ovr),
                  _compareRow('Vitesse', _a!.radar.speed, _b!.radar.speed),
                  _compareRow('Tir', _a!.radar.shooting, _b!.radar.shooting),
                  _compareRow('Passe', _a!.radar.passing, _b!.radar.passing),
                  _compareRow('Physique', _a!.radar.physical, _b!.radar.physical),
                  _compareRow('Défense', _a!.radar.defending, _b!.radar.defending),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _playerPicker(
    String label,
    BackendPlayer? selected,
    List<BackendPlayer> squad,
    ValueChanged<BackendPlayer> onSelect,
  ) {
    return GlassCard(
      child: DropdownButtonFormField<BackendPlayer>(
        decoration: InputDecoration(labelText: label),
        initialValue: selected,
        items: squad.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
        onChanged: (p) {
          if (p != null) onSelect(p);
        },
      ),
    );
  }

  Widget _compareRow(String label, int va, int vb) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$va',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: va >= vb ? OdinColors.success : OdinColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              '$vb',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: vb >= va ? OdinColors.success : OdinColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
