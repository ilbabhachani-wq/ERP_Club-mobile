import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';
import '../../services/joueur_api.dart';

class JoueurMedicalScreen extends StatefulWidget {
  const JoueurMedicalScreen({super.key});

  @override
  State<JoueurMedicalScreen> createState() => _JoueurMedicalScreenState();
}

class _JoueurMedicalScreenState extends State<JoueurMedicalScreen> {
  bool _booking = false;

  Future<void> _bookAppointment() async {
    final data = context.read<JoueurDataProvider>();
    if (data.myPlayerId == null) return;
    setState(() => _booking = true);
    try {
      final club = ClubApi(context.read<AuthProvider>().api);
      await club.bookAppointment(data.myPlayerId!, {
        'date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'reason': 'Bilan médical',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RDV médical demandé')),
        );
        await data.refetchMedical();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<JoueurDataProvider>();
    final stats = data.playerStats;
    final fatigue = stats?.fatiguePredicted ?? 45;

    return OdinBackdrop(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SectionTitle('Statut Médical'),
          Row(
            children: [
              Expanded(
                child: OdinAnimations.fadeUp(
                  _GaugeCard(label: 'Fatigue', value: fatigue, color: OdinColors.warning, icon: Icons.battery_alert),
                  index: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OdinAnimations.fadeUp(
                  _GaugeCard(label: 'Forme', value: stats?.form ?? 0, color: OdinColors.success, icon: Icons.favorite),
                  index: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modèle Corporel', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: _BodyPainter(injuries: data.injuries.map((i) => i.bodyPart).toList()),
                    child: const Center(
                      child: Icon(Icons.accessibility_new, size: 120, color: OdinColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Historique Blessures'),
          if (data.injuries.isEmpty)
            const GlassCard(child: Text('Aucune blessure enregistrée', style: TextStyle(color: OdinColors.textMuted)))
          else
            ...data.injuries.map((inj) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Row(
                      children: [
                        const Icon(Icons.healing, color: OdinColors.danger),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inj.injury, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                '${inj.bodyPart} · Retour: ${inj.returnDate}',
                                style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (inj.riskIA > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: OdinColors.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('IA ${inj.riskIA}%', style: const TextStyle(fontSize: 11, color: OdinColors.danger)),
                          ),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 16),
          OdinPrimaryButton(
            label: 'Prendre RDV médical',
            icon: Icons.calendar_today,
            loading: _booking,
            onPressed: _bookAppointment,
          ),
        ],
      ),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          OvrRing(ovr: value, size: 64, color: color),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({required this.injuries});
  final List<String> injuries;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < injuries.length; i++) {
      final paint = Paint()..color = OdinColors.danger.withValues(alpha: 0.4);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * (0.3 + i * 0.15)), 12, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) => true;
}
