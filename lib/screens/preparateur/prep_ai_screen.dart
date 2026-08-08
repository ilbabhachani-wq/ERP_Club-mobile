import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/preparateur_provider.dart';
import '../../services/preparateur_api.dart';

const _accent = Color(0xFF6366F1);

class PrepAiScreen extends StatefulWidget {
  const PrepAiScreen({super.key});

  @override
  State<PrepAiScreen> createState() => _PrepAiScreenState();
}

class _PrepAiScreenState extends State<PrepAiScreen> {
  final _questionCtrl = TextEditingController();
  final _chatScroll = ScrollController();
  final _messages = <_ChatMsg>[];
  bool _loading = true;
  bool _sending = false;
  PrepAiData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<PreparateurDataProvider>().api;
      final data = await api.getAi();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScroll.hasClients) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(String text) async {
    final data = _data;
    if (text.trim().isEmpty || _sending || data == null || !data.isAvailable) return;
    setState(() {
      _messages.add(_ChatMsg(isUser: true, text: text.trim()));
      _sending = true;
    });
    _questionCtrl.clear();
    _scrollToBottom();
    try {
      final api = context.read<PreparateurDataProvider>().api;
      final res = await api.chatAi(text.trim());
      if (mounted) {
        setState(() => _messages.add(_ChatMsg(isUser: false, text: res.text, cards: res.cards, model: res.model, durationMs: res.durationMs)));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _messages.add(_ChatMsg(isUser: false, text: 'Erreur: $e')));
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                const Expanded(child: SectionTitle('Assistant IA')),
                _RefreshButton(loading: _loading, onPressed: _loading ? null : _load),
              ],
            ),
          ),
          if (_loading && data == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
                    const SizedBox(height: 12),
                    Text('Connexion à l\'IA…', style: TextStyle(color: OdinColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                controller: _chatScroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  OdinAnimations.fadeUp(_AiHeroCard(data: data, error: _error), index: 0),
                  if (data != null && data.status == 'no_key') ...[
                    const SizedBox(height: 12),
                    OdinAnimations.fadeUp(
                      _Banner(
                        icon: Icons.warning_amber_rounded,
                        color: OdinColors.danger,
                        text: 'Clé OpenAI non configurée côté club. Contactez votre administrateur pour activer l\'IA.',
                      ),
                      index: 1,
                    ),
                  ],
                  if (data != null) ...[
                    const SizedBox(height: 14),
                    OdinAnimations.fadeUp(_SummaryGrid(summary: data.summary), index: 2),
                  ],
                  if (data != null && data.suggestedQuestions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Questions suggérées',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OdinColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.suggestedQuestions
                          .map((q) => _SuggestionChip(label: q, onTap: data.isAvailable ? () => _send(q) : null))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: _accent.withValues(alpha: 0.9)),
                      const SizedBox(width: 8),
                      const Text('Chat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ChatPanel(messages: _messages, sending: _sending),
                  const SizedBox(height: 18),
                  Text(
                    'Actions rapides',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OdinColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ActionChip(icon: Icons.speed_rounded, label: 'Charge équipe', onTap: () => context.go('/preparateur/charge')),
                      _ActionChip(icon: Icons.fitness_center_rounded, label: 'Programmes', onTap: () => context.go('/preparateur/programmes')),
                      _ActionChip(icon: Icons.insights_rounded, label: 'Condition physique', onTap: () => context.go('/preparateur/condition')),
                    ],
                  ),
                ],
              ),
            ),
          if (!_loading || data != null)
            _ChatInputBar(
              controller: _questionCtrl,
              sending: _sending,
              enabled: data?.isAvailable ?? false,
              onSend: () => _send(_questionCtrl.text),
            ),
        ],
      ),
    );
  }
}

class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard({this.data, this.error});
  final PrepAiData? data;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final online = data?.isAvailable ?? false;
    return GlassCard(
      raised: true,
      accentColor: _accent,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_accent.withValues(alpha: 0.35), const Color(0xFF22D3EE).withValues(alpha: 0.35)],
              ),
              border: Border.all(color: _accent.withValues(alpha: 0.4)),
              boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.25), blurRadius: 16)],
            ),
            child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ODIN AI — Préparateur',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.2),
                ),
                const SizedBox(height: 4),
                Text(
                  data != null
                      ? '${data!.clubName} · ${data!.season}'
                      : (error ?? 'Assistant indisponible'),
                  style: TextStyle(fontSize: 11, color: OdinColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: online ? OdinColors.success : OdinColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      online ? 'Actif · ${data?.model ?? ''}' : 'Hors ligne',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: online ? OdinColors.success : OdinColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});
  final PrepAiSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Joueurs', '${summary.totalPlayers}', Icons.groups_rounded, _accent),
      ('Charge moy.', '${summary.avgLoad}%', Icons.speed_rounded, const Color(0xFFF59E0B)),
      ('Critiques', '${summary.critiques}', Icons.warning_amber_rounded, OdinColors.danger),
      ('Risques', '${summary.injuryRiskCount}', Icons.health_and_safety_outlined, OdinColors.danger),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: items
          .map((it) => GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(it.$3, size: 18, color: it.$4),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.$2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                          Text(it.$1, style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, height: 1.35))),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: OdinColors.panelBorder),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: onTap == null ? OdinColors.textMuted : OdinColors.textSecondary, height: 1.3),
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
            color: _accent.withValues(alpha: 0.08),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: _accent),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _accent)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({required this.messages, required this.sending});
  final List<_ChatMsg> messages;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF070B1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OdinColors.panelBorder),
      ),
      child: messages.isEmpty && !sending
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Icon(Icons.smart_toy_outlined, size: 32, color: _accent.withValues(alpha: 0.4)),
                const SizedBox(height: 10),
                Text(
                  'Posez une question sur la charge ou le risque de blessure',
                  style: TextStyle(color: OdinColors.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            )
          : Column(
              children: [
                ...messages.map((m) => _ChatBubble(message: m)),
                if (sending) const _ThinkingBubble(),
              ],
            ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _ChatMsg message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.smart_toy_outlined, size: 16, color: _accent),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? _accent : _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: _accent.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(fontSize: 13, height: 1.45, color: isUser ? Colors.white : OdinColors.textPrimary),
                  ),
                ),
              ),
            ],
          ),
          if (message.model != null || message.durationMs != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                '${message.model ?? ''} · ${((message.durationMs ?? 0) / 1000).toStringAsFixed(1)}s',
                style: TextStyle(fontSize: 9, color: OdinColors.textMuted),
              ),
            ),
          ],
          if (message.cards.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...message.cards.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 24),
                  child: _AiPlayerCard(card: c),
                )),
          ],
        ],
      ),
    );
  }
}

class _AiPlayerCard extends StatelessWidget {
  const _AiPlayerCard({required this.card});
  final PrepAiCard card;

  Color get _riskColor {
    final hex = card.color.replaceFirst('#', '');
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return OdinColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      accentColor: _riskColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(card.player, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              if (card.ready != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (card.ready! ? OdinColors.success : OdinColors.danger).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    card.ready! ? 'Disponible' : 'Indisponible',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: card.ready! ? OdinColors.success : OdinColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (card.risk / 100).clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: _riskColor,
            ),
          ),
          const SizedBox(height: 4),
          Text('Risque ${card.risk}%', style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
          if (card.reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...card.reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('• $r', style: TextStyle(fontSize: 11, color: OdinColors.textSecondary)),
                )),
          ],
          if (card.recommendations.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...card.recommendations.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text('→ $r', style: TextStyle(fontSize: 11, color: _accent, fontWeight: FontWeight.w600)),
                )),
          ],
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.smart_toy_outlined, size: 16, color: _accent),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: _accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final phase = (_ctrl.value + i * 0.2) % 1.0;
                  return Container(
                    width: 7,
                    height: 7,
                    margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _accent.withValues(alpha: 0.35 + phase * 0.65)),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending && enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: TextStyle(color: OdinColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: enabled ? 'Posez votre question...' : 'IA indisponible',
                hintStyle: TextStyle(color: OdinColors.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.auto_awesome_outlined, size: 20, color: OdinColors.textMuted),
                filled: true,
                fillColor: const Color(0xB81C1C2E),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: OdinColors.panelBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: OdinColors.panelBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _accent, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_accent, Color(0xFF4338CA)]),
              boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (sending || !enabled) ? null : onSend,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OdinColors.panelBorder),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: OdinColors.textMuted))
              else
                Icon(Icons.refresh_rounded, size: 16, color: OdinColors.textSecondary),
              const SizedBox(width: 6),
              Text(loading ? '…' : 'Actualiser', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: OdinColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMsg {
  _ChatMsg({required this.isUser, required this.text, this.cards = const [], this.model, this.durationMs});
  final bool isUser;
  final String text;
  final List<PrepAiCard> cards;
  final String? model;
  final int? durationMs;
}
