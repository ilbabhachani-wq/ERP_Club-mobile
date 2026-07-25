import 'package:flutter/foundation.dart';
import '../models/analyste_models.dart';
import '../services/api_client.dart';
import '../services/analyste_api.dart';

class AnalysteDataProvider extends ChangeNotifier {
  AnalysteDataProvider(ApiClient api) : _analyste = AnalysteApi(api);

  final AnalysteApi _analyste;

  AnalysteDashboardData? dashboard;
  AnalysteLiveMatch? liveMatch;
  List<AnalystePpiPlayer> ppiPlayers = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _analyste.getDashboard().catchError((_) => const AnalysteDashboardData()),
        _analyste.getLiveMatch().catchError((_) => const AnalysteLiveMatch()),
        _analyste.getPpi().catchError((_) => <AnalystePpiPlayer>[]),
      ]);
      dashboard = results[0] as AnalysteDashboardData;
      liveMatch = results[1] as AnalysteLiveMatch;
      ppiPlayers = results[2] as List<AnalystePpiPlayer>;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> applyLiveMatch(AnalysteLiveMatch match) async {
    liveMatch = match;
    notifyListeners();
  }

  Future<void> refreshLive({String? home, String? away, int? minute}) async {
    liveMatch = await _analyste
        .getLiveMatch(home: home, away: away, minute: minute)
        .catchError((_) => liveMatch ?? const AnalysteLiveMatch());
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    dashboard = await _analyste.getDashboard().catchError((_) => dashboard ?? const AnalysteDashboardData());
    notifyListeners();
  }

  AnalysteApi get api => _analyste;
}
