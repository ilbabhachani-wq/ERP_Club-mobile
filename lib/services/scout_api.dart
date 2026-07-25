import '../models/scout_models.dart';
import 'api_client.dart';

class ScoutApi {
  ScoutApi(this._api);

  final ApiClient _api;

  Future<ScoutDashboard> getDashboard() async {
    final data = await _api.get('/scout/dashboard');
    return ScoutDashboard.fromJson(data as Map<String, dynamic>);
  }

  Future<ScoutProfile> getProfile() async {
    final data = await _api.get('/scout/profile');
    return ScoutProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<ScoutProfile> updateProfile(Map<String, dynamic> body) async {
    final data = await _api.patch('/scout/profile', body: body);
    return ScoutProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ScoutProspect>> getProspects() async {
    final data = await _api.get('/scout/prospects');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ScoutProspect.fromJson)
        .toList();
  }

  Future<ScoutProspect> getProspect(String id) async {
    final data = await _api.get('/scout/prospects/$id');
    return ScoutProspect.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateProspect(String id, Map<String, dynamic> body) async {
    await _api.patch('/scout/prospects/$id', body: body);
  }

  Future<List<ScoutProspect>> getWatchlist() async {
    final data = await _api.get('/scout/watchlist');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ScoutProspect.fromJson)
        .toList();
  }

  Future<void> addToWatchlist(String prospectId, {String priority = 'B'}) async {
    await _api.post('/scout/watchlist', body: {
      'prospectId': prospectId,
      'priority': priority,
    });
  }

  Future<void> removeFromWatchlist(String prospectId) async {
    await _api.delete('/scout/watchlist/$prospectId');
  }

  Future<void> updateWatchlistPriority(String prospectId, String priority) async {
    await _api.patch('/scout/watchlist/$prospectId/priority', body: {
      'priority': priority,
    });
  }

  Future<void> addWatchlistNote(String prospectId, String text) async {
    await _api.post('/scout/watchlist/$prospectId/notes', body: {'text': text});
  }

  Future<void> removeWatchlistNote(String prospectId, int index) async {
    await _api.delete('/scout/watchlist/$prospectId/notes/$index');
  }

  Future<List<ScoutReport>> getReports() async {
    final data = await _api.get('/scout/reports');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ScoutReport.fromJson)
        .toList();
  }

  Future<void> createReport(Map<String, dynamic> body) async {
    await _api.post('/scout/reports', body: body);
  }

  Future<List<ScoutMission>> getMissions() async {
    final data = await _api.get('/scout/missions');
    return (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ScoutMission.fromJson)
        .toList();
  }

  Future<void> createMission(Map<String, dynamic> body) async {
    await _api.post('/scout/missions', body: body);
  }

  Future<Map<String, dynamic>> getMapOverview() async {
    return await _api.get('/scout/map') as Map<String, dynamic>;
  }

  Future<List<ScoutMapContinent>> getContinents() async {
    final data = await getMapOverview();
    return (data['continents'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ScoutMapContinent.fromJson)
            .toList() ??
        [];
  }

  Future<List<ScoutMapCountry>> getMapCountries(String continentId) async {
    final data = await _api.get('/scout/map/continents/$continentId') as Map<String, dynamic>;
    return (data['countries'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ScoutMapCountry.fromJson)
            .toList() ??
        [];
  }

  Future<List<ScoutMapTeam>> getMapTeams(String countryId) async {
    final data = await _api.get('/scout/map/countries/$countryId/teams') as Map<String, dynamic>;
    return (data['teams'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ScoutMapTeam.fromJson)
            .toList() ??
        [];
  }

  Future<List<ScoutSquadPlayer>> getTeamSquad(String teamId, {bool refresh = false}) async {
    final q = refresh ? '?refresh=1' : '';
    final data = await _api.get('/scout/map/teams/$teamId/squad$q') as Map<String, dynamic>;
    return (data['players'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ScoutSquadPlayer.fromJson)
            .toList() ??
        [];
  }

  Future<ScoutSearchResponse> searchProspects(ScoutSearchFilters filters) async {
    try {
      final data = await _api.post('/scout/search', body: filters.toJson());
      return ScoutSearchResponse.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
    } catch (_) {
      // fallback below
    }

    // Fallback like web: local filter + AI
    final all = await getProspects().catchError((_) => <ScoutProspect>[]);
    var filtered = all;
    if (filters.position != null && filters.position!.isNotEmpty) {
      filtered = filtered.where((p) => p.position.toLowerCase().contains(filters.position!.toLowerCase())).toList();
    }
    if (filters.country != null && filters.country!.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.nationality.toLowerCase().contains(filters.country!.toLowerCase()) ||
              p.flag.toLowerCase().contains(filters.country!.toLowerCase()))
          .toList();
    }
    if (filters.query.isNotEmpty) {
      final q = filters.query.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.club.toLowerCase().contains(q) ||
              p.position.toLowerCase().contains(q))
          .toList();
    }

    return ScoutSearchResponse(
      summary: '${filtered.length} joueur(s) en base',
      results: filtered
          .map((p) => ScoutSearchResult(
                id: p.id,
                name: p.name,
                club: p.club,
                position: p.position,
                age: p.age,
                potential: p.potential,
                flag: p.flag,
                aiScore: p.aiScore,
                inDatabase: true,
                source: 'database',
                photoUrl: p.photoUrl,
                marketValue: p.marketValue,
              ))
          .toList(),
      model: 'fallback-local',
    );
  }

  Future<Map<String, dynamic>> getAiMeta() async {
    return await _api.get('/scout/ai') as Map<String, dynamic>;
  }

  Future<List<ScoutAiHit>> searchAi(String query) async {
    final data = await _api.post('/scout/ai/search', body: {'query': query}) as Map<String, dynamic>;
    return (data['results'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ScoutAiHit.fromJson)
            .toList() ??
        [];
  }

  Future<List<ScoutAgent>> getAgents({bool refresh = false}) async {
    final data = await _api.get('/scout/agents${refresh ? '?refresh=1' : ''}') as Map<String, dynamic>;
    return (data['agents'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(ScoutAgent.fromJson)
            .toList() ??
        [];
  }

  Future<Map<String, dynamic>> submitCommittee(List<String> prospectIds) async {
    return await _api.post('/scout/shortlist/submit-committee', body: {
      'prospectIds': prospectIds,
    }) as Map<String, dynamic>;
  }
}
