import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../models/player_models.dart';
import '../../providers/app_providers.dart';
import '../../services/joueur_api.dart';

class JoueurAiScreen extends StatefulWidget {
  const JoueurAiScreen({super.key});

  @override
  State<JoueurAiScreen> createState() => _JoueurAiScreenState();
}

class _JoueurAiScreenState extends State<JoueurAiScreen> {
  final _questionCtrl = TextEditingController();
  final _chatScroll = ScrollController();
  final _messages = <_ChatMsg>[];
  bool _loadingReport = true;
  bool _sending = false;
  JoueurAiReport? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _loadReport({bool refresh = false}) async {
    setState(() => _loadingReport = true);
    try {
      final api = JoueurApi(context.read<AuthProvider>().api);
      final report = await api.getAiReport(refresh: refresh);
      if (mounted) setState(() => _report = report);
    } catch (_) {
      if (mounted) {
        setState(() {
          _report = const JoueurAiReport(
            suggestedQuestions: [
              'Comment puis-je améliorer ma vitesse sur le terrain ?',
              'Quel est mon risque de blessure cette semaine ?',
              'Plan d\'entraînement personnalisé ?',
            ],
            recommendations: [
              'Intégrez 15 min d\'étirements dynamiques avant chaque séance.',
              'Travaillez la précision de passe avec des exercices ciblés.',
              'Ajoutez 2 séances de vitesse par semaine pour progresser.',
            ],
          );
        });
      }
    } finally {
      if (mounted) setState(() => _loadingReport = false);
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
    if (text.trim().isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatMsg(isUser: true, text: text.trim()));
      _sending = true;
    });
    _questionCtrl.clear();
    _scrollToBottom();
    try {
      final api = JoueurApi(context.read<AuthProvider>().api);
      final reply = await api.chatAi(text.trim());
      if (mounted) {
        setState(() => _messages.add(_ChatMsg(isUser: false, text: reply)));
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
    final report = _report;
    final suggestions = report?.suggestedQuestions ?? [];
    final recommendations = report?.recommendations ?? [];

    return OdinBackdrop(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                const Expanded(child: SectionTitle('AI Coach')),
                _RefreshButton(
                  loading: _loadingReport,
                  onPressed: _loadingReport ? null : () => _loadReport(refresh: true),
                ),
              ],
            ),
          ),
          if (_loadingReport && report == null)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: OdinColors.playerCoral, strokeWidth: 2.5),
                    SizedBox(height: 12),
                    Text('Génération du rapport IA…', style: TextStyle(color: OdinColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView(
                controller: _chatScroll,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  OdinAnimations.fadeUp(_AiHeroCard(playerName: report?.playerName), index: 0),
                  if (recommendations.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    OdinAnimations.fadeUp(
                      _WeeklyReportCard(recommendations: recommendations.take(4).toList()),
                      index: 1,
                    ),
                  ],
                  if ((report?.strengths.isNotEmpty ?? false) || (report?.weaknesses.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 14),
                    OdinAnimations.fadeUp(_InsightsRow(report: report!), index: 2),
                  ],
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Questions suggérées',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: OdinColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestions.map((q) => _SuggestionChip(label: q, onTap: () => _send(q))).toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: OdinColors.playerCoral.withValues(alpha: 0.9)),
                      const SizedBox(width: 8),
                      const Text(
                        'Assistant IA',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ChatPanel(
                    messages: _messages,
                    sending: _sending,
                  ),
                ],
              ),
            ),
            _ChatInputBar(
              controller: _questionCtrl,
              sending: _sending,
              onSend: () => _send(_questionCtrl.text),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard({this.playerName});

  final String? playerName;

  @override
  Widget build(BuildContext context) {
    final firstName = (playerName ?? 'Joueur').split(' ').first;
    return GlassCard(
      raised: true,
      accentColor: OdinColors.playerCoral,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  OdinColors.playerCoral.withValues(alpha: 0.35),
                  const Color(0xFF6D28D9).withValues(alpha: 0.35),
                ],
              ),
              border: Border.all(color: OdinColors.playerCoral.withValues(alpha: 0.4)),
              boxShadow: [BoxShadow(color: OdinColors.playerCoral.withValues(alpha: 0.25), blurRadius: 16)],
            ),
            child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyse IA — $firstName',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.2),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: OdinColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Actif · Temps réel',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: OdinColors.success),
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

class _WeeklyReportCard extends StatelessWidget {
  const _WeeklyReportCard({required this.recommendations});

  final List<String> recommendations;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      accentColor: OdinColors.playerCoral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OdinColors.playerCoral.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded, size: 18, color: OdinColors.playerCoral),
              ),
              const SizedBox(width: 10),
              const Text('Rapport Hebdo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          ...recommendations.asMap().entries.map((e) {
            return Padding(
              padding: EdgeInsets.only(bottom: e.key < recommendations.length - 1 ? 10 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: OdinColors.playerCoral.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: OdinColors.playerCoral),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(fontSize: 13, height: 1.45, color: OdinColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _InsightsRow extends StatelessWidget {
  const _InsightsRow({required this.report});

  final JoueurAiReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (report.strengths.isNotEmpty)
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.trending_up, size: 14, color: OdinColors.success),
                      SizedBox(width: 6),
                      Text('Forces', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...report.strengths.take(2).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${s['label'] ?? ''}: ${s['value'] ?? ''}',
                          style: const TextStyle(fontSize: 11, color: OdinColors.textMuted),
                        ),
                      )),
                ],
              ),
            ),
          ),
        if (report.strengths.isNotEmpty && report.weaknesses.isNotEmpty) const SizedBox(width: 10),
        if (report.weaknesses.isNotEmpty)
          Expanded(
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.trending_down, size: 14, color: OdinColors.warning),
                      SizedBox(width: 6),
                      Text('Axes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...report.weaknesses.take(2).map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${w['label'] ?? ''}: ${w['value'] ?? ''}',
                          style: const TextStyle(fontSize: 11, color: OdinColors.textMuted),
                        ),
                      )),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

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
            style: const TextStyle(fontSize: 11, color: OdinColors.textSecondary, height: 1.3),
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
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 24),
                Icon(Icons.smart_toy_outlined, size: 32, color: Color(0x66FF6B57)),
                SizedBox(height: 10),
                Text(
                  'Posez une question sur votre performance',
                  style: TextStyle(color: OdinColors.textMuted, fontSize: 13),
                ),
                SizedBox(height: 24),
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
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.smart_toy_outlined, size: 16, color: OdinColors.playerCoral),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? OdinColors.playerCoral : OdinColors.playerCoral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: OdinColors.playerCoral.withValues(alpha: 0.15)),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isUser ? Colors.white : OdinColors.textPrimary,
                ),
              ),
            ),
          ),
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
          child: Icon(Icons.smart_toy_outlined, size: 16, color: OdinColors.playerCoral),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: OdinColors.playerCoral.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
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
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: OdinColors.playerCoral.withValues(alpha: 0.35 + phase * 0.65),
                    ),
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
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
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
              enabled: !sending,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(color: OdinColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Posez votre question...',
                hintStyle: const TextStyle(color: OdinColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.auto_awesome_outlined, size: 20, color: OdinColors.textMuted),
                filled: true,
                fillColor: const Color(0xB81C1C2E),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: OdinColors.panelBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: OdinColors.panelBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: OdinColors.playerCoral, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [OdinColors.playerCoral, Color(0xFFE0584A)],
              ),
              boxShadow: [
                BoxShadow(color: OdinColors.playerCoral.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: sending ? null : onSend,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Center(
                    child: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
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
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: OdinColors.textMuted),
                )
              else
                const Icon(Icons.refresh_rounded, size: 16, color: OdinColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                loading ? '…' : 'Actualiser',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: OdinColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMsg {
  _ChatMsg({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}
