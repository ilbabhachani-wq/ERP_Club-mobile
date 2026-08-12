import 'api_client.dart';

class CoachApi {
  CoachApi(this._api);
  final ApiClient _api;

  Future<List<dynamic>> getPlayers() async {
    final res = await _api.get('/club/players');
    return List<dynamic>.from(res as List);
  }

  Future<Map<String, dynamic>> getInjuries() async {
    final res = await _api.get('/club/injuries');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<List<dynamic>> getCalendar() async {
    final res = await _api.get('/club/calendar');
    if (res is List) return List<dynamic>.from(res);
    if (res is Map && res['events'] is List) {
      return List<dynamic>.from(res['events'] as List);
    }
    return [];
  }

  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body) async {
    final res = await _api.post('/club/calendar', body: body);
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> getTraining() async {
    final res = await _api.get('/club/training');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> getMatches() async {
    final res = await _api.get('/club/matches');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> getCharge() async {
    final res = await _api.get('/club/preparateur/charge');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<List<dynamic>> getMessageContacts({String search = ''}) async {
    final q = search.trim().isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search.trim())}';
    final res = await _api.get('/messages/contacts$q');
    if (res is List) return List<dynamic>.from(res);
    if (res is Map) {
      final items = res['items'] ?? res['searchResults'];
      if (items is List) return List<dynamic>.from(items);
    }
    return [];
  }

  Future<List<dynamic>> getMessageThread(String peerMemberId) async {
    final res = await _api.get('/messages/thread/$peerMemberId');
    if (res is List) return List<dynamic>.from(res);
    if (res is Map && res['messages'] is List) {
      return List<dynamic>.from(res['messages'] as List);
    }
    return [];
  }

  Future<Map<String, dynamic>> sendMessage(
    String peerMemberId,
    String text,
  ) async {
    final res = await _api.post(
      '/messages/thread/$peerMemberId',
      body: {'body': text},
    );
    return Map<String, dynamic>.from(res as Map);
  }
}
