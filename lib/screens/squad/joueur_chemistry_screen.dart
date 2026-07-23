import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

class JoueurChemistryScreen extends StatelessWidget {
  const JoueurChemistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chemistry = context.watch<JoueurDataProvider>().chemistry;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Chimie d\'équipe'),
          if (chemistry.isEmpty)
            const GlassCard(
              child: Text('Aucune donnée de chimie', style: TextStyle(color: OdinColors.textMuted)),
            )
          else
            ...chemistry.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${c.player1Name} ↔ ${c.player2Name}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: c.chemistry / 100,
                              color: _chemColor(c.chemistry),
                              backgroundColor: Colors.white.withValues(alpha: 0.08),
                            ),
                            Text(
                              '${c.chemistry}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Color _chemColor(int v) {
    if (v >= 80) return OdinColors.success;
    if (v >= 60) return OdinColors.warning;
    return OdinColors.danger;
  }
}
