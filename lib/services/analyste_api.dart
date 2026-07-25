import '../config/api_config.dart';
import '../models/analyste_models.dart';
import 'api_client.dart';

class AnalysteApi {
  AnalysteApi(this._api);

  final ApiClient _api;

  Future<AnalysteDashboardData> getDashboard() async {
    final data = await _api.get('/analyste/dashboard');
    return AnalysteDashboardData.fromJson(data as Map<String, dynamic>);
  }

  Future<AnalysteLiveMatch> getLiveMatch({String? home, String? away, int? minute}) async {
    final qs = <String>[];
    if (home != null && home.isNotEmpty) qs.add('home=${Uri.encodeQueryComponent(home)}');
    if (away != null && away.isNotEmpty) qs.add('away=${Uri.encodeQueryComponent(away)}');
    if (minute != null) qs.add('minute=$minute');
    final path = qs.isEmpty ? '/analyste/live-match' : '/analyste/live-match?${qs.join('&')}';
    final data = kAnalysteMlUrl.isNotEmpty
        ? await _api.get(path, baseUrl: kAnalysteMlUrl)
        : await _api.get(path);
    return AnalysteLiveMatch.fromJson(data as Map<String, dynamic>);
  }

  Future<List<String>> getMlClubs() async {
    if (kAnalysteMlUrl.isEmpty) return [];
    try {
      final data = await _api.get('/analyste/clubs', baseUrl: kAnalysteMlUrl) as Map<String, dynamic>;
      return (data['clubs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<List<AnalystePpiPlayer>> getPpi() async {
    final data = await _api.get('/analyste/ppi') as Map<String, dynamic>;
    final players = data['players'] as List<dynamic>? ?? [];
    return players
        .whereType<Map<String, dynamic>>()
        .map(AnalystePpiPlayer.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> getChemistry() async {
    return await _api.get('/analyste/chemistry') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPatterns() async {
    return await _api.get('/analyste/patterns') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFatigue() async {
    return await _api.get('/analyste/fatigue') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getExecutive() async {
    return await _api.get('/analyste/executive') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInjuries() async {
    return await _api.get('/analyste/injuries') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOpponent() async {
    return await _api.get('/analyste/opponent') as Map<String, dynamic>;
  }

  Future<List<String>> getPredictionTeams() async {
    final data = await _api.get('/analyste/prediction/teams') as Map<String, dynamic>;
    return (data['teams'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
  }

  Future<Map<String, dynamic>> predictMatch(String home, String away) async {
    return await _api.post('/analyste/prediction', body: {
      'home': home,
      'away': away,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getWhoop() async {
    return await _api.get('/analyste/whoop') as Map<String, dynamic>;
  }
}
