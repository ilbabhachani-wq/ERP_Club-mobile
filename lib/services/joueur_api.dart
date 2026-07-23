import '../models/player_models.dart';
import 'api_client.dart';

class JoueurApi {
  JoueurApi(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> getMe() async =>
      await _api.get('/joueur/me') as Map<String, dynamic>;

  Future<Map<String, dynamic>> getExtended() async =>
      await _api.get('/joueur/me/extended') as Map<String, dynamic>;

  Future<List<dynamic>> getCalendar() async {
    final data = await _api.get('/joueur/me/calendar');
    return data is List ? data : [];
  }

  Future<List<dynamic>> getInjuries() async {
    final data = await _api.get('/joueur/me/injuries');
    return data is List ? data : [];
  }

  Future<List<dynamic>> getSquad() async {
    final data = await _api.get('/joueur/squad');
    return data is List ? data : [];
  }

  Future<JoueurAiReport> getAiReport({bool refresh = false}) async {
    final data = await _api.getWithTimeout(
      '/joueur/ai/report${refresh ? '?refresh=1' : ''}',
      timeoutMs: 25000,
    );
    return JoueurAiReport.fromJson(data as Map<String, dynamic>?);
  }

  Future<String> chatAi(String question) async {
    final data = await _api.post('/joueur/ai/chat', body: {'question': question})
        as Map<String, dynamic>;
    return data['text'] as String? ?? '';
  }
}

class ClubApi {
  ClubApi(this._api);
  final ApiClient _api;

  Future<OrgProfile> getProfile() async {
    final data = await _api.get('/club/profile');
    return OrgProfile.fromJson(data as Map<String, dynamic>?);
  }

  Future<List<BackendPlayer>> getPlayers() async {
    final data = await _api.get('/club/players');
    if (data is! List) return [];
    return data
        .map((e) => BackendPlayer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlayerStatsPayload> getPlayerStats(String id) async {
    final data = await _api.get('/club/players/$id/stats');
    return PlayerStatsPayload.fromJson(data as Map<String, dynamic>?);
  }

  Future<List<BackendMatchStat>> getMatchStats(String id) async {
    final data = await _api.get('/club/players/$id/match-stats');
    if (data is! List) return [];
    return data
        .map((e) => BackendMatchStat.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BackendAward>> getAwards(String id) async {
    final data = await _api.get('/club/players/$id/awards');
    if (data is! List) return [];
    return data
        .map((e) => BackendAward.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BackendDocument>> getDocuments(String id) async {
    final data = await _api.get('/club/players/$id/documents');
    if (data is! List) return [];
    return data
        .map((e) => BackendDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BackendContract> getPlayerContract(String id) async {
    final data = await _api.get('/club/players/$id/contract');
    return BackendContract.fromJson(data as Map<String, dynamic>?);
  }

  Future<List<BackendTransfer>> getTransfers() async {
    final data = await _api.get('/club/transfers');
    if (data is! List) return [];
    return data
        .map((e) => BackendTransfer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BackendChemistry>> getChemistry() async {
    final data = await _api.get('/club/chemistry');
    if (data is! List) return [];
    return data
        .map((e) => BackendChemistry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updatePlayerPhysical(String id, Map<String, dynamic> body) async {
    await _api.patch('/club/players/$id/physical', body: body);
  }

  Future<void> bookAppointment(String id, Map<String, dynamic> body) async {
    await _api.post('/club/players/$id/appointment', body: body);
  }

  Future<void> deleteDocument(String docId) async {
    await _api.delete('/club/documents/$docId');
  }
}

class MessagesApi {
  MessagesApi(this._api);
  final ApiClient _api;

  Future<List<dynamic>> getContacts({String search = ''}) async {
    final data = await _api.get('/messages/contacts?search=$search');
    return data is List ? data : [];
  }

  Future<List<dynamic>> getThread(String peerMemberId) async {
    final data = await _api.get('/messages/thread/$peerMemberId');
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> sendMessage(
    String peerMemberId,
    String text,
  ) async {
    return await _api.post('/messages/thread/$peerMemberId', body: {'text': text})
        as Map<String, dynamic>;
  }
}
