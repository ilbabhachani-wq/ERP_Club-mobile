import 'api_client.dart';
import 'responsable_api.dart';

class CoachAiSummary {
  CoachAiSummary({
    this.squadSize = 0,
    this.disponibles = 0,
    this.blesses = 0,
    this.avgLoad = 0,
    this.critiques = 0,
  });

  final int squadSize;
  final int disponibles;
  final int blesses;
  final int avgLoad;
  final int critiques;

  factory CoachAiSummary.fromJson(Map<String, dynamic>? j) => CoachAiSummary(
        squadSize: (j?['squadSize'] as num?)?.toInt() ?? 0,
        disponibles: (j?['disponibles'] as num?)?.toInt() ?? 0,
        blesses: (j?['blesses'] as num?)?.toInt() ?? 0,
        avgLoad: (j?['avgLoad'] as num?)?.toInt() ?? 0,
        critiques: (j?['critiques'] as num?)?.toInt() ?? 0,
      );
}

class CoachAiData {
  CoachAiData({
    required this.status,
    required this.model,
    required this.provider,
    required this.hasApiKey,
    required this.clubName,
    required this.coachName,
    required this.season,
    required this.summary,
    required this.suggestedQuestions,
  });

  final String status;
  final String model;
  final String provider;
  final bool hasApiKey;
  final String clubName;
  final String coachName;
  final String season;
  final CoachAiSummary summary;
  final List<String> suggestedQuestions;

  bool get isAvailable => status == 'available';

  factory CoachAiData.fromJson(Map<String, dynamic> j) => CoachAiData(
        status: '${j['status'] ?? 'disabled'}',
        model: '${j['model'] ?? ''}',
        provider: '${j['provider'] ?? ''}',
        hasApiKey: j['hasApiKey'] == true,
        clubName: '${j['clubName'] ?? ''}',
        coachName: '${j['coachName'] ?? ''}',
        season: '${j['season'] ?? ''}',
        summary: CoachAiSummary.fromJson(
          j['summary'] is Map ? Map<String, dynamic>.from(j['summary'] as Map) : null,
        ),
        suggestedQuestions:
            (j['suggestedQuestions'] as List?)?.map((e) => '$e').toList() ?? const [],
      );
}

class CoachAiCard {
  CoachAiCard({
    required this.title,
    required this.value,
    required this.color,
    required this.detail,
  });

  final String title;
  final String value;
  final String color;
  final String detail;

  factory CoachAiCard.fromJson(Map<String, dynamic> j) => CoachAiCard(
        title: '${j['title'] ?? ''}',
        value: '${j['value'] ?? ''}',
        color: '${j['color'] ?? '#FF7A00'}',
        detail: '${j['detail'] ?? ''}',
      );
}

class CoachAiChatResult {
  CoachAiChatResult({
    required this.text,
    required this.cards,
    this.durationMs = 0,
    this.model = '',
  });

  final String text;
  final List<CoachAiCard> cards;
  final int durationMs;
  final String model;

  factory CoachAiChatResult.fromJson(Map<String, dynamic> j) => CoachAiChatResult(
        text: '${j['text'] ?? ''}',
        cards: (j['cards'] as List?)
                ?.whereType<Map>()
                .map((e) => CoachAiCard.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
        model: '${j['model'] ?? ''}',
      );
}

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

  Future<CoachAiData> getAi() async {
    final raw = await _api.get('/club/coach/ai');
    return CoachAiData.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<CoachAiChatResult> chatAi(String question, {String? context}) async {
    final raw = await _api.post('/club/coach/ai/chat', body: {
      'question': question,
      if (context != null && context.isNotEmpty) 'context': context,
    });
    return CoachAiChatResult.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<List<ClubNotificationItem>> getNotifications() async {
    final raw = await _api.get('/club/notifications');
    final list = raw is List
        ? raw
        : (raw is Map && raw['items'] is List)
            ? raw['items'] as List
            : const [];
    return list
        .whereType<Map>()
        .map((e) => ClubNotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> markNotificationsRead([List<String>? ids]) async {
    await _api.patch('/club/notifications/read', body: {'ids': ids});
  }

  Future<void> clearReadNotifications() async {
    await _api.delete('/club/notifications/read');
  }
}
