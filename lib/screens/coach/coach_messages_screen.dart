import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/coach_models.dart';
import '../../providers/coach_provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/theme_provider.dart';

enum _RoleFilter { tous, joueurs, staff }

class CoachMessagesScreen extends StatefulWidget {
  const CoachMessagesScreen({super.key});

  @override
  State<CoachMessagesScreen> createState() => _CoachMessagesScreenState();
}

class _CoachMessagesScreenState extends State<CoachMessagesScreen> {
  static const _accent = OdinColors.accent;

  List<CoachContact> _contacts = [];
  List<CoachChatMessage> _thread = [];
  bool _loading = true;
  bool _sending = false;
  String? _peerId;
  String? _peerName;
  _RoleFilter _filter = _RoleFilter.tous;
  final _searchCtrl = TextEditingController();
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<CoachProvider>().loadContacts(
            search: _searchCtrl.text.trim(),
          );
      if (mounted) setState(() => _contacts = list);
    } catch (_) {
      if (mounted) setState(() => _contacts = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openThread(CoachContact c) async {
    setState(() {
      _peerId = c.memberId;
      _peerName = c.name;
      _thread = [];
    });
    try {
      final msgs = await context.read<CoachProvider>().loadThread(c.memberId);
      if (mounted) setState(() => _thread = msgs);
    } catch (_) {}
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (_peerId == null || text.isEmpty) return;
    final peerId = _peerId!;
    final prov = context.read<CoachProvider>();
    setState(() => _sending = true);
    try {
      await prov.sendChat(peerId, text);
      _textCtrl.clear();
      final msgs = await prov.loadThread(peerId);
      if (!mounted) return;
      setState(() => _thread = msgs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool _isJoueur(CoachContact c) {
    final r = c.role.toLowerCase();
    return r.contains('joueur') || r.contains('player');
  }

  List<CoachContact> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _contacts.where((c) {
      if (_filter == _RoleFilter.joueurs && !_isJoueur(c)) return false;
      if (_filter == _RoleFilter.staff && _isJoueur(c)) return false;
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.role.toLowerCase().contains(q) ||
          c.preview.toLowerCase().contains(q);
    }).toList();
  }

  /// Extract a date-group key from message.time. If no date part is found,
  /// all messages share "Conversation".
  static String _dateKey(String time) {
    final t = time.trim();
    if (t.isEmpty) return 'Conversation';

    // ISO-like: 2024-03-12 or 2024-03-12T18:30
    final iso = RegExp(r'^(\d{4}-\d{2}-\d{2})');
    final isoM = iso.firstMatch(t);
    if (isoM != null) return isoM.group(1)!;

    // FR: 12/03/2024 or 12-03-2024
    final fr = RegExp(r'^(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})');
    final frM = fr.firstMatch(t);
    if (frM != null) return frM.group(1)!;

    // "12 mars 2024 · 18:30" / "Aujourd'hui" / weekday labels with date
    if (t.contains(' · ')) {
      final left = t.split(' · ').first.trim();
      if (left.isNotEmpty && !_looksLikeClockOnly(left)) return left;
    }
    if (t.contains(', ')) {
      final left = t.split(', ').first.trim();
      if (left.isNotEmpty && !_looksLikeClockOnly(left)) return left;
    }

    // Pure clock (18:30, 18h30) → no date
    if (_looksLikeClockOnly(t)) return 'Conversation';

    // Otherwise treat leading token as date label if it has letters/digits beyond time
    return t;
  }

  static bool _looksLikeClockOnly(String s) {
    return RegExp(r'^\d{1,2}[:hH]\d{2}(\s*(AM|PM|am|pm))?$').hasMatch(s.trim());
  }

  static String _displayTime(String time) {
    final t = time.trim();
    if (t.isEmpty) return '';
    if (t.contains(' · ')) return t.split(' · ').last.trim();
    if (t.contains(', ')) {
      final parts = t.split(', ');
      if (parts.length > 1) return parts.last.trim();
    }
    // ISO datetime → HH:mm
    final iso = RegExp(r'T(\d{2}:\d{2})');
    final m = iso.firstMatch(t);
    if (m != null) return m.group(1)!;
    return t;
  }

  List<_ChatRow> _buildChatRows(List<CoachChatMessage> msgs) {
    final rows = <_ChatRow>[];
    String? lastKey;
    for (final m in msgs) {
      final key = _dateKey(m.time);
      if (key != lastKey) {
        rows.add(_ChatRow.separator(key));
        lastKey = key;
      }
      rows.add(_ChatRow.message(m));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return OdinBackdrop(
      child: Column(
        children: [
          if (_peerId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: OdinColors.textSecondary),
                    onPressed: () => setState(() {
                      _peerId = null;
                      _peerName = null;
                      _thread = [];
                    }),
                  ),
                  Expanded(
                    child: Text(
                      _peerName ?? 'Conversation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: OdinColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _peerId == null ? _contactsView() : _threadView()),
        ],
      ),
    );
  }

  Widget _contactsView() {
    final list = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: OdinColors.textPrimary, fontSize: 14),
            onSubmitted: (_) => _loadContacts(),
            decoration: InputDecoration(
              hintText: 'Rechercher…',
              hintStyle: TextStyle(
                color: OdinColors.textMuted.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: OdinColors.textMuted,
              ),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: OdinColors.textMuted,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        _loadContacts();
                      },
                    ),
              filled: true,
              fillColor: OdinColors.inputFill,
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
                borderSide: BorderSide(color: OdinColors.accent.withValues(alpha: 0.5)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _FilterChip(
                label: 'Tous',
                selected: _filter == _RoleFilter.tous,
                onTap: () => setState(() => _filter = _RoleFilter.tous),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Joueurs',
                selected: _filter == _RoleFilter.joueurs,
                onTap: () => setState(() => _filter = _RoleFilter.joueurs),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Staff',
                selected: _filter == _RoleFilter.staff,
                onTap: () => setState(() => _filter = _RoleFilter.staff),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _accent),
                )
              : list.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune conversation',
                        style: TextStyle(color: OdinColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      color: _accent,
                      onRefresh: _loadContacts,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.bottomNav),
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final c = list[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ContactRow(
                              contact: c,
                              onTap: () => _openThread(c),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _threadView() {
    final rows = _buildChatRows(_thread);
    return Column(
      children: [
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    'Aucun message',
                    style: TextStyle(
                      color: OdinColors.textMuted,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    if (row.isSeparator) {
                      return _DateSeparator(label: row.separatorLabel!);
                    }
                    return _Bubble(message: row.message!);
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            12,
            10 + MediaQuery.of(context).viewInsets.bottom + AppSpacing.fabLift(context),
          ),
          decoration: BoxDecoration(
            color: OdinColors.panelSolid.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: OdinColors.panelBorder),
            ),
          ),
          child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: TextStyle(color: OdinColors.textPrimary),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Écrire un message…',
                      hintStyle: TextStyle(
                        color: OdinColors.textMuted.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: OdinColors.panelBorder.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: _sending ? OdinColors.panelBorder : _accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sending ? null : _send,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
        ),
      ],
    );
  }
}

class _ChatRow {
  _ChatRow._({this.message, this.separatorLabel});

  factory _ChatRow.message(CoachChatMessage m) => _ChatRow._(message: m);
  factory _ChatRow.separator(String label) =>
      _ChatRow._(separatorLabel: label);

  final CoachChatMessage? message;
  final String? separatorLabel;

  bool get isSeparator => separatorLabel != null;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? OdinColors.accent : OdinColors.inputFill,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? OdinColors.accent : OdinColors.panelBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : OdinColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact, required this.onTap});

  final CoachContact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final c = contact;
    return GlassCard(
      onTap: onTap,
      accentColor: OdinColors.accent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        height: 52,
        child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: OdinColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: OdinColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: OdinColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (c.role.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: OdinColors.panelBorder,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                c.role,
                                style: TextStyle(
                                  color: OdinColors.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.preview.isEmpty ? 'Aucun message' : c.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (c.time.isNotEmpty)
                      Text(
                        c.time,
                        style: TextStyle(
                          color: OdinColors.textMuted.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    if (c.unread > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: OdinColors.accent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${c.unread}',
                          style: TextStyle(
                            color: OdinColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: OdinColors.panelBorder,
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: OdinColors.panelBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: OdinColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: OdinColors.panelBorder,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final CoachChatMessage message;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final mine = message.sent;
    final timeLabel = _CoachMessagesScreenState._displayTime(message.time);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine
              ? OdinColors.accent.withValues(alpha: 0.28)
              : OdinColors.panelBorder,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: OdinColors.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            if (timeLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: TextStyle(
                  color: OdinColors.textMuted.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
