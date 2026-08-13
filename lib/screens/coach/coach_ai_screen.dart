import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../core/widgets/scout_widgets.dart';
import '../../providers/coach_provider.dart';
import '../../services/coach_api.dart';

class CoachAiScreen extends StatefulWidget {
  const CoachAiScreen({super.key});

  @override
  State<CoachAiScreen> createState() => _CoachAiScreenState();
}

class _CoachAiScreenState extends State<CoachAiScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Msg>[];
  bool _loading = true;
  bool _sending = false;
  CoachAiData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<CoachProvider>().api.getAi();
      if (!mounted) return;
      setState(() {
        _data = data;
        if (_messages.isEmpty) {
          final first = data.coachName.split(' ').first;
          _messages.add(_Msg(
            isUser: false,
            text:
                'Bonjour ${first.isEmpty ? 'Coach' : first} ! Je suis ODIN AI Coach pour ${data.clubName}. Posez-moi une question sur l\'effectif, la tactique ou le prochain match.',
          ));
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final data = _data;
    if (text.trim().isEmpty || _sending || data == null || !data.isAvailable) return;
    setState(() {
      _messages.add(_Msg(isUser: true, text: text.trim()));
      _sending = true;
    });
    _ctrl.clear();
    _scrollToBottom();
    try {
      final res = await context.read<CoachProvider>().api.chatAi(text.trim());
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(
          isUser: false,
          text: res.text,
          cards: res.cards,
          model: res.model,
          durationMs: res.durationMs,
        ));
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add(_Msg(isUser: false, text: 'Erreur: $e')));
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return OdinBackdrop(
      child: Column(
        children: [
          if (_loading && data == null)
            const Expanded(child: Center(child: CircularProgressIndicator(color: OdinColors.accent)))
          else
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  OdinAnimations.fadeUp(
                    GlassCard(
                      raised: true,
                      accentColor: OdinColors.accent,
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  OdinColors.accent.withValues(alpha: 0.35),
                                  const Color(0xFF22D3EE).withValues(alpha: 0.28),
                                ],
                              ),
                              border: Border.all(color: OdinColors.accent.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ODIN AI Coach',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data != null
                                      ? '${data.clubName} · ${data.season}'
                                      : (_error ?? 'Assistant indisponible'),
                                  style: TextStyle(fontSize: 12, color: OdinColors.textMuted),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: data?.isAvailable == true
                                            ? AppColors.success
                                            : OdinColors.textMuted,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      data?.isAvailable == true
                                          ? 'Actif · ${data?.model ?? ''}'
                                          : 'Hors ligne',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: data?.isAvailable == true
                                            ? AppColors.success
                                            : OdinColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (data?.status == 'no_key') ...[
                    const SizedBox(height: 12),
                    GlassCard(
                      accentColor: OdinColors.warning,
                      child: Text(
                        'Clé OpenAI non configurée côté serveur.',
                        style: TextStyle(color: OdinColors.warning),
                      ),
                    ),
                  ],
                  if (data != null) ...[
                    const SizedBox(height: 16),
                    const ScoutSectionLabel('Indicateurs'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _KpiTile(
                            label: 'Effectif',
                            value: '${data.summary.squadSize}',
                            icon: Icons.groups_rounded,
                            color: OdinColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiTile(
                            label: 'Dispo',
                            value: '${data.summary.disponibles}',
                            icon: Icons.check_circle_rounded,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _KpiTile(
                            label: 'Charge',
                            value: '${data.summary.avgLoad}%',
                            icon: Icons.speed_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _KpiTile(
                            label: 'Critiques',
                            value: '${data.summary.critiques}',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    if (data.suggestedQuestions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const ScoutSectionLabel('Questions suggérées'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: data.suggestedQuestions
                            .take(6)
                            .map(
                              (q) => GestureDetector(
                                onTap: data.isAvailable ? () => _send(q) : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: OdinColors.inputFill,
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(color: OdinColors.panelBorder),
                                  ),
                                  child: Text(
                                    q,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: data.isAvailable
                                          ? OdinColors.textSecondary
                                          : OdinColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  const ScoutSectionLabel('Chat'),
                  const SizedBox(height: 10),
                  ..._messages.map((m) => _Bubble(m)),
                  if (_sending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('ODIN réfléchit…', style: TextStyle(color: OdinColors.textMuted)),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _LinkChip('Séances', Icons.fitness_center_rounded, '/coach/entrainements'),
                      _LinkChip('Compo', Icons.sports_soccer, '/coach/composition'),
                      _LinkChip('Analyse', Icons.analytics_rounded, '/coach/analyse'),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8 + AppSpacing.fabLift(context)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    enabled: data?.isAvailable == true && !_sending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    style: TextStyle(color: OdinColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: data?.isAvailable == true
                          ? 'Question tactique, effectif, match…'
                          : 'IA indisponible',
                      hintStyle: TextStyle(color: OdinColors.textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.auto_awesome_outlined, color: OdinColors.textMuted, size: 20),
                      filled: true,
                      fillColor: OdinColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: OdinColors.panelBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: OdinColors.panelBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: OdinColors.accent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: OdinColors.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: data?.isAvailable == true && !_sending ? () => _send(_ctrl.text) : null,
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: GlassCard(
        raised: true,
        accentColor: color,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: OdinColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OdinColors.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: OdinColors.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: OdinColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Msg {
  _Msg({required this.isUser, required this.text, this.cards = const [], this.model, this.durationMs});
  final bool isUser;
  final String text;
  final List<CoachAiCard> cards;
  final String? model;
  final int? durationMs;
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.m);
  final _Msg m;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: m.isUser ? OdinColors.accent : OdinColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.isUser ? 16 : 4),
            bottomRight: Radius.circular(m.isUser ? 4 : 16),
          ),
          border: m.isUser ? null : Border.all(color: OdinColors.accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(
                color: m.isUser ? Colors.white : OdinColors.textPrimary,
                height: 1.4,
                fontSize: 13,
              ),
            ),
            if (m.cards.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...m.cards.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${c.title}: ${c.value} — ${c.detail}',
                    style: TextStyle(fontSize: 12, color: OdinColors.textMuted),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
