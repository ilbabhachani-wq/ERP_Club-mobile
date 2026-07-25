import 'package:flutter/foundation.dart';
import '../models/scout_models.dart';
import '../services/api_client.dart';
import '../services/scout_api.dart';

class ScoutDataProvider extends ChangeNotifier {
  ScoutDataProvider(ApiClient api) : _scout = ScoutApi(api);

  final ScoutApi _scout;

  ScoutDashboard? dashboard;
  ScoutProfile? profile;
  List<ScoutProspect> prospects = [];
  List<ScoutProspect> watchlist = [];
  List<ScoutReport> reports = [];
  List<ScoutMission> missions = [];
  bool loading = false;
  String? error;

  ScoutApi get api => _scout;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _scout.getDashboard().catchError((_) => const ScoutDashboard()),
        _scout.getProspects().catchError((_) => <ScoutProspect>[]),
        _scout.getWatchlist().catchError((_) => <ScoutProspect>[]),
        _scout.getReports().catchError((_) => <ScoutReport>[]),
        _scout.getMissions().catchError((_) => <ScoutMission>[]),
        _scout.getProfile().catchError((_) => const ScoutProfile()),
      ]);
      dashboard = results[0] as ScoutDashboard;
      prospects = results[1] as List<ScoutProspect>;
      watchlist = results[2] as List<ScoutProspect>;
      reports = results[3] as List<ScoutReport>;
      missions = results[4] as List<ScoutMission>;
      profile = results[5] as ScoutProfile;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    dashboard = await _scout.getDashboard().catchError((_) => dashboard ?? const ScoutDashboard());
    notifyListeners();
  }

  Future<void> refreshWatchlist() async {
    watchlist = await _scout.getWatchlist().catchError((_) => watchlist);
    notifyListeners();
  }

  Future<void> refreshProspects() async {
    prospects = await _scout.getProspects().catchError((_) => prospects);
    notifyListeners();
  }

  Future<void> refreshMissions() async {
    missions = await _scout.getMissions().catchError((_) => missions);
    notifyListeners();
  }

  Future<void> refreshReports() async {
    reports = await _scout.getReports().catchError((_) => reports);
    notifyListeners();
  }

  Future<ScoutProfile> refreshProfile() async {
    profile = await _scout.getProfile();
    notifyListeners();
    return profile!;
  }

  Future<ScoutProfile> updateProfile(Map<String, dynamic> body) async {
    profile = await _scout.updateProfile(body);
    notifyListeners();
    return profile!;
  }

  Future<void> toggleWatchlist(ScoutProspect p, {String priority = 'B'}) async {
    final inList = watchlist.any((w) => w.id == p.id) || p.inWatchlist;
    if (inList) {
      await _scout.removeFromWatchlist(p.id);
    } else {
      await _scout.addToWatchlist(p.id, priority: priority);
    }
    await Future.wait([refreshWatchlist(), refreshProspects()]);
  }

  Future<void> cyclePriority(ScoutProspect p) async {
    const cycle = ['A', 'B', 'C'];
    final next = cycle[(cycle.indexOf(p.priority.clampPriority()) + 1) % cycle.length];
    await _scout.updateWatchlistPriority(p.id, next);
    await refreshWatchlist();
  }

  Future<void> updateWorkflow(String prospectId, String workflow) async {
    await _scout.updateProspect(prospectId, {'workflow': workflow, 'status': workflow});
    await refreshProspects();
    await refreshDashboard();
  }

  Future<void> addNote(String prospectId, String text) async {
    await _scout.addWatchlistNote(prospectId, text);
    await refreshWatchlist();
  }
}

extension on String {
  String clampPriority() {
    if (this == 'A' || this == 'B' || this == 'C') return this;
    return 'B';
  }
}
