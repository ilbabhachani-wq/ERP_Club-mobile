import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/odin_colors.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../models/coach_models.dart';
import '../../providers/coach_provider.dart';
import '../../providers/theme_provider.dart';

Color get _kCard => OdinColors.canvas2;
Color get _kAccent => OdinColors.accent;
const _kGreen = Color(0xFF22C55E);
const _kRed = Color(0xFFEF4444);
const _kAmber = Color(0xFFF59E0B);
const _kBlue = Color(0xFF3B82F6);
const _kPurple = Color(0xFF8B5CF6);
const _kYellow = Color(0xFFFACC15);

const _kMaxSubs = 7;
const _kMaxReserves = 7;

const _kDefenderPositions = {'GK', 'DC', 'LB', 'RB', 'CB'};
const _kMidfielderPositions = {'MC', 'MDF', 'MOC'};
const _kAttackerPositions = {'BU', 'ST', 'AG', 'AD', 'LW', 'RW'};

class _PitchSlot {
  const _PitchSlot(this.label, this.x, this.y);

  final String label;
  final double x;
  final double y;
}

const _kFormations = <String, List<_PitchSlot>>{
  '4-3-3': [
    _PitchSlot('GK', 50, 88),
    _PitchSlot('RB', 80, 70),
    _PitchSlot('DC', 62, 72),
    _PitchSlot('DC', 38, 72),
    _PitchSlot('LB', 20, 70),
    _PitchSlot('MC', 70, 50),
    _PitchSlot('MC', 50, 48),
    _PitchSlot('MC', 30, 50),
    _PitchSlot('AD', 75, 28),
    _PitchSlot('BU', 50, 22),
    _PitchSlot('AG', 25, 28),
  ],
  '4-4-2': [
    _PitchSlot('GK', 50, 88),
    _PitchSlot('RB', 80, 70),
    _PitchSlot('DC', 62, 72),
    _PitchSlot('DC', 38, 72),
    _PitchSlot('LB', 20, 70),
    _PitchSlot('AD', 78, 48),
    _PitchSlot('MC', 60, 50),
    _PitchSlot('MC', 40, 50),
    _PitchSlot('AG', 22, 48),
    _PitchSlot('BU', 62, 24),
    _PitchSlot('BU', 38, 24),
  ],
  '4-2-3-1': [
    _PitchSlot('GK', 50, 88),
    _PitchSlot('RB', 80, 70),
    _PitchSlot('DC', 62, 72),
    _PitchSlot('DC', 38, 72),
    _PitchSlot('LB', 20, 70),
    _PitchSlot('MDF', 62, 56),
    _PitchSlot('MDF', 38, 56),
    _PitchSlot('AD', 74, 36),
    _PitchSlot('MOC', 50, 34),
    _PitchSlot('AG', 26, 36),
    _PitchSlot('BU', 50, 18),
  ],
  '3-5-2': [
    _PitchSlot('GK', 50, 88),
    _PitchSlot('DC', 70, 72),
    _PitchSlot('DC', 50, 74),
    _PitchSlot('DC', 30, 72),
    _PitchSlot('RB', 85, 52),
    _PitchSlot('MC', 65, 50),
    _PitchSlot('MDF', 50, 48),
    _PitchSlot('MC', 35, 50),
    _PitchSlot('LB', 15, 52),
    _PitchSlot('BU', 60, 24),
    _PitchSlot('BU', 40, 24),
  ],
};

String _normalizePosition(String raw) {
  final upper = raw
      .toUpperCase()
      .replaceAll('É', 'E')
      .replaceAll('È', 'E')
      .replaceAll('Ê', 'E')
      .replaceAll('À', 'A')
      .replaceAll('Ç', 'C');
  final buffer = StringBuffer();
  for (final unit in upper.codeUnits) {
    if (unit >= 65 && unit <= 90) buffer.writeCharCode(unit);
  }
  return buffer.toString();
}

/// A player fits a slot when their declared position belongs to the slot's
/// compatibility group (kPositionGroups), tolerating long-form labels such as
/// "DEFENSEUR" or "ATTAQUANT".
bool _fitsSlot(String slotLabel, String playerPosition) {
  final pos = _normalizePosition(playerPosition);
  if (pos.isEmpty) return false;
  final group = kPositionGroups[slotLabel.toUpperCase()] ?? [slotLabel];
  for (final entry in group) {
    final g = _normalizePosition(entry);
    if (g.isEmpty) continue;
    if (pos == g) return true;
    if (g.length >= 2 && pos.contains(g)) return true;
    if (pos.length >= 2 && g.contains(pos)) return true;
  }
  return false;
}

String _zoneOf(String slotLabel) {
  final l = slotLabel.toUpperCase();
  if (l == 'GK') return 'G';
  if (_kDefenderPositions.contains(l)) return 'D';
  if (_kMidfielderPositions.contains(l)) return 'M';
  if (_kAttackerPositions.contains(l)) return 'A';
  return 'M';
}

class CoachCompositionScreen extends StatefulWidget {
  const CoachCompositionScreen({super.key});

  @override
  State<CoachCompositionScreen> createState() => _CoachCompositionScreenState();
}

class _CoachCompositionScreenState extends State<CoachCompositionScreen>
    with SingleTickerProviderStateMixin {
  String _formation = '4-3-3';
  List<String?> _starters = List<String?>.filled(11, null);
  final List<String> _subs = [];
  final List<String> _reserves = [];

  String? _captainId;
  String? _viceCaptainId;
  String? _penaltyTakerId;
  String? _freeKickTakerId;
  String? _cornerLeftId;
  String? _cornerRightId;

  bool _booting = true;
  bool _saving = false;
  bool _justSaved = false;
  late final TabController _tabs;

  List<_PitchSlot> get _slots => _kFormations[_formation]!;

  int get _starterCount => _starters.where((id) => id != null).length;

  bool get _isComplete => _starterCount == 11;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prov = context.read<CoachProvider>();
    await prov.loadAll();
    if (!mounted) return;
    final saved = await prov.loadLineup(_formation);
    if (!mounted) return;
    if (saved != null) _applySaved(prov, saved);
    setState(() => _booting = false);
  }

  void _applySaved(CoachProvider prov, Map<String, dynamic> saved) {
    final validIds = {for (final p in prov.players) p.id};

    String? readId(Object? raw) {
      if (raw == null) return null;
      final id = raw is Map
          ? (raw['playerId']?.toString() ?? raw['id']?.toString())
          : raw.toString();
      if (id == null || id.isEmpty || id == 'null') return null;
      return validIds.contains(id) ? id : null;
    }

    final formation = saved['formation']?.toString();
    if (formation != null && _kFormations.containsKey(formation)) {
      _formation = formation;
    }

    final starters = List<String?>.filled(11, null);
    final rawStarters = saved['starters'];
    if (rawStarters is List) {
      for (var i = 0; i < 11 && i < rawStarters.length; i++) {
        starters[i] = readId(rawStarters[i]);
      }
    }

    final taken = <String>{...starters.whereType<String>()};

    List<String> readBench(Object? raw, int max) {
      final out = <String>[];
      if (raw is! List) return out;
      for (final entry in raw) {
        if (out.length >= max) break;
        final id = readId(entry);
        if (id == null || taken.contains(id)) continue;
        taken.add(id);
        out.add(id);
      }
      return out;
    }

    final subs = readBench(saved['subs'], _kMaxSubs);
    final reserves = readBench(saved['reserves'], _kMaxReserves);

    String? readRole(String key) {
      final id = readId(saved[key]);
      return id != null && starters.contains(id) ? id : null;
    }

    setState(() {
      _starters = starters;
      _subs
        ..clear()
        ..addAll(subs);
      _reserves
        ..clear()
        ..addAll(reserves);
      _captainId = readRole('captain');
      _viceCaptainId = readRole('viceCaptain');
      _penaltyTakerId = readRole('penaltyTaker');
      _freeKickTakerId = readRole('freeKickTaker');
      _cornerLeftId = readRole('cornerLeftTaker');
      _cornerRightId = readRole('cornerRightTaker');
    });
  }

  // ---------------------------------------------------------------- helpers

  CoachPlayer? _playerById(CoachProvider prov, String? id) {
    if (id == null) return null;
    for (final p in prov.players) {
      if (p.id == id) return p;
    }
    return null;
  }

  Set<String> get _usedIds => {
        ..._starters.whereType<String>(),
        ..._subs,
        ..._reserves,
      };

  List<CoachPlayer> _starterPlayers(CoachProvider prov) => [
        for (final id in _starters)
          if (_playerById(prov, id) != null) _playerById(prov, id)!,
      ];

  /// Roles can only be held by a player still in the starting XI.
  void _syncRoles() {
    bool stillStarter(String? id) => id != null && _starters.contains(id);
    if (!stillStarter(_captainId)) _captainId = null;
    if (!stillStarter(_viceCaptainId)) _viceCaptainId = null;
    if (!stillStarter(_penaltyTakerId)) _penaltyTakerId = null;
    if (!stillStarter(_freeKickTakerId)) _freeKickTakerId = null;
    if (!stillStarter(_cornerLeftId)) _cornerLeftId = null;
    if (!stillStarter(_cornerRightId)) _cornerRightId = null;
  }

  void _markDirty() {
    if (_justSaved) _justSaved = false;
  }

  void _reset() {
    setState(() {
      _starters = List<String?>.filled(11, null);
      _subs.clear();
      _reserves.clear();
      _syncRoles();
      _markDirty();
    });
  }

  void _changeFormation(String key) {
    if (key == _formation) return;
    setState(() {
      _formation = key;
      _starters = List<String?>.filled(11, null);
      _subs.clear();
      _reserves.clear();
      _syncRoles();
      _markDirty();
    });
  }

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _save(CoachProvider prov) async {
    setState(() => _saving = true);
    await prov.saveLineupData(_formation, {
      'formation': _formation,
      'starters': _starters,
      'subs': List<String>.from(_subs),
      'reserves': List<String>.from(_reserves),
      'captain': _captainId,
      'viceCaptain': _viceCaptainId,
      'penaltyTaker': _penaltyTakerId,
      'freeKickTaker': _freeKickTakerId,
      'cornerLeftTaker': _cornerLeftId,
      'cornerRightTaker': _cornerRightId,
      'matchId': prov.nextMatch?.id,
      'savedAt': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      _justSaved = true;
    });
    _toast('Composition sauvegardée', _kGreen);
  }

  // ----------------------------------------------------------------- picker

  Future<CoachPlayer?> _pickPlayer(
    CoachProvider prov, {
    required String title,
    String? slotLabel,
  }) {
    final used = _usedIds;
    final pool = prov.players
        .where((p) => p.canPlay && !used.contains(p.id))
        .toList();

    final primary = <CoachPlayer>[];
    final secondary = <CoachPlayer>[];
    for (final p in pool) {
      if (slotLabel != null && _fitsSlot(slotLabel, p.position)) {
        primary.add(p);
      } else {
        secondary.add(p);
      }
    }
    if (slotLabel == null) {
      primary
        ..clear()
        ..addAll(pool);
      secondary.clear();
    }
    for (final list in [primary, secondary]) {
      list.sort((a, b) => b.forme.compareTo(a.forme));
    }

    if (pool.isEmpty) {
      _toast('Aucun joueur disponible', _kRed);
      return Future<CoachPlayer?>.value();
    }

    return showGeneralDialog<CoachPlayer>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Fermer',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 170),
      pageBuilder: (ctx, _, _) => SizedBox.expand(
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: _PlayerPickerDialog(
                title: title,
                slotLabel: slotLabel,
                primary: primary,
                secondary: secondary,
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _onSlotTap(CoachProvider prov, int index) async {
    final current = _starters[index];
    if (current != null) {
      setState(() {
        _starters[index] = null;
        _syncRoles();
        _markDirty();
      });
      return;
    }
    final slot = _slots[index];
    final picked = await _pickPlayer(
      prov,
      title: 'Titulaire · ${slot.label}',
      slotLabel: slot.label,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _starters[index] = picked.id;
      _markDirty();
    });
  }

  Future<void> _addSub(CoachProvider prov) async {
    if (_subs.length >= _kMaxSubs) return;
    final picked = await _pickPlayer(prov, title: 'Ajouter un remplaçant');
    if (picked == null || !mounted) return;
    setState(() {
      _subs.add(picked.id);
      _markDirty();
    });
  }

  Future<void> _addReserve(CoachProvider prov) async {
    if (_reserves.length >= _kMaxReserves) return;
    final picked = await _pickPlayer(prov, title: 'Ajouter un réserviste');
    if (picked == null || !mounted) return;
    setState(() {
      _reserves.add(picked.id);
      _markDirty();
    });
  }

  void _sendToSubs(CoachPlayer p) {
    if (_subs.length >= _kMaxSubs) {
      _toast('Banc complet ($_kMaxSubs remplaçants)', _kRed);
      return;
    }
    setState(() {
      _subs.add(p.id);
      _markDirty();
    });
  }

  void _sendToReserves(CoachPlayer p) {
    if (_reserves.length >= _kMaxReserves) {
      _toast('Réserve complète', _kRed);
      return;
    }
    setState(() {
      _reserves.add(p.id);
      _markDirty();
    });
  }

  void _removeFromBench(String id) {
    setState(() {
      _subs.remove(id);
      _reserves.remove(id);
      _markDirty();
    });
  }

  // ---------------------------------------------------------------- metrics

  _TeamMetrics _metrics(CoachProvider prov) {
    final starters = _starterPlayers(prov);
    if (starters.isEmpty) return const _TeamMetrics.empty();

    var forme = 0;
    var fatigue = 0;
    var fitting = 0;
    for (var i = 0; i < _starters.length; i++) {
      final p = _playerById(prov, _starters[i]);
      if (p == null) continue;
      forme += p.forme;
      fatigue += p.fatigue;
      if (_fitsSlot(_slots[i].label, p.position)) fitting++;
    }

    final count = starters.length;
    final avgForme = (forme / count).round();
    final avgFatigue = (fatigue / count).round();
    final cohesion = ((fitting / count) * 100).round();
    final completion = (count / 11) * 100;
    final readiness = (avgForme * 0.4 +
            (100 - avgFatigue) * 0.25 +
            cohesion * 0.2 +
            completion * 0.15)
        .round()
        .clamp(0, 100);

    var g = 0;
    var d = 0;
    var m = 0;
    var a = 0;
    for (var i = 0; i < _starters.length; i++) {
      if (_starters[i] == null) continue;
      switch (_zoneOf(_slots[i].label)) {
        case 'G':
          g++;
        case 'D':
          d++;
        case 'M':
          m++;
        default:
          a++;
      }
    }

    return _TeamMetrics(
      hasStarters: true,
      forme: avgForme,
      fatigue: avgFatigue,
      cohesion: cohesion,
      readiness: readiness,
      keepers: g,
      defenders: d,
      midfielders: m,
      attackers: a,
    );
  }

  List<_Advice> _alerts(CoachProvider prov) {
    final out = <_Advice>[];
    final empty = 11 - _starterCount;

    final hasKeeper = () {
      for (var i = 0; i < _starters.length; i++) {
        if (_slots[i].label == 'GK' && _starters[i] != null) return true;
      }
      return false;
    }();

    if (!hasKeeper) {
      out.add(const _Advice(
        'Aucun gardien positionné dans le onze de départ.',
        Icons.sports_handball,
        _kRed,
      ));
    }
    if (empty > 0) {
      out.add(_Advice(
        '$empty poste${empty > 1 ? 's' : ''} encore vacant${empty > 1 ? 's' : ''} sur le terrain.',
        Icons.grid_off,
        _kAmber,
      ));
    }
    if (_captainId == null) {
      out.add(const _Advice(
        'Capitaine non désigné.',
        Icons.star_border,
        _kAmber,
      ));
    }
    if (_viceCaptainId == null) {
      out.add(const _Advice(
        'Vice-capitaine non désigné.',
        Icons.star_half,
        _kAmber,
      ));
    }

    final tired = <String>[];
    final offPosition = <String>[];
    for (var i = 0; i < _starters.length; i++) {
      final p = _playerById(prov, _starters[i]);
      if (p == null) continue;
      if (p.fatigue >= 75) tired.add('${p.shortName} (${p.fatigue}%)');
      if (!_fitsSlot(_slots[i].label, p.position)) {
        offPosition.add('${p.shortName} → ${_slots[i].label}');
      }
    }
    if (tired.isNotEmpty) {
      out.add(_Advice(
        'Fatigue élevée : ${tired.join(', ')}.',
        Icons.battery_alert,
        _kRed,
      ));
    }
    if (offPosition.isNotEmpty) {
      out.add(_Advice(
        'Hors de leur poste : ${offPosition.join(', ')}.',
        Icons.swap_horiz,
        _kPurple,
      ));
    }
    return out;
  }

  List<_Advice> _suggestions(CoachProvider prov, _TeamMetrics m) {
    final out = <_Advice>[];

    final tired = <CoachPlayer>[];
    for (final p in _starterPlayers(prov)) {
      if (p.fatigue > 65) tired.add(p);
    }
    if (tired.isNotEmpty) {
      out.add(_Advice(
        'Envisager une rotation pour ${tired.map((p) => p.shortName).join(', ')} : charge au-dessus de 65%.',
        Icons.autorenew,
        _kAmber,
      ));
    }
    if (m.hasStarters && m.defenders < 3) {
      out.add(const _Advice(
        'Moins de 3 défenseurs de champ : bloc arrière exposé sur les transitions.',
        Icons.shield_outlined,
        _kRed,
      ));
    }
    if (m.hasStarters && m.attackers == 0) {
      out.add(const _Advice(
        'Aucun attaquant aligné : la sortie de balle manquera de point de fixation.',
        Icons.sports_soccer,
        _kRed,
      ));
    }
    if (m.hasStarters && m.fatigue > 60) {
      out.add(const _Advice(
        'Fatigue moyenne élevée : privilégier un bloc médian et une gestion des temps forts.',
        Icons.speed,
        _kAmber,
      ));
    }
    if (m.hasStarters && m.cohesion < 70) {
      out.add(const _Advice(
        'Cohésion faible : plusieurs joueurs évoluent hors de leur poste de prédilection.',
        Icons.hub_outlined,
        _kPurple,
      ));
    }

    final used = _usedIds;
    final inForm = prov.players
        .where((p) => p.canPlay && p.forme >= 80 && !used.contains(p.id))
        .toList()
      ..sort((a, b) => b.forme.compareTo(a.forme));
    if (inForm.isNotEmpty) {
      final names = inForm.take(3).map((p) => '${p.shortName} (${p.forme}%)');
      out.add(_Advice(
        'En pleine forme et non retenus : ${names.join(', ')}.',
        Icons.trending_up,
        _kGreen,
      ));
    }
    if (_subs.length < 3) {
      out.add(_Advice(
        'Banc trop court (${_subs.length}) : viser au moins 3 remplaçants dont un gardien.',
        Icons.event_seat,
        _kBlue,
      ));
    }
    if (_isComplete && out.isEmpty) {
      out.add(const _Advice(
        'Onze équilibré et frais : aucune correction majeure recommandée.',
        Icons.verified,
        _kGreen,
      ));
    }
    return out;
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final prov = context.watch<CoachProvider>();
    final metrics = _metrics(prov);
    final alerts = _alerts(prov);
    final suggestions = _suggestions(prov, metrics);
    final starters = _starterPlayers(prov);

    final used = _usedIds;
    final availableSquad = prov.disponibles
        .where((p) => !used.contains(p.id))
        .toList()
      ..sort((a, b) => b.forme.compareTo(a.forme));

    return OdinBackdrop(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _isComplete
          ? Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.fabLift(context)),
              child: _completeBanner(),
            )
          : null,
      body: _booting
          ? Center(child: CircularProgressIndicator(color: _kAccent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Composition d\'équipe',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: OdinColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_starterCount/11 · ${_subs.length} remp · ${_reserves.length} rés',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: OdinColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Réinitialiser',
                        onPressed: _reset,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        icon: Icon(
                          Icons.restart_alt,
                          size: 20,
                          color: OdinColors.textMuted,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving ? null : () => _save(prov),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: (_justSaved ? _kGreen : _kAccent)
                              .withValues(alpha: 0.14),
                        ),
                        icon: _saving
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _kAccent,
                                ),
                              )
                            : Icon(
                                _justSaved ? Icons.check_circle : Icons.save_outlined,
                                size: 15,
                                color: _justSaved ? _kGreen : _kAccent,
                              ),
                        label: Text(
                          _justSaved ? 'Enregistré' : 'Sauvegarder',
                          maxLines: 1,
                          style: TextStyle(
                            color: _justSaved ? _kGreen : _kAccent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (prov.nextMatch != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: _matchBanner(prov),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Container(
                    decoration: BoxDecoration(
                      color: OdinColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      indicator: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: _kAccent,
                      unselectedLabelColor: OdinColors.textMuted,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: 'Terrain'),
                        Tab(text: 'Banc'),
                        Tab(text: 'Staff'),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      // Tab 1 — Terrain
                      ListView(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, AppSpacing.bottomNav),
                        children: [
                          _sectionTitle(
                            'Formation',
                            Icons.dashboard_customize_outlined,
                          ),
                          const SizedBox(height: 10),
                          _formationChips(),
                          const SizedBox(height: 16),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: _PitchBoard(
                                slots: _slots,
                                starters: _starters,
                                captainId: _captainId,
                                playerOf: (id) => _playerById(prov, id),
                                onTapSlot: (i) => _onSlotTap(prov, i),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _legend(),
                        ],
                      ),
                      // Tab 2 — Banc
                      ListView(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, AppSpacing.bottomNav),
                        children: [
                          _benchSection(
                            prov,
                            title: 'Remplaçants',
                            icon: Icons.event_seat_outlined,
                            ids: _subs,
                            max: _kMaxSubs,
                            accent: _kAccent,
                            emptyLabel: 'Aucun remplaçant sélectionné',
                            addLabel: 'Ajouter un remplaçant',
                            onAdd: () => _addSub(prov),
                          ),
                          const SizedBox(height: 20),
                          _benchSection(
                            prov,
                            title: 'Réservistes',
                            icon: Icons.groups_2_outlined,
                            ids: _reserves,
                            max: _kMaxReserves,
                            accent: _kBlue,
                            emptyLabel: 'Aucun réserviste sélectionné',
                            addLabel: 'Ajouter un réserviste',
                            onAdd: () => _addReserve(prov),
                          ),
                          const SizedBox(height: 16),
                          _SurfaceCard(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  'Effectif disponible',
                                  Icons.groups_outlined,
                                  trailing: '(${availableSquad.length})',
                                ),
                                const SizedBox(height: 10),
                                if (availableSquad.isEmpty)
                                  Text(
                                    'Tous les joueurs sont placés ✓',
                                    style: TextStyle(
                                      color:
                                          OdinColors.textMuted,
                                      fontSize: 12.5,
                                    ),
                                  )
                                else
                                  ...availableSquad.map(
                                    (p) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _AvailableRow(
                                        player: p,
                                        canSub: _subs.length < _kMaxSubs,
                                        canReserve:
                                            _reserves.length < _kMaxReserves,
                                        onSub: () => _sendToSubs(p),
                                        onReserve: () => _sendToReserves(p),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SurfaceCard(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INDISPONIBLES',
                                  style: TextStyle(
                                    color: _kRed.withValues(alpha: 0.95),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (prov.indisponibles.isEmpty)
                                  Text(
                                    'Aucune indisponibilité déclarée.',
                                    style: TextStyle(
                                      color:
                                          OdinColors.textMuted,
                                      fontSize: 12.5,
                                    ),
                                  )
                                else
                                  ...prov.indisponibles.map(
                                    (p) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: _UnavailableRow(player: p),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Tab 3 — Staff
                      ListView(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, AppSpacing.bottomNav),
                        children: [
                          _metricsPanel(metrics),
                          const SizedBox(height: 22),
                          _responsibilitiesPanel(starters),
                          const SizedBox(height: 22),
                          _advicePanel(
                            'Alertes tactiques',
                            Icons.warning_amber_rounded,
                            _kAmber,
                            alerts,
                            'Aucune alerte : la feuille de match est conforme.',
                          ),
                          const SizedBox(height: 20),
                          _advicePanel(
                            'Suggestions IA',
                            Icons.auto_awesome,
                            _kPurple,
                            suggestions,
                            'Complétez le onze pour obtenir des recommandations.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    ),
    );
  }

  // ------------------------------------------------------------- UI pieces

  Widget _sectionTitle(String label, IconData icon, {String? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 17, color: _kAccent.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: OdinColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: TextStyle(
              color: OdinColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _matchBanner(CoachProvider prov) {
    final match = prov.nextMatch!;
    final days = prov.daysToNextMatch;
    return _SurfaceCard(
      color: _kAccent.withValues(alpha: 0.09),
      borderColor: _kAccent.withValues(alpha: 0.32),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: _kAccent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Composition pour vs ${match.opponent}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: OdinColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    if (match.competition.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        match.competition,
                        style: TextStyle(
                          color: OdinColors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (days != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    days <= 0 ? 'Jour J' : 'J-$days',
                    style: TextStyle(
                      color: _kAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (match.matchDate.isNotEmpty)
                _Pill(
                  icon: Icons.calendar_today_outlined,
                  label: match.matchDate,
                ),
              if (match.homeAwayLabel.isNotEmpty)
                _Pill(
                  icon: Icons.place_outlined,
                  label: match.homeAwayLabel,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formationChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kFormations.length,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (_, i) {
          final key = _kFormations.keys.elementAt(i);
          final active = key == _formation;
          return GestureDetector(
            onTap: () => _changeFormation(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? _kAccent.withValues(alpha: 0.16)
                    : OdinColors.inputFill,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active
                      ? _kAccent.withValues(alpha: 0.6)
                      : OdinColors.inputFill,
                ),
              ),
              child: Text(
                key,
                style: TextStyle(
                  color: active ? _kAccent : OdinColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _legend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            _LegendItem(color: _kAccent, label: 'Titulaire'),
            const _LegendItem(color: _kYellow, label: 'Gardien'),
            _LegendItem(
              color: OdinColors.textMuted,
              label: 'Poste libre',
              dashed: true,
            ),
            _LegendItem(color: _kAccent, label: 'Capitaine', star: true),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'tap = placer · joueur = retirer',
          style: TextStyle(
            color: OdinColors.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _benchSection(
    CoachProvider prov, {
    required String title,
    required IconData icon,
    required List<String> ids,
    required int max,
    required Color accent,
    required String emptyLabel,
    required String addLabel,
    required VoidCallback onAdd,
  }) {
    final players = [
      for (final id in ids)
        if (_playerById(prov, id) != null) _playerById(prov, id)!,
    ];

    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title, icon, trailing: '${ids.length}/$max'),
          const SizedBox(height: 12),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                emptyLabel,
                style: TextStyle(
                  color: OdinColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            )
          else
            ...players.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _BenchPlayerCard(
                  player: p,
                  accent: accent,
                  onRemove: () => _removeFromBench(p.id),
                ),
              ),
            ),
          if (ids.length < max) ...[
            const SizedBox(height: 4),
            _DashedAddButton(
              label: addLabel,
              color: accent,
              onTap: onAdd,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricsPanel(_TeamMetrics m) {
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Métriques équipe', Icons.monitor_heart_outlined),
          const SizedBox(height: 16),
          _MetricBar(
            label: 'Forme moyenne',
            value: m.hasStarters ? m.forme : null,
            color: _kRed,
          ),
          const SizedBox(height: 14),
          _MetricBar(
            label: 'Fatigue moyenne',
            value: m.hasStarters ? m.fatigue : null,
            color: _kGreen,
          ),
          const SizedBox(height: 14),
          _MetricBar(
            label: 'Cohésion équipe',
            value: m.hasStarters ? m.cohesion : null,
            color: _kRed,
          ),
          const SizedBox(height: 14),
          _MetricBar(
            label: 'Préparation match',
            value: m.hasStarters ? m.readiness : null,
            color: _kAccent,
          ),
        ],
      ),
    );
  }

  Widget _responsibilitiesPanel(List<CoachPlayer> starters) {
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Responsabilités match', Icons.star_outline),
          const SizedBox(height: 14),
          _RoleDropdown(
            label: 'CAPITAINE',
            icon: Icons.workspace_premium,
            value: _captainId,
            options: starters,
            onChanged: (v) => setState(() {
              _captainId = v;
              _markDirty();
            }),
          ),
          const SizedBox(height: 12),
          _RoleDropdown(
            label: 'VICE-CAPITAINE',
            icon: Icons.military_tech_outlined,
            value: _viceCaptainId,
            options: starters,
            onChanged: (v) => setState(() {
              _viceCaptainId = v;
              _markDirty();
            }),
          ),
          const SizedBox(height: 12),
          _RoleDropdown(
            label: 'TIREUR PENALTYS',
            icon: Icons.sports_soccer,
            value: _penaltyTakerId,
            options: starters,
            onChanged: (v) => setState(() {
              _penaltyTakerId = v;
              _markDirty();
            }),
          ),
          const SizedBox(height: 12),
          _RoleDropdown(
            label: 'COUPS FRANCS',
            icon: Icons.my_location_outlined,
            value: _freeKickTakerId,
            options: starters,
            onChanged: (v) => setState(() {
              _freeKickTakerId = v;
              _markDirty();
            }),
          ),
          const SizedBox(height: 12),
          _RoleDropdown(
            label: 'CORNERS GAUCHE',
            icon: Icons.north_west,
            value: _cornerLeftId,
            options: starters,
            onChanged: (v) => setState(() {
              _cornerLeftId = v;
              _markDirty();
            }),
          ),
          const SizedBox(height: 12),
          _RoleDropdown(
            label: 'CORNERS DROIT',
            icon: Icons.north_east,
            value: _cornerRightId,
            options: starters,
            onChanged: (v) => setState(() {
              _cornerRightId = v;
              _markDirty();
            }),
          ),
        ],
      ),
    );
  }

  Widget _advicePanel(
    String title,
    IconData icon,
    Color color,
    List<_Advice> items,
    String emptyLabel,
  ) {
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: OdinColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (items.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              emptyLabel,
              style: TextStyle(
                color: OdinColors.textMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            )
          else
            ...items.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.08),
                      border: Border(
                        left: BorderSide(color: a.color, width: 3),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(a.icon, size: 16, color: a.color),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            a.text,
                            style: TextStyle(
                              color: OdinColors.textPrimary,
                              fontSize: 12.5,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _completeBanner() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: _SurfaceCard(
          color: _kGreen.withValues(alpha: 0.12),
          borderColor: _kGreen.withValues(alpha: 0.40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: _kGreen, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Onze de départ complet · ${_subs.length} remplaçant${_subs.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: _kGreen,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formation,
                style: TextStyle(
                  color: _kGreen.withValues(alpha: 0.8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================== value objects

class _TeamMetrics {
  const _TeamMetrics({
    required this.hasStarters,
    required this.forme,
    required this.fatigue,
    required this.cohesion,
    required this.readiness,
    required this.keepers,
    required this.defenders,
    required this.midfielders,
    required this.attackers,
  });

  const _TeamMetrics.empty()
      : hasStarters = false,
        forme = 0,
        fatigue = 0,
        cohesion = 0,
        readiness = 0,
        keepers = 0,
        defenders = 0,
        midfielders = 0,
        attackers = 0;

  final bool hasStarters;
  final int forme;
  final int fatigue;
  final int cohesion;
  final int readiness;
  final int keepers;
  final int defenders;
  final int midfielders;
  final int attackers;
}

class _Advice {
  const _Advice(this.text, this.icon, this.color);

  final String text;
  final IconData icon;
  final Color color;
}

// ============================================================== components

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      raised: borderColor != null,
      accentColor: borderColor ?? OdinColors.accent,
      padding: padding,
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: OdinColors.inputFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: OdinColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: OdinColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
    this.star = false,
  });

  final Color color;
  final String label;
  final bool dashed;
  final bool star;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (star)
          Icon(Icons.star, size: 13, color: color)
        else if (dashed)
          SizedBox(
            width: 13,
            height: 13,
            child: CustomPaint(painter: _DashedCirclePainter(color: color)),
          )
        else
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: OdinColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final progress = ((v ?? 0) / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: OdinColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final tipLeft =
                (constraints.maxWidth * progress - 5).clamp(0.0, constraints.maxWidth - 10);
            return SizedBox(
              height: 10,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 6,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: OdinColors.inputFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  if (v != null)
                    Positioned(
                      left: tipLeft,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _BenchPlayerCard extends StatelessWidget {
  const _BenchPlayerCard({
    required this.player,
    required this.accent,
    required this.onRemove,
  });

  final CoachPlayer player;
  final Color accent;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withValues(alpha: 0.45)),
              ),
              child: Text(
                player.number > 0 ? '${player.number}' : player.initials,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: OdinColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${player.position} · Forme ${player.forme}%',
                    style: TextStyle(
                      color: OdinColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: OdinColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedAddButton extends StatelessWidget {
  const _DashedAddButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, size: 17, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailableRow extends StatelessWidget {
  const _AvailableRow({
    required this.player,
    required this.canSub,
    required this.canReserve,
    required this.onSub,
    required this.onReserve,
  });

  final CoachPlayer player;
  final bool canSub;
  final bool canReserve;
  final VoidCallback onSub;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: OdinColors.inputFill,
          border: Border.all(color: OdinColors.panelBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _kAccent.withValues(alpha: 0.40)),
              ),
              child: Text(
                player.number > 0 ? '${player.number}' : player.initials,
                style: TextStyle(
                  color: _kAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: OdinColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${player.position} · Forme ${player.forme}% · Fatigue ${player.fatigue}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: OdinColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _MiniButton(
              label: 'Rem.',
              color: _kAccent,
              enabled: canSub,
              onTap: onSub,
            ),
            const SizedBox(width: 6),
            _MiniButton(
              label: 'Rés.',
              color: _kBlue,
              enabled: canReserve,
              onTap: onReserve,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : OdinColors.textMuted;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.12),
            border: Border.all(color: c.withValues(alpha: 0.38)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _UnavailableRow extends StatelessWidget {
  const _UnavailableRow({required this.player});

  final CoachPlayer player;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF3A1A1A),
          border: Border.all(color: _kRed.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: _kRed.withValues(alpha: 0.40)),
              ),
              child: Text(
                player.number > 0 ? '${player.number}' : '0',
                style: TextStyle(
                  color: OdinColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: OdinColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              player.lineupStatusLabel,
              style: TextStyle(
                color: _kRed,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<CoachPlayer> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue =
        options.any((p) => p.id == value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: safeValue != null
                  ? _kAccent
                  : OdinColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: OdinColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF161625),
              border: Border.all(color: OdinColors.panelBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: safeValue,
                isExpanded: true,
                isDense: true,
                dropdownColor: _kCard,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(
                  Icons.expand_more,
                  size: 18,
                  color: OdinColors.textMuted,
                ),
                hint: Text(
                  options.isEmpty ? 'Aucun titulaire' : '— Choisir —',
                  style: TextStyle(
                    color: OdinColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      '— Choisir —',
                      style: TextStyle(
                        color: OdinColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  for (final p in options)
                    DropdownMenuItem<String?>(
                      value: p.id,
                      child: Text(
                        p.shortName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
                onChanged: options.isEmpty ? null : onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================== picker

class _PlayerPickerDialog extends StatelessWidget {
  const _PlayerPickerDialog({
    required this.title,
    required this.slotLabel,
    required this.primary,
    required this.secondary,
  });

  final String title;
  final String? slotLabel;
  final List<CoachPlayer> primary;
  final List<CoachPlayer> secondary;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      width: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: BoxConstraints(
        maxWidth: media.size.width - 40,
        maxHeight: media.size.height * 0.76,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            border: Border.all(color: OdinColors.panelBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          size: 19,
                          color: OdinColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${primary.length + secondary.length} joueur(s) disponible(s)',
                    style: TextStyle(
                      color: OdinColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  children: [
                    if (primary.isNotEmpty) ...[
                      _header(
                        slotLabel == null
                            ? 'Effectif disponible'
                            : 'Postes compatibles · $slotLabel',
                        _kGreen,
                      ),
                      ...primary.map((p) => _tile(context, p, true)),
                    ],
                    if (secondary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _header('Autres joueurs', OdinColors.textMuted),
                      ...secondary.map((p) => _tile(context, p, false)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, CoachPlayer p, bool compatible) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: GestureDetector(
        onTap: () => Navigator.of(context, rootNavigator: true).pop(p),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: compatible
                  ? _kGreen.withValues(alpha: 0.06)
                  : OdinColors.inputFill,
              border: Border.all(
                color: compatible
                    ? _kGreen.withValues(alpha: 0.22)
                    : OdinColors.panelBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    p.number > 0 ? '${p.number}' : p.initials,
                    style: TextStyle(
                      color: _kAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${p.position} · Forme ${p.forme}% · Fatigue ${p.fatigue}%',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: OdinColors.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  size: 19,
                  color: compatible ? _kGreen : _kAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =================================================================== pitch

class _PitchBoard extends StatelessWidget {
  const _PitchBoard({
    required this.slots,
    required this.starters,
    required this.captainId,
    required this.playerOf,
    required this.onTapSlot,
  });

  final List<_PitchSlot> slots;
  final List<String?> starters;
  final String? captainId;
  final CoachPlayer? Function(String? id) playerOf;
  final ValueChanged<int> onTapSlot;

  /// Portrait stadium — taller than wide (attack top, GK bottom).
  static const _aspectRatio = 0.68;
  static const _slotSize = 38.0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _PitchLinesPainter()),
                    ),
                    for (var i = 0; i < slots.length; i++) _slot(i, w, h),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _slot(int i, double w, double h) {
    final slot = slots[i];
    final player = playerOf(i < starters.length ? starters[i] : null);
    final isCaptain = player != null && player.id == captainId;
    final isKeeper = slot.label == 'GK';
    final color = isKeeper ? _kYellow : _kAccent;

    final maxLeft = (w - _slotSize).clamp(0.0, double.infinity);
    final maxTop = (h - _slotSize).clamp(0.0, double.infinity);
    final left = ((slot.x / 100) * w - _slotSize / 2).clamp(0.0, maxLeft);
    final top = ((slot.y / 100) * h - _slotSize / 2).clamp(0.0, maxTop);

    return Positioned(
      left: left,
      top: top,
      width: _slotSize,
      height: _slotSize,
      child: GestureDetector(
        onTap: () => onTapSlot(i),
        behavior: HitTestBehavior.opaque,
        child: player == null
            ? _emptySlot(slot.label)
            : _filledSlot(player, color, isCaptain),
      ),
    );
  }

  /// Dashed circle + position code only (no subtitle — matches picture 2).
  Widget _emptySlot(String label) {
    return SizedBox(
      width: _slotSize,
      height: _slotSize,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: OdinColors.textSecondary,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filledSlot(CoachPlayer player, Color color, bool isCaptain) {
    return SizedBox(
      width: _slotSize,
      height: _slotSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _slotSize - 2,
            height: _slotSize - 2,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.90),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              player.number > 0 ? '${player.number}' : player.initials,
              style: TextStyle(
                color: Color(0xFF0B0B14),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          if (isCaptain)
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(Icons.star, size: 11, color: Color(0xFFFFB020)),
            ),
        ],
      ),
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mowing stripes (portrait bands)
    const light = Color(0xFF2E9B4A);
    const dark = Color(0xFF24803C);
    final bandH = size.height / 10;
    for (var i = 0; i < 10; i++) {
      final paint = Paint()..color = i.isEven ? light : dark;
      canvas.drawRect(
        Rect.fromLTWH(0, i * bandH, size.width, bandH + 0.5),
        paint,
      );
    }

    final line = Paint()
      ..color = OdinColors.textMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      line,
    );

    // Halfway line
    canvas.drawLine(
      Offset(rect.left, rect.center.dy),
      Offset(rect.right, rect.center.dy),
      line,
    );

    // Center circle + spot
    final centerR = size.width * 0.14;
    canvas.drawCircle(rect.center, centerR, line);
    canvas.drawCircle(
      rect.center,
      2.2,
      Paint()
        ..color = OdinColors.textMuted
        ..style = PaintingStyle.fill,
    );

    // Penalty areas (top = attack, bottom = GK) — portrait proportions
    final boxW = size.width * 0.58;
    final boxH = size.height * 0.145;
    final boxLeft = rect.center.dx - boxW / 2;
    canvas.drawRect(Rect.fromLTWH(boxLeft, rect.top, boxW, boxH), line);
    canvas.drawRect(
      Rect.fromLTWH(boxLeft, rect.bottom - boxH, boxW, boxH),
      line,
    );

    final sixW = size.width * 0.30;
    final sixH = size.height * 0.060;
    final sixLeft = rect.center.dx - sixW / 2;
    canvas.drawRect(Rect.fromLTWH(sixLeft, rect.top, sixW, sixH), line);
    canvas.drawRect(
      Rect.fromLTWH(sixLeft, rect.bottom - sixH, sixW, sixH),
      line,
    );

    // Goal mouths
    final goalW = size.width * 0.14;
    final goalH = 4.0;
    final goalLeft = rect.center.dx - goalW / 2;
    canvas.drawRect(Rect.fromLTWH(goalLeft, rect.top - 1, goalW, goalH), line);
    canvas.drawRect(
      Rect.fromLTWH(goalLeft, rect.bottom - goalH + 1, goalW, goalH),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  static const _strokeWidth = 1.4;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    final path = Path()
      ..addOval(
        Rect.fromLTWH(
          _strokeWidth / 2,
          _strokeWidth / 2,
          size.width - _strokeWidth,
          size.height - _strokeWidth,
        ),
      );

    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}
