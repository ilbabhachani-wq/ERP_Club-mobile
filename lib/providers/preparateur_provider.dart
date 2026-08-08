import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/preparateur_api.dart';

class PreparateurDataProvider extends ChangeNotifier {
  PreparateurDataProvider(ApiClient api) : _api = PreparateurApi(api);

  final PreparateurApi _api;

  PreparateurApi get api => _api;

  List<PrepProgram> programs = [];
  List<PrepPlayerOption> players = [];
  PrepChargeData? charge;
  List<PrepPhysicalProfile> condition = [];
  List<PrepNotification> notifications = [];
  bool loading = false;
  String? error;
  bool bootstrapped = false;

  Future<void> load() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getPrograms().catchError((_) => <PrepProgram>[]),
        _api.getPlayers().catchError((_) => <PrepPlayerOption>[]),
        _api.getCharge().catchError(
          (_) => PrepChargeData(players: [], summary: PrepChargeSummary()),
        ),
        _api.getCondition().catchError((_) => <PrepPhysicalProfile>[]),
        _api.getNotifications().catchError((_) => <PrepNotification>[]),
      ]);
      programs = results[0] as List<PrepProgram>;
      players = results[1] as List<PrepPlayerOption>;
      charge = results[2] as PrepChargeData;
      condition = results[3] as List<PrepPhysicalProfile>;
      notifications = results[4] as List<PrepNotification>;
    } catch (e) {
      error = e.toString();
      charge ??= PrepChargeData(players: [], summary: PrepChargeSummary());
    } finally {
      bootstrapped = true;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPrograms() async {
    programs = await _api.getPrograms().catchError((_) => programs);
    notifyListeners();
  }

  Future<void> refreshCharge() async {
    charge = await _api.getCharge().catchError(
      (_) => charge ?? PrepChargeData(players: [], summary: PrepChargeSummary()),
    );
    notifyListeners();
  }

  Future<void> refreshCondition() async {
    condition = await _api.getCondition().catchError((_) => condition);
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    notifications = await _api.getNotifications().catchError((_) => notifications);
    notifyListeners();
  }

  int get unreadNotifications => notifications.where((n) => !n.isRead).length;

  Future<void> markNotificationRead(String id) async {
    await _api.markNotificationRead(id);
    notifications = notifications
        .map((n) => n.id == id
            ? PrepNotification(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                priority: n.priority,
                isRead: true,
                playerName: n.playerName,
                createdAt: n.createdAt,
              )
            : n)
        .toList();
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    await _api.markAllNotificationsRead();
    notifications = notifications
        .map((n) => PrepNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              priority: n.priority,
              isRead: true,
              playerName: n.playerName,
              createdAt: n.createdAt,
            ))
        .toList();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    await _api.deleteNotification(id);
    notifications = notifications.where((n) => n.id != id).toList();
    notifyListeners();
  }

  Future<PrepProgram> createProgram(Map<String, dynamic> body) async {
    final created = await _api.createProgram(body);
    programs = [created, ...programs];
    notifyListeners();
    return created;
  }

  Future<void> updateProgramStatus(String id, String status) async {
    final updated = await _api.updateProgram(id, {'status': status});
    programs = programs.map((p) => p.id == id ? updated : p).toList();
    notifyListeners();
  }

  Future<void> deleteProgram(String id) async {
    await _api.deleteProgram(id);
    programs = programs.where((p) => p.id != id).toList();
    notifyListeners();
  }

  Future<void> reduceCharge(String playerId) async {
    final updated = await _api.reduceCharge(playerId);
    _patchChargePlayer(updated);
  }

  Future<void> increaseCharge(String playerId) async {
    final updated = await _api.increaseCharge(playerId);
    _patchChargePlayer(updated);
  }

  void _patchChargePlayer(PrepChargePlayer updated) {
    final current = charge;
    if (current == null) return;
    final list = current.players.map((p) => p.id == updated.id ? updated : p).toList();
    final critiques = list.where((p) => p.statut == 'Critique').length;
    final attentions = list.where((p) => p.statut == 'Attention').length;
    final avg = list.isEmpty
        ? 0
        : (list.fold<int>(0, (s, p) => s + p.loadScore) / list.length).round();
    charge = PrepChargeData(
      players: list,
      summary: PrepChargeSummary(
        critiques: critiques,
        attentions: attentions,
        avgLoad: avg,
        total: list.length,
      ),
    );
    notifyListeners();
  }
}
