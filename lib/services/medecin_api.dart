import 'api_client.dart';
import 'responsable_api.dart';

class MedecinAiSummary {
  MedecinAiSummary({
    this.squadSize = 0,
    this.blesses = 0,
    this.highRisk = 0,
    this.avgRisk = 0,
  });

  final int squadSize;
  final int blesses;
  final int highRisk;
  final int avgRisk;

  factory MedecinAiSummary.fromJson(Map<String, dynamic>? j) => MedecinAiSummary(
        squadSize: (j?['squadSize'] as num?)?.toInt() ?? 0,
        blesses: (j?['blesses'] as num?)?.toInt() ?? 0,
        highRisk: (j?['highRisk'] as num?)?.toInt() ?? 0,
        avgRisk: (j?['avgRisk'] as num?)?.toInt() ?? 0,
      );
}

class MedecinAiPlayer {
  MedecinAiPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.status,
    required this.riskScore,
    required this.level,
  });

  final String id;
  final String name;
  final String position;
  final String status;
  final int riskScore;
  final String level;

  factory MedecinAiPlayer.fromJson(Map<String, dynamic> j) => MedecinAiPlayer(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        position: '${j['position'] ?? ''}',
        status: '${j['status'] ?? ''}',
        riskScore: (j['riskScore'] as num?)?.toInt() ?? 0,
        level: '${j['level'] ?? ''}',
      );
}

class MedecinAiData {
  MedecinAiData({
    required this.status,
    required this.model,
    required this.provider,
    required this.hasApiKey,
    required this.clubName,
    required this.staffName,
    required this.season,
    required this.summary,
    required this.players,
    required this.suggestedQuestions,
  });

  final String status;
  final String model;
  final String provider;
  final bool hasApiKey;
  final String clubName;
  final String staffName;
  final String season;
  final MedecinAiSummary summary;
  final List<MedecinAiPlayer> players;
  final List<String> suggestedQuestions;

  bool get isAvailable => status == 'available';

  factory MedecinAiData.fromJson(Map<String, dynamic> j) => MedecinAiData(
        status: '${j['status'] ?? 'disabled'}',
        model: '${j['model'] ?? ''}',
        provider: '${j['provider'] ?? ''}',
        hasApiKey: j['hasApiKey'] == true,
        clubName: '${j['clubName'] ?? ''}',
        staffName: '${j['medicalStaffName'] ?? ''}',
        season: '${j['season'] ?? ''}',
        summary: MedecinAiSummary.fromJson(
          j['summary'] is Map ? Map<String, dynamic>.from(j['summary'] as Map) : null,
        ),
        players: (j['players'] as List?)
                ?.whereType<Map>()
                .map((e) => MedecinAiPlayer.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        suggestedQuestions:
            (j['suggestedQuestions'] as List?)?.map((e) => '$e').toList() ?? const [],
      );
}

class MedecinAiCard {
  MedecinAiCard({
    required this.title,
    required this.value,
    required this.color,
    required this.detail,
  });

  final String title;
  final String value;
  final String color;
  final String detail;

  factory MedecinAiCard.fromJson(Map<String, dynamic> j) => MedecinAiCard(
        title: '${j['title'] ?? ''}',
        value: '${j['value'] ?? ''}',
        color: '${j['color'] ?? '#FF7A00'}',
        detail: '${j['detail'] ?? ''}',
      );
}

class MedecinAiChatResult {
  MedecinAiChatResult({
    required this.text,
    required this.cards,
    this.durationMs = 0,
    this.model = '',
  });

  final String text;
  final List<MedecinAiCard> cards;
  final int durationMs;
  final String model;

  factory MedecinAiChatResult.fromJson(Map<String, dynamic> j) => MedecinAiChatResult(
        text: '${j['text'] ?? ''}',
        cards: (j['cards'] as List?)
                ?.whereType<Map>()
                .map((e) => MedecinAiCard.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
        model: '${j['model'] ?? ''}',
      );
}

class MedecinPlayerAnalysis {
  MedecinPlayerAnalysis({
    required this.playerName,
    required this.risk,
    required this.level,
    required this.mainInjury,
    required this.grade,
    required this.returnDays,
    required this.recommendation,
  });

  final String playerName;
  final int risk;
  final String level;
  final String mainInjury;
  final String grade;
  final int returnDays;
  final String recommendation;

  factory MedecinPlayerAnalysis.fromJson(Map<String, dynamic> j) =>
      MedecinPlayerAnalysis(
        playerName: '${j['playerName'] ?? ''}',
        risk: (j['risk'] as num?)?.toInt() ?? 0,
        level: '${j['level'] ?? ''}',
        mainInjury: '${j['mainInjury'] ?? ''}',
        grade: '${j['grade'] ?? ''}',
        returnDays: (j['returnDays'] as num?)?.toInt() ?? 0,
        recommendation: '${j['recommendation'] ?? ''}',
      );
}

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

  Future<MedecinAiData> getAi() async {
    final raw = await _api.get('/club/medical/ai');
    return MedecinAiData.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<MedecinAiChatResult> chatAi(String question, {String? playerId}) async {
    final raw = await _api.post('/club/medical/ai/chat', body: {
      'question': question,
      if (playerId != null && playerId.isNotEmpty) 'context': playerId,
    });
    return MedecinAiChatResult.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<MedecinPlayerAnalysis> analyzePlayer(String playerId) async {
    final raw = await _api.post('/club/medical/ai/analyze', body: {
      'playerId': playerId,
    });
    return MedecinPlayerAnalysis.fromJson(Map<String, dynamic>.from(raw as Map));
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
}
