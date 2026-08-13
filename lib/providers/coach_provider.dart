import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coach_models.dart';
import '../services/coach_api.dart';
import '../services/responsable_api.dart';

class CoachProvider extends ChangeNotifier {
  CoachProvider(this._api);
  final CoachApi _api;

  CoachApi get api => _api;

  static const _kAttendance = 'odin_attendance';
  static const _kMatchAnalysis = 'odin_match_analysis_v2';

  List<CoachPlayer> players = [];
  List<CoachSession> sessions = [];
  List<CoachMatch> matches = [];
  List<CoachMatch> upcomingMatches = [];
  CoachMatch? nextMatch;
  Set<String> injuredNames = {};
  Map<String, Map<String, String>> attendanceBySession = {};
  List<Map<String, dynamic>> attendanceHistory = [];
  Map<String, dynamic>? trainingSummary;
  Map<String, dynamic>? savedLineup;
  List<ClubNotificationItem> notifications = [];
  bool loading = false;
  bool bootstrapped = false;
  String? error;

  int get unreadNotifications => notifications.where((n) => !n.read).length;

  Future<void> loadAll({bool force = false}) async {
    if (loading) return;
    if (bootstrapped && !force) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      await Future.wait([
        _loadPlayers(),
        _loadCalendar(),
        _loadMatches(),
        _loadTraining(),
        _loadInjuries(),
        _loadCharge(),
        _loadLocal(),
        _loadNotifications(),
      ]);
    } catch (e) {
      error = e.toString();
    } finally {
      bootstrapped = true;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadNotifications() async {
    try {
      notifications = await _api.getNotifications();
    } catch (_) {
      notifications = notifications;
    }
  }

  Future<void> refreshNotifications() async {
    await _loadNotifications();
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final ids = notifications.where((n) => !n.read).map((n) => n.id).toList();
    if (ids.isEmpty) return;
    await _api.markNotificationsRead(ids);
    notifications = notifications
        .map((n) => ClubNotificationItem(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              date: n.date,
              read: true,
              path: n.path,
              level: n.level,
            ))
        .toList();
    notifyListeners();
  }

  Future<void> markRead(List<String> ids) async {
    if (ids.isEmpty) return;
    await _api.markNotificationsRead(ids);
    notifications = notifications
        .map((n) => ids.contains(n.id)
            ? ClubNotificationItem(
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                date: n.date,
                read: true,
                path: n.path,
                level: n.level,
              )
            : n)
        .toList();
    notifyListeners();
  }

  Future<void> _loadPlayers() async {
    final raw = await _api.getPlayers();
    players = raw
        .map((e) => CoachPlayer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _loadCalendar() async {
    final raw = await _api.getCalendar();
    sessions = raw
        .map((e) => CoachSession.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  Future<void> _loadMatches() async {
    final raw = await _api.getMatches();
    final past = (raw['past'] as List? ?? [])
        .map((e) => CoachMatch.fromJson(e as Map<String, dynamic>))
        .toList();
    upcomingMatches = (raw['upcoming'] as List? ?? [])
        .map((e) => CoachMatch.fromJson(e as Map<String, dynamic>))
        .toList();
    matches = [...upcomingMatches, ...past];
    if (raw['nextMatch'] is Map) {
      nextMatch =
          CoachMatch.fromJson(raw['nextMatch'] as Map<String, dynamic>);
    } else if (upcomingMatches.isNotEmpty) {
      nextMatch = upcomingMatches.first;
    } else {
      nextMatch = null;
    }
  }

  Future<void> _loadTraining() async {
    try {
      trainingSummary = await _api.getTraining();
    } catch (_) {
      trainingSummary = null;
    }
  }

  Future<void> _loadInjuries() async {
    try {
      final raw = await _api.getInjuries();
      final list = raw['injured'] as List? ?? [];
      injuredNames = list
          .map((e) => (e as Map)['name']?.toString().toLowerCase() ?? '')
          .where((n) => n.isNotEmpty)
          .toSet();
    } catch (_) {
      injuredNames = {};
    }
  }

  Future<void> _loadCharge() async {
    try {
      final raw = await _api.getCharge();
      final list = raw['players'] as List? ?? [];
      final byId = <String, Map>{};
      for (final e in list) {
        final m = e as Map;
        final id = m['id']?.toString();
        if (id != null) byId[id] = m;
      }
      for (final p in players) {
        final c = byId[p.id];
        if (c != null) {
          p.forme = (c['loadScore'] as num?)?.toInt() ?? p.forme;
          p.fatigue = (c['fatigueScore'] as num?)?.toInt() ?? p.fatigue;
        }
      }
    } catch (_) {
      // defaults already on players
    }
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final attRaw = prefs.getString(_kAttendance);
    if (attRaw != null) {
      try {
        final decoded = jsonDecode(attRaw);
        if (decoded is List) {
          attendanceHistory = List<Map<String, dynamic>>.from(
            decoded.map((e) => Map<String, dynamic>.from(e as Map)),
          );
          for (final h in attendanceHistory) {
            final sid = h['sessionId']?.toString();
            final records = h['records'];
            if (sid != null && records is Map) {
              attendanceBySession[sid] = Map<String, String>.from(
                records.map((k, v) => MapEntry('$k', '$v')),
              );
            }
          }
        }
      } catch (_) {}
    }
  }

  List<CoachSession> get trainings =>
      sessions.where((s) => s.isTraining).toList();

  List<CoachSession> get matchEvents =>
      sessions.where((s) => s.isMatch).toList();

  String get _todayKey => DateTime.now().toIso8601String().substring(0, 10);

  CoachSession? get todayTraining {
    final t = _todayKey;
    final list = trainings.where((s) => s.dateKey == t).toList();
    return list.isEmpty ? null : list.first;
  }

  List<CoachSession> get upcomingTrainings {
    final t = _todayKey;
    return trainings.where((s) => s.dateKey.compareTo(t) >= 0).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
  }

  List<CoachSession> get doneTrainings {
    final t = _todayKey;
    return trainings.where((s) => s.dateKey.compareTo(t) < 0).toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  int get sessionsThisWeek {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final startKey = DateTime(start.year, start.month, start.day)
        .toIso8601String()
        .substring(0, 10);
    final end = start.add(const Duration(days: 6));
    final endKey = DateTime(end.year, end.month, end.day)
        .toIso8601String()
        .substring(0, 10);
    return trainings
        .where((s) =>
            s.dateKey.compareTo(startKey) >= 0 &&
            s.dateKey.compareTo(endKey) <= 0)
        .length;
  }

  CoachSession? get nextMatchEvent {
    final t = _todayKey;
    final list = matchEvents.where((s) => s.dateKey.compareTo(t) >= 0).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return list.isEmpty ? null : list.first;
  }

  int? get daysToNextMatch {
    if (nextMatch?.daysUntil != null) return nextMatch!.daysUntil;
    final m = nextMatchEvent;
    if (m == null) return null;
    final d = DateTime.tryParse(m.dateKey);
    if (d == null) return null;
    return d.difference(DateTime.now()).inDays;
  }

  List<CoachPlayer> get disponibles =>
      players.where((p) => p.canPlay).toList();

  List<CoachPlayer> get indisponibles =>
      players.where((p) => p.isUnavailable).toList();

  /// Présence: Exemption médicale seulement si Blessé / LIMITE (pas juste historique blessure)
  bool needsMedicalExemption(CoachPlayer p) =>
      p.isInjured || p.isLimite;

  bool isInjuredPlayer(CoachPlayer p) => needsMedicalExemption(p);

  Future<void> addTraining({
    required String title,
    required String date,
    required String time,
    required String location,
    String? notes,
  }) async {
    await _api.createSession({
      'title': title,
      'eventDate': date,
      'eventTime': time,
      'eventType': 'ENTRAINEMENT',
      'location': location.isEmpty ? 'Terrain principal' : location,
      if (notes != null && notes.isNotEmpty) 'description': notes,
    });
    await _loadCalendar();
    await _loadTraining();
    notifyListeners();
  }

  Map<String, String> attendanceFor(String sessionId) {
    return Map<String, String>.from(attendanceBySession[sessionId] ?? {});
  }

  Future<void> saveAttendanceSheet({
    required String sessionId,
    required String sessionTitle,
    required String date,
    required int rate,
    required Map<String, String> records,
  }) async {
    attendanceBySession[sessionId] = Map<String, String>.from(records);
    final entry = {
      'sessionId': sessionId,
      'sessionTitle': sessionTitle,
      'date': date,
      'rate': rate,
      'records': records,
    };
    attendanceHistory = [
      entry,
      ...attendanceHistory.where((h) => h['sessionId'] != sessionId),
    ].take(20).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAttendance, jsonEncode(attendanceHistory));
    notifyListeners();
  }

  String lineupStorageKey(String formation) {
    final mid = nextMatch?.id;
    if (mid != null && mid.isNotEmpty) return 'odin_lineup_match_$mid';
    return 'odin_lineup_$formation';
  }

  Future<Map<String, dynamic>?> loadLineup(String formation) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(lineupStorageKey(formation));
    if (raw == null && nextMatch != null) {
      final fallback = prefs.getString('odin_lineup_$formation');
      if (fallback == null) return null;
      try {
        return Map<String, dynamic>.from(jsonDecode(fallback) as Map);
      } catch (_) {
        return null;
      }
    }
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLineupData(String formation, Map<String, dynamic> data) async {
    savedLineup = data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lineupStorageKey(formation), jsonEncode(data));
    notifyListeners();
  }

  Future<Map<String, dynamic>?> loadMatchAnalysis(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_kMatchAnalysis}_$matchId');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMatchAnalysis(
      String matchId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_kMatchAnalysis}_$matchId', jsonEncode(data));
    notifyListeners();
  }

  Future<List<CoachContact>> loadContacts({String search = ''}) async {
    final raw = await _api.getMessageContacts(search: search);
    return raw
        .map((e) => CoachContact.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CoachChatMessage>> loadThread(String peerId) async {
    final raw = await _api.getMessageThread(peerId);
    return raw
        .map((e) => CoachChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendChat(String peerId, String text) async {
    await _api.sendMessage(peerId, text);
  }
}
