import 'package:flutter/foundation.dart';
import '../models/medecin_models.dart';
import '../services/medecin_api.dart';
import '../services/responsable_api.dart';

class MedecinProvider extends ChangeNotifier {
  MedecinProvider(this._api);
  final MedecinApi _api;

  MedecinApi get api => _api;

  List<MedecinPlayer> players = [];
  List<MedecinInjury> injuries = [];
  List<MedecinEvent> events = [];
  List<MedecinEvent> localEvents = [];
  Map<String, dynamic> kpis = {};
  List<ClubNotificationItem> notifications = [];
  bool loading = false;
  bool bootstrapped = false;
  String? error;

  List<MedecinEvent> get allEvents => [...events, ...localEvents];

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
        _loadInjuries(),
        _loadCalendar(),
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
    } catch (_) {}
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
      .map((e) => MedecinPlayer.fromJson(
        e as Map<String, dynamic>
      ))
      .toList();
  }

  Future<void> _loadInjuries() async {
    final raw = await _api.getInjuries();
    final list = raw['injured'] as List? ?? [];
    final rawKpis = raw['kpis'];
    kpis = rawKpis is Map
        ? Map<String, dynamic>.from(rawKpis)
        : {};
    injuries = list
      .map((e) => MedecinInjury.fromJson(
        e as Map<String, dynamic>
      ))
      .toList();
  }

  Future<void> _loadCalendar() async {
    final raw = await _api.getCalendar();
    events = raw
      .map((e) => MedecinEvent.fromJson(
        e as Map<String, dynamic>
      ))
      .toList();
  }

  // Computed
  List<MedecinPlayer> get disponibles =>
    players.where((p) =>
      p.status.toUpperCase() == 'DISPONIBLE'
    ).toList();

  List<MedecinInjury> get activeInjuries =>
    injuries.where((i) =>
      i.statusLabel == 'Active'
    ).toList();

  List<MedecinInjury> get inReeducation =>
    injuries.where((i) =>
      i.statusLabel == 'En rééducation'
    ).toList();

  List<MedecinEvent> get todayEvents {
    final today = DateTime.now();
    final key =
      '${today.day.toString().padLeft(2,'0')}/'
      '${today.month.toString().padLeft(2,'0')}/'
      '${today.year}';
    return allEvents.where((e) =>
      e.eventDate.startsWith(key) ||
      e.eventDate.startsWith(
        today.toIso8601String().split('T')[0]
      )
    ).toList();
  }

  // Create injury
  Future<void> addInjury(
    Map<String, dynamic> body
  ) async {
    await _api.createInjury(body);
    await _loadInjuries();
    notifyListeners();
  }

  // Create event
  Future<void> addEvent(
    Map<String, dynamic> body
  ) async {
    await _api.createEvent(body);
    await _loadCalendar();
    notifyListeners();
  }

  void addLocalEvent(Map<String, dynamic> data) {
    localEvents.add(MedecinEvent.fromJson(data));
    notifyListeners();
  }
}
