import 'api_client.dart';

class MedecinApi {
  MedecinApi(this._api);
  final ApiClient _api;

  // Players
  Future<List<dynamic>> getPlayers() async {
    final res = await _api.get('/club/players');
    return List<dynamic>.from(res as List);
  }

  // Injuries
  Future<Map<String, dynamic>> getInjuries() async {
    final res = await _api.get('/club/injuries');
    return Map<String, dynamic>.from(
      res as Map
    );
  }

  Future<Map<String, dynamic>> createInjury(
    Map<String, dynamic> body
  ) async {
    final res = await _api.post(
      '/club/injuries', body: body
    );
    return Map<String, dynamic>.from(
      res as Map
    );
  }

  Future<Map<String, dynamic>> updateInjury(
    String id,
    Map<String, dynamic> body
  ) async {
    final res = await _api.patch(
      '/club/injuries/$id', body: body
    );
    return Map<String, dynamic>.from(
      res as Map
    );
  }

  // Calendar / Rendez-vous
  Future<List<dynamic>> getCalendar() async {
    final res = await _api.get('/club/calendar');
    if (res is List) return List<dynamic>.from(res);
    if (res is Map && res['events'] is List) {
      return List<dynamic>.from(
        res['events'] as List
      );
    }
    return [];
  }

  Future<Map<String, dynamic>> createEvent(
    Map<String, dynamic> body
  ) async {
    final res = await _api.post(
      '/club/calendar', body: body
    );
    return Map<String, dynamic>.from(
      res as Map
    );
  }

  // Documents
  Future<List<dynamic>> getPlayerDocuments(
    String playerId
  ) async {
    final res = await _api.get(
      '/club/players/$playerId/documents'
    );
    return List<dynamic>.from(res as List);
  }
}
