import 'api_client.dart';

class PrepChargePlayer {
  PrepChargePlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.loadScore,
    required this.fatigueScore,
    required this.recoveryScore,
    required this.statut,
    this.sessionDate,
    this.loadId,
  });

  final String id;
  final String name;
  final String position;
  final int loadScore;
  final int fatigueScore;
  final int recoveryScore;
  final String statut;
  final String? sessionDate;
  final String? loadId;

  factory PrepChargePlayer.fromJson(Map<String, dynamic> j) => PrepChargePlayer(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        position: '${j['position'] ?? ''}',
        loadScore: (j['loadScore'] as num?)?.toInt() ?? 0,
        fatigueScore: (j['fatigueScore'] as num?)?.toInt() ?? 0,
        recoveryScore: (j['recoveryScore'] as num?)?.toInt() ?? 0,
        statut: '${j['statut'] ?? 'Normal'}',
        sessionDate: j['sessionDate']?.toString(),
        loadId: j['loadId']?.toString(),
      );
}

class PrepChargeSummary {
  PrepChargeSummary({
    this.critiques = 0,
    this.attentions = 0,
    this.avgLoad = 0,
    this.total = 0,
  });

  final int critiques;
  final int attentions;
  final int avgLoad;
  final int total;

  factory PrepChargeSummary.fromJson(Map<String, dynamic>? j) => PrepChargeSummary(
        critiques: (j?['critiques'] as num?)?.toInt() ?? 0,
        attentions: (j?['attentions'] as num?)?.toInt() ?? 0,
        avgLoad: (j?['avgLoad'] as num?)?.toInt() ?? 0,
        total: (j?['total'] as num?)?.toInt() ?? 0,
      );
}

class PrepChargeData {
  PrepChargeData({required this.players, required this.summary});
  final List<PrepChargePlayer> players;
  final PrepChargeSummary summary;
}

class PrepPhysicalProfile {
  PrepPhysicalProfile({
    required this.id,
    required this.name,
    required this.position,
    required this.ovr,
    required this.speed,
    required this.endurance,
    required this.force,
    required this.explosivity,
    required this.agility,
    required this.recovery,
    this.evolution = const [],
  });

  final String id;
  final String name;
  final String position;
  final int ovr;
  final int speed;
  final int endurance;
  final int force;
  final int explosivity;
  final int agility;
  final int recovery;
  final List<Map<String, dynamic>> evolution;

  factory PrepPhysicalProfile.fromJson(Map<String, dynamic> j) => PrepPhysicalProfile(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        position: '${j['position'] ?? ''}',
        ovr: (j['ovr'] as num?)?.toInt() ?? 0,
        speed: (j['speed'] as num?)?.toInt() ?? 0,
        endurance: (j['endurance'] as num?)?.toInt() ?? 0,
        force: (j['force'] as num?)?.toInt() ?? 0,
        explosivity: (j['explosivity'] as num?)?.toInt() ?? 0,
        agility: (j['agility'] as num?)?.toInt() ?? 0,
        recovery: (j['recovery'] as num?)?.toInt() ?? 0,
        evolution: (j['evolution'] as List?)
                ?.whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList() ??
            const [],
      );
}

class PrepProgram {
  PrepProgram({
    required this.id,
    required this.name,
    required this.objective,
    required this.duration,
    required this.intensity,
    required this.status,
    required this.createdAt,
    this.assignedPlayers = const [],
    this.playerIds = const [],
  });

  final String id;
  final String name;
  final String objective;
  final String duration;
  final String intensity;
  final String status;
  final String createdAt;
  final List<String> assignedPlayers;
  final List<String> playerIds;

  factory PrepProgram.fromJson(Map<String, dynamic> j) => PrepProgram(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        objective: '${j['objective'] ?? ''}',
        duration: '${j['duration'] ?? ''}',
        intensity: '${j['intensity'] ?? 'Moyenne'}',
        status: '${j['status'] ?? 'brouillon'}',
        createdAt: '${j['createdAt'] ?? ''}',
        assignedPlayers:
            (j['assignedPlayers'] as List?)?.map((e) => '$e').toList() ?? const [],
        playerIds: (j['playerIds'] as List?)?.map((e) => '$e').toList() ?? const [],
      );
}

class PrepPlayerOption {
  PrepPlayerOption({required this.id, required this.name});
  final String id;
  final String name;

  factory PrepPlayerOption.fromJson(Map<String, dynamic> j) => PrepPlayerOption(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? j['fullName'] ?? ''}',
      );
}

class PrepAiSummary {
  PrepAiSummary({
    this.totalPlayers = 0,
    this.disponibles = 0,
    this.critiques = 0,
    this.attentions = 0,
    this.avgLoad = 0,
    this.injuryRiskCount = 0,
  });

  final int totalPlayers;
  final int disponibles;
  final int critiques;
  final int attentions;
  final int avgLoad;
  final int injuryRiskCount;

  factory PrepAiSummary.fromJson(Map<String, dynamic>? j) => PrepAiSummary(
        totalPlayers: (j?['totalPlayers'] as num?)?.toInt() ?? 0,
        disponibles: (j?['disponibles'] as num?)?.toInt() ?? 0,
        critiques: (j?['critiques'] as num?)?.toInt() ?? 0,
        attentions: (j?['attentions'] as num?)?.toInt() ?? 0,
        avgLoad: (j?['avgLoad'] as num?)?.toInt() ?? 0,
        injuryRiskCount: (j?['injuryRiskCount'] as num?)?.toInt() ?? 0,
      );
}

class PrepAiData {
  PrepAiData({
    required this.status,
    required this.model,
    required this.provider,
    required this.hasApiKey,
    required this.clubName,
    required this.season,
    required this.summary,
    required this.suggestedQuestions,
    this.avgResponseTime = '',
  });

  final String status;
  final String model;
  final String provider;
  final bool hasApiKey;
  final String clubName;
  final String season;
  final PrepAiSummary summary;
  final List<String> suggestedQuestions;
  final String avgResponseTime;

  bool get isAvailable => status == 'available';

  factory PrepAiData.fromJson(Map<String, dynamic> j) => PrepAiData(
        status: '${j['status'] ?? 'disabled'}',
        model: '${j['model'] ?? ''}',
        provider: '${j['provider'] ?? ''}',
        hasApiKey: j['hasApiKey'] == true,
        clubName: '${j['clubName'] ?? ''}',
        season: '${j['season'] ?? ''}',
        summary: PrepAiSummary.fromJson(
          j['summary'] is Map ? Map<String, dynamic>.from(j['summary'] as Map) : null,
        ),
        suggestedQuestions:
            (j['suggestedQuestions'] as List?)?.map((e) => '$e').toList() ?? const [],
        avgResponseTime: '${j['avgResponseTime'] ?? ''}',
      );
}

class PrepAiCard {
  PrepAiCard({
    required this.player,
    required this.risk,
    required this.color,
    required this.reasons,
    required this.recommendations,
    this.ready,
  });

  final String player;
  final int risk;
  final String color;
  final List<String> reasons;
  final List<String> recommendations;
  final bool? ready;

  factory PrepAiCard.fromJson(Map<String, dynamic> j) => PrepAiCard(
        player: '${j['player'] ?? ''}',
        risk: (j['risk'] as num?)?.toInt() ?? 0,
        color: '${j['color'] ?? '#22D3EE'}',
        reasons: (j['reasons'] as List?)?.map((e) => '$e').toList() ?? const [],
        recommendations:
            (j['recommendations'] as List?)?.map((e) => '$e').toList() ?? const [],
        ready: j['ready'] is bool ? j['ready'] as bool : null,
      );
}

class PrepAiChatResult {
  PrepAiChatResult({
    required this.question,
    required this.text,
    required this.cards,
    this.durationMs = 0,
    this.model = '',
  });

  final String question;
  final String text;
  final List<PrepAiCard> cards;
  final int durationMs;
  final String model;

  factory PrepAiChatResult.fromJson(Map<String, dynamic> j) => PrepAiChatResult(
        question: '${j['question'] ?? ''}',
        text: '${j['text'] ?? ''}',
        cards: (j['cards'] as List?)
                ?.whereType<Map>()
                .map((e) => PrepAiCard.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
        model: '${j['model'] ?? ''}',
      );
}

class PreparateurApi {
  PreparateurApi(this._api);
  final ApiClient _api;

  Future<PrepAiData> getAi() async {
    final raw = await _api.get('/club/preparateur/ai');
    return PrepAiData.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<PrepAiChatResult> chatAi(String question, {String? context}) async {
    final raw = await _api.post('/club/preparateur/ai/chat', body: {
      'question': question,
      if (context != null && context.isNotEmpty) 'context': context,
    });
    return PrepAiChatResult.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<PrepChargeData> getCharge() async {
    final raw = await _api.get('/club/preparateur/charge');
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final players = (map['players'] as List?)
            ?.whereType<Map>()
            .map((e) => PrepChargePlayer.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    return PrepChargeData(
      players: players,
      summary: PrepChargeSummary.fromJson(
        map['summary'] is Map ? Map<String, dynamic>.from(map['summary'] as Map) : null,
      ),
    );
  }

  Future<PrepChargePlayer> reduceCharge(String playerId) async {
    final raw = await _api.patch('/club/preparateur/charge/$playerId/reduce');
    return PrepChargePlayer.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<PrepChargePlayer> increaseCharge(String playerId) async {
    final raw = await _api.patch('/club/preparateur/charge/$playerId/increase');
    return PrepChargePlayer.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<List<PrepPhysicalProfile>> getCondition() async {
    final raw = await _api.get('/club/preparateur/condition');
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => PrepPhysicalProfile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<PrepProgram>> getPrograms() async {
    final raw = await _api.get('/club/preparateur/programs');
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => PrepProgram.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PrepProgram> createProgram(Map<String, dynamic> body) async {
    final raw = await _api.post('/club/preparateur/programs', body: body);
    return PrepProgram.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<PrepProgram> updateProgram(String id, Map<String, dynamic> body) async {
    final raw = await _api.patch('/club/preparateur/programs/$id', body: body);
    return PrepProgram.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> deleteProgram(String id) async {
    await _api.delete('/club/preparateur/programs/$id');
  }

  Future<List<PrepPlayerOption>> getPlayers() async {
    final raw = await _api.get('/club/players');
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => PrepPlayerOption.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  Future<List<PrepNotification>> getNotifications() async {
    final raw = await _api.get('/club/preparateur/notifications');
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => PrepNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _api.patch('/club/preparateur/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _api.patch('/club/preparateur/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete('/club/preparateur/notifications/$id');
  }
}

class PrepNotification {
  PrepNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.priority,
    required this.isRead,
    this.playerName,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String priority;
  final bool isRead;
  final String? playerName;
  final String? createdAt;

  factory PrepNotification.fromJson(Map<String, dynamic> j) => PrepNotification(
        id: '${j['id'] ?? ''}',
        type: '${j['type'] ?? ''}',
        title: '${j['title'] ?? ''}',
        body: '${j['body'] ?? ''}',
        priority: '${j['priority'] ?? 'basse'}',
        isRead: j['isRead'] == true,
        playerName: j['playerName']?.toString(),
        createdAt: j['createdAt']?.toString(),
      );
}
