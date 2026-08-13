import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/medecin_provider.dart';
import '../../services/medecin_api.dart';

class MedecinAiScreen extends StatefulWidget {
  const MedecinAiScreen({super.key});

  @override
  State<MedecinAiScreen> createState() => _MedecinAiScreenState();
}

class _MedecinAiScreenState extends State<MedecinAiScreen> {
  final _ctrl = TextEditingController();
  final _messages = <_Msg>[];
  bool _loading = true;
  bool _sending = false;
  MedecinAiData? _data;
  String? _error;
  String? _playerId;
  MedecinPlayerAnalysis? _analysis;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<MedecinProvider>().api.getAi();
      if (!mounted) return;
      setState(() {
        _data = data;
        if (_messages.isEmpty) {
          _messages.add(_Msg(
            isUser: false,
            text:
                'Bonjour. Je suis Medical AI ODIN pour ${data.clubName}. Posez une question ou analysez un joueur à risque.',
          ));
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send(String text) async {
    final data = _data;
    if (text.trim().isEmpty || _sending || data == null || !data.isAvailable) return;
    setState(() {
      _messages.add(_Msg(isUser: true, text: text.trim()));
      _sending = true;
    });
    _ctrl.clear();
    try {
      final res = await context.read<MedecinProvider>().api.chatAi(text.trim(), playerId: _playerId);
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(isUser: false, text: res.text, cards: res.cards, model: res.model));
      });
    } catch (e) {
      if (mounted) setState(() => _messages.add(_Msg(isUser: false, text: 'Erreur: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _analyze(String id) async {
    setState(() {
      _playerId = id;
      _sending = true;
    });
    try {
      final res = await context.read<MedecinProvider>().api.analyzePlayer(id);
      if (!mounted) return;
      setState(() => _analysis = res);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  OdinAnimations.fadeUp(
                    GlassCard(
                      raised: true,
                      accentColor: OdinColors.accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Medical AI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(
                            data != null ? '${data.clubName} · ${data.season}' : (_error ?? 'Assistant indisponible'),
                            style: TextStyle(fontSize: 12, color: OdinColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (data != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Kpi('Effectif', '${data.summary.squadSize}'),
                        _Kpi('Blessés', '${data.summary.blesses}'),
                        _Kpi('Haut risque', '${data.summary.highRisk}'),
                        _Kpi('Risque moy.', '${data.summary.avgRisk}'),
                      ],
                    ),
                    if (data.players.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('Joueurs à risque', style: TextStyle(color: OdinColors.textMuted, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...data.players.take(5).map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                onTap: data.isAvailable ? () => _analyze(p.id) : null,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('${p.name} · ${p.position}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                    Text('${p.riskScore}', style: const TextStyle(color: OdinColors.accent, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ],
                    if (_analysis != null) ...[
                      const SizedBox(height: 8),
                      GlassCard(
                        accentColor: OdinColors.accent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Analyse — ${_analysis!.playerName}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text('Risque ${_analysis!.risk}% · ${_analysis!.level}'),
                            Text('${_analysis!.mainInjury} — ${_analysis!.grade}'),
                            Text(_analysis!.recommendation, style: TextStyle(color: OdinColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.suggestedQuestions
                          .take(6)
                          .map((q) => ActionChip(
                                label: Text(q, style: const TextStyle(fontSize: 11)),
                                onPressed: data.isAvailable ? () => _send(q) : null,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ..._messages.map((m) => _Bubble(m)),
                  if (_sending) Text('Analyse en cours…', style: TextStyle(color: OdinColors.textMuted)),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      enabled: data?.isAvailable == true && !_sending,
                      decoration: const InputDecoration(
                        hintText: 'Question médicale…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: data?.isAvailable == true && !_sending ? () => _send(_ctrl.text) : null,
                    style: IconButton.styleFrom(backgroundColor: OdinColors.accent),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: OdinColors.accent)),
          Text(label, style: TextStyle(fontSize: 10, color: OdinColors.textMuted)),
        ],
      ),
    );
  }
}

class _Msg {
  _Msg({required this.isUser, required this.text, this.cards = const [], this.model});
  final bool isUser;
  final String text;
  final List<MedecinAiCard> cards;
  final String? model;
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
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: m.isUser ? OdinColors.accent : OdinColors.canvas2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(m.text, style: TextStyle(color: m.isUser ? Colors.white : OdinColors.textPrimary)),
      ),
    );
  }
}
