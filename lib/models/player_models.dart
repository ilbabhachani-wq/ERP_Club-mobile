class OdinUser {
  const OdinUser({
    required this.email,
    required this.role,
    this.id,
    this.fullName,
    this.clubMemberRole,
    this.playerId,
    this.organization,
  });

  final String? id;
  final String email;
  final String? fullName;
  final String role;
  final String? clubMemberRole;
  final String? playerId;
  final OrganizationInfo? organization;

  factory OdinUser.fromJson(Map<String, dynamic> json) {
    return OdinUser(
      id: json['id'] as String?,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      role: _mapRole(json),
      clubMemberRole: json['clubMemberRole'] as String?,
      playerId: json['playerId'] as String?,
      organization: json['organization'] != null
          ? OrganizationInfo.fromJson(json['organization'] as Map<String, dynamic>)
          : null,
    );
  }

  static String _mapRole(Map<String, dynamic> json) {
    const clubMap = {
      'Joueur': 'joueur',
      'Coach': 'coach',
      'Médecin': 'medical',
    };
    final memberRole = json['clubMemberRole'] as String?;
    if (memberRole != null && clubMap.containsKey(memberRole)) {
      return clubMap[memberRole]!;
    }
    final backendRole = json['role'] as String?;
    if (backendRole == 'ADMIN_CLUB') return 'adminclub';
    if (backendRole == 'SUPER_ADMIN') return 'superadmin';
    return 'joueur';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'clubMemberRole': clubMemberRole,
        'playerId': playerId,
        'organization': organization?.toJson(),
      };
}

class OrganizationInfo {
  const OrganizationInfo({
    required this.id,
    required this.clubName,
    required this.country,
    required this.league,
    this.logoUrl,
  });

  final String id;
  final String clubName;
  final String country;
  final String league;
  final String? logoUrl;

  factory OrganizationInfo.fromJson(Map<String, dynamic> json) {
    return OrganizationInfo(
      id: json['id'] as String? ?? '',
      clubName: json['clubName'] as String? ?? '',
      country: json['country'] as String? ?? '',
      league: json['league'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clubName': clubName,
        'country': country,
        'league': league,
        'logoUrl': logoUrl,
      };
}

class PlayerRadar {
  const PlayerRadar({
    this.speed = 70,
    this.passing = 70,
    this.shooting = 70,
    this.physical = 70,
    this.vision = 70,
    this.defending = 70,
  });

  final int speed;
  final int passing;
  final int shooting;
  final int physical;
  final int vision;
  final int defending;

  factory PlayerRadar.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerRadar();
    int v(String k) => (json[k] as num?)?.round() ?? 70;
    return PlayerRadar(
      speed: v('speed'),
      passing: v('passing'),
      shooting: v('shooting'),
      physical: v('physical'),
      vision: v('vision'),
      defending: v('defending'),
    );
  }
}

class BackendPlayer {
  const BackendPlayer({
    required this.id,
    required this.name,
    required this.position,
    this.positionFull = '',
    this.age = 0,
    this.ovr = 0,
    this.goals = 0,
    this.marketValue = '—',
    this.availability = 'Disponible',
    this.photoUrl,
    this.radar = const PlayerRadar(),
    this.height,
    this.weight,
    this.strongFoot,
    this.jerseyNumber,
    this.nationality,
  });

  final String id;
  final String name;
  final String position;
  final String positionFull;
  final int age;
  final int ovr;
  final int goals;
  final String marketValue;
  final String availability;
  final String? photoUrl;
  final PlayerRadar radar;
  final String? height;
  final String? weight;
  final String? strongFoot;
  final int? jerseyNumber;
  final String? nationality;

  factory BackendPlayer.fromJson(Map<String, dynamic> json) {
    return BackendPlayer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      position: json['position'] as String? ?? '',
      positionFull: json['positionFull'] as String? ?? '',
      age: (json['age'] as num?)?.round() ?? 0,
      ovr: (json['ovr'] as num?)?.round() ?? 0,
      goals: (json['goals'] as num?)?.round() ?? 0,
      marketValue: json['marketValue'] as String? ?? '—',
      availability: json['availability'] as String? ?? 'Disponible',
      photoUrl: json['photoUrl'] as String?,
      radar: PlayerRadar.fromJson(json['radar'] as Map<String, dynamic>?),
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      strongFoot: json['strongFoot'] as String?,
      jerseyNumber: (json['jerseyNumber'] as num?)?.round(),
      nationality: json['nationality'] as String?,
    );
  }
}

class PlayerStatsPayload {
  const PlayerStatsPayload({
    this.form = 0,
    this.vitesse = 0,
    this.technique = 0,
    this.physique = 0,
    this.mental = 0,
    this.coachRating = 0,
    this.positionRanking = 0,
    this.trainingLoad = 0,
    this.seasonGoals = 0,
    this.seasonAssists = 0,
    this.seasonMatches = 0,
    this.marketValue = '—',
    this.marketValueTrend = '+0%',
    this.fatiguePredicted = 0,
  });

  final int form;
  final int vitesse;
  final int technique;
  final int physique;
  final int mental;
  final double coachRating;
  final int positionRanking;
  final int trainingLoad;
  final int seasonGoals;
  final int seasonAssists;
  final int seasonMatches;
  final String marketValue;
  final String marketValueTrend;
  final int fatiguePredicted;

  factory PlayerStatsPayload.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlayerStatsPayload();
    final hero = json['dashboardHero'] as Map<String, dynamic>?;
    final season = json['seasonStats'] as Map<String, dynamic>?;
    final trend = json['marketValueTrend'] as Map<String, dynamic>?;
    final sess = json['trainingSessions'] as Map<String, dynamic>?;
    return PlayerStatsPayload(
      form: (json['form'] as num?)?.round() ?? 0,
      vitesse: (json['vitesse'] as num?)?.round() ?? 0,
      technique: (json['technique'] as num?)?.round() ?? 0,
      physique: (json['physique'] as num?)?.round() ?? 0,
      mental: (json['mental'] as num?)?.round() ?? 0,
      coachRating: (json['coachRating'] as num?)?.toDouble() ??
          (hero?['coachRating'] as num?)?.toDouble() ??
          0,
      positionRanking: (json['positionRanking'] as num?)?.round() ??
          (hero?['positionRanking'] as num?)?.round() ??
          0,
      trainingLoad: (json['trainingLoad'] as num?)?.round() ?? 0,
      seasonGoals: (season?['goals'] as num?)?.round() ?? 0,
      seasonAssists: (season?['assists'] as num?)?.round() ?? 0,
      seasonMatches: (season?['matches'] as num?)?.round() ?? 0,
      marketValue: hero?['marketValue'] as String? ?? '—',
      marketValueTrend: trend?['change'] as String? ?? '+0%',
      fatiguePredicted: (sess?['fatiguePredicted'] as num?)?.round() ?? 0,
    );
  }
}

class BackendMatchStat {
  const BackendMatchStat({
    required this.id,
    required this.opponent,
    required this.result,
    this.matchDate = '',
    this.goals = 0,
    this.assists = 0,
    this.minutes = 0,
    this.rating = 0,
    this.distance = 0,
    this.sprints = 0,
    this.passAccuracy = 0,
    this.topSpeed = 0,
  });

  final String id;
  final String matchDate;
  final String opponent;
  final String result;
  final int goals;
  final int assists;
  final int minutes;
  final double rating;
  final double distance;
  final int sprints;
  final double passAccuracy;
  final double topSpeed;

  factory BackendMatchStat.fromJson(Map<String, dynamic> json) {
    return BackendMatchStat(
      id: json['id'] as String? ?? '',
      matchDate: json['matchDate'] as String? ?? '',
      opponent: json['opponent'] as String? ?? '',
      result: json['result'] as String? ?? '',
      goals: (json['goals'] as num?)?.round() ?? 0,
      assists: (json['assists'] as num?)?.round() ?? 0,
      minutes: (json['minutes'] as num?)?.round() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      sprints: (json['sprints'] as num?)?.round() ?? 0,
      passAccuracy: (json['passAccuracy'] as num?)?.toDouble() ?? 0,
      topSpeed: (json['topSpeed'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BackendCalendarEvent {
  const BackendCalendarEvent({
    required this.id,
    required this.title,
    required this.eventDate,
    this.eventTime,
    this.eventType = '',
    this.location,
  });

  final String id;
  final String title;
  final String eventDate;
  final String? eventTime;
  final String eventType;
  final String? location;

  factory BackendCalendarEvent.fromJson(Map<String, dynamic> json) {
    return BackendCalendarEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      eventDate: json['eventDate'] as String? ?? json['date'] as String? ?? '',
      eventTime: json['eventTime'] as String? ?? json['time'] as String?,
      eventType: json['eventType'] as String? ?? json['type'] as String? ?? '',
      location: json['location'] as String?,
    );
  }
}

class BackendInjury {
  const BackendInjury({
    required this.id,
    required this.injury,
    this.bodyPart = '',
    this.returnDate = '—',
    this.riskIA = 0,
  });

  final String id;
  final String injury;
  final String bodyPart;
  final String returnDate;
  final int riskIA;

  factory BackendInjury.fromJson(Map<String, dynamic> json) {
    return BackendInjury(
      id: json['id'] as String? ?? '',
      injury: json['injury'] as String? ??
          json['type'] as String? ??
          json['injuryType'] as String? ??
          '',
      bodyPart: json['bodyPart'] as String? ?? '',
      returnDate: json['returnDate'] as String? ?? '—',
      riskIA: (json['riskScore'] as num?)?.round() ??
          (json['riskIA'] as num?)?.round() ??
          0,
    );
  }
}

class BackendAward {
  const BackendAward({
    required this.id,
    required this.title,
    this.season = '',
    this.icon = '🏆',
    this.color = '#d99a1f',
    this.awardType = 'award',
  });

  final String id;
  final String title;
  final String season;
  final String icon;
  final String color;
  final String awardType;

  factory BackendAward.fromJson(Map<String, dynamic> json) {
    return BackendAward(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      season: json['season'] as String? ?? '',
      icon: json['icon'] as String? ?? '🏆',
      color: json['color'] as String? ?? '#d99a1f',
      awardType: json['awardType'] as String? ?? 'award',
    );
  }
}

class BackendDocument {
  const BackendDocument({
    required this.id,
    required this.name,
    this.docType = '',
    this.docDate = '',
    this.size = '',
  });

  final String id;
  final String name;
  final String docType;
  final String docDate;
  final String size;

  factory BackendDocument.fromJson(Map<String, dynamic> json) {
    return BackendDocument(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      docType: json['docType'] as String? ?? '',
      docDate: json['docDate'] as String? ?? '',
      size: json['size'] as String? ?? '',
    );
  }
}

class BackendContract {
  const BackendContract({
    required this.id,
    this.startDate = '',
    this.endDate = '',
    this.salary = '—',
    this.releaseClause = '—',
    this.consumedPct = 0,
  });

  final String id;
  final String startDate;
  final String endDate;
  final String salary;
  final String releaseClause;
  final int consumedPct;

  factory BackendContract.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const BackendContract(id: '');
    }
    return BackendContract(
      id: json['id'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      salary: json['salary'] as String? ?? '—',
      releaseClause: json['releaseClause'] as String? ?? '—',
      consumedPct: (json['consumedPct'] as num?)?.round() ?? 0,
    );
  }
}

class BackendTransfer {
  const BackendTransfer({
    required this.id,
    required this.playerName,
    this.transferType = '',
    this.club = '',
    this.value = '',
    this.status = '',
    this.probability = 0,
  });

  final String id;
  final String playerName;
  final String transferType;
  final String club;
  final String value;
  final String status;
  final int probability;

  factory BackendTransfer.fromJson(Map<String, dynamic> json) {
    return BackendTransfer(
      id: json['id'] as String? ?? '',
      playerName: json['playerName'] as String? ?? '',
      transferType: json['transferType'] as String? ?? '',
      club: json['club'] as String? ?? '',
      value: json['value'] as String? ?? '',
      status: json['status'] as String? ?? '',
      probability: (json['probability'] as num?)?.round() ?? 0,
    );
  }
}

class BackendChemistry {
  const BackendChemistry({
    required this.id,
    required this.player1Name,
    required this.player2Name,
    this.chemistry = 0,
  });

  final String id;
  final String player1Name;
  final String player2Name;
  final int chemistry;

  factory BackendChemistry.fromJson(Map<String, dynamic> json) {
    return BackendChemistry(
      id: json['id'] as String? ?? '',
      player1Name: json['player1Name'] as String? ?? '',
      player2Name: json['player2Name'] as String? ?? '',
      chemistry: (json['chemistry'] as num?)?.round() ?? 0,
    );
  }
}

class OrgProfile {
  const OrgProfile({
    this.clubName = '',
    this.league = '',
    this.country = '',
    this.logoUrl,
  });

  final String clubName;
  final String league;
  final String country;
  final String? logoUrl;

  factory OrgProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OrgProfile();
    return OrgProfile(
      clubName: json['clubName'] as String? ?? '',
      league: json['league'] as String? ?? '',
      country: json['country'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
    );
  }
}

class JoueurAiReport {
  const JoueurAiReport({
    this.recommendations = const [],
    this.suggestedQuestions = const [],
    this.strengths = const [],
    this.weaknesses = const [],
    this.playerName,
    this.ovr,
    this.position,
  });

  final List<String> recommendations;
  final List<String> suggestedQuestions;
  final List<Map<String, dynamic>> strengths;
  final List<Map<String, dynamic>> weaknesses;
  final String? playerName;
  final int? ovr;
  final String? position;

  factory JoueurAiReport.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const JoueurAiReport();
    return JoueurAiReport(
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedQuestions: (json['suggestedQuestions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      strengths: (json['strengths'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      weaknesses: (json['weaknesses'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      playerName: json['playerName'] as String?,
      ovr: (json['ovr'] as num?)?.round(),
      position: json['position'] as String?,
    );
  }
}
