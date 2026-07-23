import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

class JoueurTransfersScreen extends StatelessWidget {
  const JoueurTransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transfers = context.watch<JoueurDataProvider>().transfers;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Transferts & Rumeurs'),
          if (transfers.isEmpty)
            const GlassCard(child: Text('Aucun transfert', style: TextStyle(color: OdinColors.textMuted)))
          else
            ...transfers.asMap().entries.map((e) {
              final t = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OdinAnimations.fadeUp(
                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(t.playerName, style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            _statusChip(t.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${t.transferType} → ${t.club}', style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(t.value, style: const TextStyle(fontWeight: FontWeight.w700, color: OdinColors.accent)),
                            const Spacer(),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: t.probability / 100,
                                    color: OdinColors.playerCoral,
                                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  ),
                                  Text('${t.probability}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  static Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: OdinColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
