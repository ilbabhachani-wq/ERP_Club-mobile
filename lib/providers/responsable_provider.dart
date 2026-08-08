import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/responsable_api.dart';

class ResponsableDataProvider extends ChangeNotifier {
  ResponsableDataProvider(ApiClient api) : _api = ResponsableApi(api);

  final ResponsableApi _api;

  ResponsableApi get api => _api;

  ResponsableDashboardData? dashboard;
  List<ValidationRequest> validation = [];
  List<ClubNotificationItem> notifications = [];
  List<TeamCard> teams = [];
  bool loading = false;
  String? error;
  String? _orgId;
  bool bootstrapped = false;

  void setOrgId(String? orgId) => _orgId = orgId;

  Future<void> load({String? orgId}) async {
    if (loading) return;
    if (orgId != null) _orgId = orgId;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.getDashboard(_orgId).catchError(
          (_) => ResponsableDashboardData(
            execKpis: const [],
            secondaryKpis: const [],
            validationQueue: const [],
            notifications: const [],
          ),
        ),
        _api.getValidation().catchError((_) => <ValidationRequest>[]),
        _api.getNotifications().catchError((_) => <ClubNotificationItem>[]),
        _api.getTeams().catchError((_) => <TeamCard>[]),
      ]);
      dashboard = results[0] as ResponsableDashboardData;
      validation = results[1] as List<ValidationRequest>;
      notifications = results[2] as List<ClubNotificationItem>;
      teams = results[3] as List<TeamCard>;
    } catch (e) {
      error = e.toString();
      dashboard ??= ResponsableDashboardData(
        execKpis: const [],
        secondaryKpis: const [],
        validationQueue: const [],
        notifications: const [],
      );
    } finally {
      bootstrapped = true;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDashboard() async {
    try {
      dashboard = await _api.getDashboard(_orgId);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> refreshValidation() async {
    validation = await _api.getValidation().catchError((_) => validation);
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    notifications = await _api.getNotifications().catchError((_) => notifications);
    notifyListeners();
  }

  Future<void> refreshTeams() async {
    teams = await _api.getTeams().catchError((_) => teams);
    notifyListeners();
  }

  Future<void> decide(String id, String action, {String? comment}) async {
    await _api.decideValidation(id, action, comment: comment);
    await refreshValidation();
    await refreshDashboard();
  }

  Future<void> markAllRead() async {
    await _api.markNotificationsRead();
    await refreshNotifications();
  }

  Future<void> markRead(List<String> ids) async {
    await _api.markNotificationsRead(ids);
    await refreshNotifications();
  }

  Future<void> clearRead() async {
    await _api.clearReadNotifications();
    await refreshNotifications();
  }
}
