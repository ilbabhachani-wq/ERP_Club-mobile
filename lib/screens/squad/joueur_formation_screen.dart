import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../models/player_models.dart';
import '../../providers/app_providers.dart';

class JoueurFormationScreen extends StatelessWidget {
  const JoueurFormationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final squad = context.watch<JoueurDataProvider>().squadPlayers;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Formation 4-3-3'),
          GlassCard(
            child: AspectRatio(
              aspectRatio: 0.75,
              child: CustomPaint(
                painter: _PitchPainter(),
                child: Stack(
                  children: [
                    ..._slots(squad),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _chemStat('Chimie', '82', OdinColors.success),
                _chemStat('Attaque', '78', OdinColors.playerCoral),
                _chemStat('Défense', '75', OdinColors.info),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _slots(List<BackendPlayer> squad) {
    final positions = [
      const Offset(0.5, 0.88),
      const Offset(0.15, 0.65), const Offset(0.38, 0.65), const Offset(0.62, 0.65), const Offset(0.85, 0.65),
      const Offset(0.25, 0.42), const Offset(0.5, 0.42), const Offset(0.75, 0.42),
      const Offset(0.2, 0.18), const Offset(0.5, 0.12), const Offset(0.8, 0.18),
    ];
    return List.generate(positions.length, (i) {
      final p = i < squad.length ? squad[i] : null;
      final pos = positions[i];
      return Positioned(
        left: pos.dx * 280 - 24,
        top: pos.dy * 360,
        child: _slotPlayer(p),
      );
    });
  }

  static Widget _slotPlayer(BackendPlayer? p) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: OdinColors.glassRaised,
        shape: BoxShape.circle,
        border: Border.all(color: OdinColors.accent, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        p != null ? '${p.ovr}' : '?',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }

  static Widget _chemStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1a4d2e)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)),
      paint,
    );
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 30, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
