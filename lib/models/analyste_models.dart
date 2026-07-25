class AnalysteInfo {
  const AnalysteInfo({
    this.name = 'Analyste',
    this.club = 'Club',
    this.season = '2025-26',
  });

  final String name;
  final String club;
  final String season;

  factory AnalysteInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AnalysteInfo();
    return AnalysteInfo(
      name: json['name'] as String? ?? 'Analyste',
      club: json['club'] as String? ?? 'Club',
      season: json['season'] as String? ?? '2025-26',
    );
  }
}

class AnalysteLiveStat {
  const AnalysteLiveStat({
    required this.label,
    required this.value,
    this.color = '#8B5CF6',
  });

  final String label;
  final String value;
  final String color;

  factory AnalysteLiveStat.fromJson(Map<String, dynamic> json) {
    return AnalysteLiveStat(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      color: json['color'] as String? ?? '#8B5CF6',
    );
  }
}

class AnalystePattern {
  const AnalystePattern({
    required this.title,
    this.confidence = 0,
    this.description = '',
    this.severity = '',
  });

  final String title;
  final double confidence;
  final String description;
  final String severity;

  factory AnalystePattern.fromJson(Map<String, dynamic> json) {
    return AnalystePattern(
      title: json['title'] as String? ??
          json['pattern'] as String? ??
          json['name'] as String? ??
          'Pattern',
      confidence: (json['confidence'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          0,
      description: json['description'] as String? ?? json['desc'] as String? ?? '',
      severity: json['severity'] as String? ??
          json['category'] as String? ??
          json['level'] as String? ??
          '',
    );
  }
}

class AnalysteDashboardData {
  const AnalysteDashboardData({
    this.info = const AnalysteInfo(),
    this.liveStats = const [],
    this.patterns = const [],
  });

  final AnalysteInfo info;
  final List<AnalysteLiveStat> liveStats;
  final List<AnalystePattern> patterns;

  factory AnalysteDashboardData.fromJson(Map<String, dynamic> json) {
    final stats = json['liveStats'] as List<dynamic>?;
    final patterns = json['patterns'] as List<dynamic>?;
    return AnalysteDashboardData(
      info: AnalysteInfo.fromJson(json['info'] as Map<String, dynamic>?),
      liveStats: stats
              ?.whereType<Map<String, dynamic>>()
              .map(AnalysteLiveStat.fromJson)
              .toList() ??
          const [],
      patterns: patterns
              ?.whereType<Map<String, dynamic>>()
              .map(AnalystePattern.fromJson)
              .toList() ??
          const [],
    );
  }
}

class AnalysteLiveMatch {
  const AnalysteLiveMatch({
    this.homeTeam = 'Domicile',
    this.awayTeam = 'Extérieur',
    this.homeScore = 0,
    this.awayScore = 0,
    this.minute = 0,
    this.events = const [],
    this.players = const [],
    this.minuteData = const [],
    this.drawPct = 0,
    this.awayWinPct = 0,
    this.homeWinPct = 0,
    this.leadingOutcome = '',
    this.source = '',
  });

  final String homeTeam;
  final String awayTeam;
  final int homeScore;
  final int awayScore;
  final int minute;
  final List<AnalysteMatchEvent> events;
  final List<AnalysteLivePlayer> players;
  final List<AnalysteMinutePoint> minuteData;
  final double drawPct;
  final double awayWinPct;
  final double homeWinPct;
  final String leadingOutcome;
  final String source;

  factory AnalysteLiveMatch.fromJson(Map<String, dynamic> json) {
    final score = json['score'] as Map<String, dynamic>?;
    final events = json['events'] as List<dynamic>?;
    final players = json['players'] as List<dynamic>?;
    final minutes = json['minuteData'] as List<dynamic>?;
    final meta = json['meta'] as Map<String, dynamic>?;
    return AnalysteLiveMatch(
      homeTeam: json['homeTeam'] as String? ?? 'Domicile',
      awayTeam: json['awayTeam'] as String? ?? 'Extérieur',
      homeScore: (score?['home'] as num?)?.round() ?? 0,
      awayScore: (score?['away'] as num?)?.round() ?? 0,
      minute: (json['minute'] as num?)?.round() ?? 0,
      events: events
              ?.whereType<Map<String, dynamic>>()
              .map(AnalysteMatchEvent.fromJson)
              .toList() ??
          const [],
      players: players
              ?.whereType<Map<String, dynamic>>()
              .map(AnalysteLivePlayer.fromJson)
              .toList() ??
          const [],
      minuteData: minutes
              ?.whereType<Map<String, dynamic>>()
              .map(AnalysteMinutePoint.fromJson)
              .toList() ??
          const [],
      homeWinPct: (meta?['home_win_pct'] as num?)?.toDouble() ?? 0,
      drawPct: (meta?['draw_pct'] as num?)?.toDouble() ?? 0,
      awayWinPct: (meta?['away_win_pct'] as num?)?.toDouble() ?? 0,
      leadingOutcome: meta?['leading_outcome'] as String? ?? '',
      source: meta?['source'] as String? ?? '',
    );
  }
}

class AnalysteMatchEvent {
  const AnalysteMatchEvent({
    this.minute = 0,
    this.type = '',
    this.player = '',
    this.team = '',
    this.desc = '',
  });

  final int minute;
  final String type;
  final String player;
  final String team;
  final String desc;

  factory AnalysteMatchEvent.fromJson(Map<String, dynamic> json) {
    return AnalysteMatchEvent(
      minute: (json['minute'] as num?)?.round() ?? 0,
      type: json['type'] as String? ?? '',
      player: json['player'] as String? ?? '',
      team: json['team'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
    );
  }
}

class AnalysteLivePlayer {
  const AnalysteLivePlayer({
    required this.name,
    this.fatigue = 0,
    this.risk = 0,
    this.readiness = 0,
    this.shouldSub = false,
  });

  final String name;
  final double fatigue;
  final double risk;
  final double readiness;
  final bool shouldSub;

  factory AnalysteLivePlayer.fromJson(Map<String, dynamic> json) {
    return AnalysteLivePlayer(
      name: json['name'] as String? ?? '',
      fatigue: (json['fatigue'] as num?)?.toDouble() ?? 0,
      risk: (json['risk'] as num?)?.toDouble() ?? 0,
      readiness: (json['readiness'] as num?)?.toDouble() ?? 0,
      shouldSub: json['shouldSub'] as bool? ?? false,
    );
  }
}

class AnalysteMinutePoint {
  const AnalysteMinutePoint({
    this.minute = 0,
    this.possession = 0,
    this.fatigue = 0,
    this.winProb = 0,
    this.drawProb = 0,
    this.awayProb = 0,
    this.xg = 0,
  });

  final int minute;
  final double possession;
  final double fatigue;
  final double winProb;
  final double drawProb;
  final double awayProb;
  final double xg;

  factory AnalysteMinutePoint.fromJson(Map<String, dynamic> json) {
    return AnalysteMinutePoint(
      minute: (json['minute'] as num?)?.round() ?? 0,
      possession: (json['possession'] as num?)?.toDouble() ?? 0,
      fatigue: (json['fatigue'] as num?)?.toDouble() ?? 0,
      winProb: (json['winProb'] as num?)?.toDouble() ?? 0,
      drawProb: (json['drawProb'] as num?)?.toDouble() ?? 0,
      awayProb: (json['awayProb'] as num?)?.toDouble() ?? 0,
      xg: (json['xg'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AnalystePpiPlayer {
  const AnalystePpiPlayer({
    required this.name,
    this.position = '',
    this.ppi = 0,
    this.ovr = 0,
    this.trend = '',
    this.form = 0,
  });

  final String name;
  final String position;
  final double ppi;
  final int ovr;
  final String trend;
  final double form;

  factory AnalystePpiPlayer.fromJson(Map<String, dynamic> json) {
    return AnalystePpiPlayer(
      name: json['name'] as String? ?? json['playerName'] as String? ?? '',
      position: json['position'] as String? ?? '',
      ppi: (json['ppi'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          0,
      ovr: (json['ovr'] as num?)?.round() ?? 0,
      trend: json['trend'] as String? ?? '',
      form: (json['form'] as num?)?.toDouble() ?? 0,
    );
  }
}
