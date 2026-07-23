import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';

class JoueurAwardsScreen extends StatelessWidget {
  const JoueurAwardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final awards = context.watch<JoueurDataProvider>().awards;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Récompenses & Trophées'),
          if (awards.isEmpty)
            const GlassCard(child: Text('Aucune récompense', style: TextStyle(color: OdinColors.textMuted)))
          else
            ...awards.asMap().entries.map((e) {
              final a = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OdinAnimations.fadeUp(
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.9, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                          child: Text(a.icon, style: const TextStyle(fontSize: 36)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              Text(a.season, style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                              if (a.awardType.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: OdinColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(a.awardType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
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
}
