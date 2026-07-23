import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/animations/odin_animations.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';
import '../../services/joueur_api.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> _contacts = [];
  bool _loading = true;
  String? _selectedPeerId;
  String? _selectedPeerName;
  List<dynamic> _thread = [];
  final _textCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      final api = MessagesApi(context.read<AuthProvider>().api);
      _contacts = await api.getContacts();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openThread(String peerId, String name) async {
    setState(() {
      _selectedPeerId = peerId;
      _selectedPeerName = name;
      _thread = [];
    });
    try {
      final api = MessagesApi(context.read<AuthProvider>().api);
      _thread = await api.getThread(peerId);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _send() async {
    if (_selectedPeerId == null || _textCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      final api = MessagesApi(context.read<AuthProvider>().api);
      await api.sendMessage(_selectedPeerId!, _textCtrl.text.trim());
      _textCtrl.clear();
      _thread = await api.getThread(_selectedPeerId!);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OdinBackdrop(
      child: _selectedPeerId == null ? _contactsList() : _threadView(),
    );
  }

  Widget _contactsList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: OdinColors.accent));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/menu')),
            const Text('Messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        if (_contacts.isEmpty)
          const GlassCard(child: Text('Aucune conversation', style: TextStyle(color: OdinColors.textMuted)))
        else
          ..._contacts.asMap().entries.map((e) {
            final c = e.value as Map<String, dynamic>;
            final id = c['memberId'] as String? ?? c['id'] as String? ?? '';
            final name = c['fullName'] as String? ?? c['name'] as String? ?? 'Contact';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OdinAnimations.fadeUp(
                GlassCard(
                  onTap: () => _openThread(id, name),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: OdinColors.accent.withValues(alpha: 0.2),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              c['lastMessage'] as String? ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
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
    );
  }

  Widget _threadView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedPeerId = null),
              ),
              Text(_selectedPeerName ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _thread.length,
            itemBuilder: (_, i) {
              final m = _thread[i] as Map<String, dynamic>;
              final isMe = m['isMine'] == true;
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? OdinColors.accent.withValues(alpha: 0.25) : OdinColors.glassPanel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OdinColors.panelBorder),
                  ),
                  child: Text(m['text'] as String? ?? ''),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  decoration: const InputDecoration(hintText: 'Votre message...'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(backgroundColor: OdinColors.accent, shape: const CircleBorder(), padding: const EdgeInsets.all(14)),
                child: const Icon(Icons.send, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
