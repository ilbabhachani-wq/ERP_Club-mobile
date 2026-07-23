import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

class JoueurListScreen extends StatefulWidget {
  const JoueurListScreen({super.key});

  @override
  State<JoueurListScreen> createState() => _JoueurListScreenState();
}

class _JoueurListScreenState extends State<JoueurListScreen> {
  String _filter = 'Tous';

  @override
  Widget build(BuildContext context) {
    final squad = context.watch<JoueurDataProvider>().squadPlayers;
    final filtered = _filter == 'Tous'
        ? squad
        : squad.where((p) => p.availability == _filter).toList();

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Effectif'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tous', 'Disponible', 'Blessé', 'Limité'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: OdinColors.accent.withValues(alpha: 0.25),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          ...filtered.asMap().entries.map((e) {
            final p = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OdinAnimations.fadeUp(
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      OvrRing(ovr: p.ovr, size: 52, color: OdinColors.playerCoral),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text('${p.position} · ${p.availability}', style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(p.marketValue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
                index: e.key,
              ),
            );
          }),
        ],
      ),
    );
  }
}
