import 'package:flutter/material.dart';

typedef ScoutPriority = String; // A | B | C
typedef ScoutWorkflow = String; // new | analysis | validation | signature | done

class ScoutWorkflowCol {
  const ScoutWorkflowCol(this.id, this.label, this.color);
  final String id;
  final String label;
  final Color color;
}

const kScoutWorkflowCols = [
  ScoutWorkflowCol('new', 'Nouveau', Color(0xFF3B82F6)),
  ScoutWorkflowCol('analysis', 'Analyse', Color(0xFFF59E0B)),
  ScoutWorkflowCol('validation', 'Validation', Color(0xFF8B5CF6)),
  ScoutWorkflowCol('signature', 'Signature', Color(0xFFFF7A00)),
  ScoutWorkflowCol('done', 'Terminé', Color(0xFF22C55E)),
];

class ScoutPriorityMeta {
  const ScoutPriorityMeta(this.color, this.label);
  final Color color;
  final String label;
}

const kScoutPriorityMeta = {
  'A': ScoutPriorityMeta(Color(0xFFEF4444), 'Priorité A — Critique'),
  'B': ScoutPriorityMeta(Color(0xFFF59E0B), 'Priorité B — Suivi actif'),
  'C': ScoutPriorityMeta(Color(0xFF3B82F6), 'Priorité C — Surveillance'),
};

class ScoutNote {
  const ScoutNote({required this.date, required this.text});
  final String date;
  final String text;

  factory ScoutNote.fromJson(Map<String, dynamic> json) => ScoutNote(
        date: json['date']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
      );
}

class ScoutProspect {
  const ScoutProspect({
    required this.id,
    required this.name,
    this.legacyId,
    this.apiSportsId,
    this.age = 0,
    this.nationality = '',
    this.flag = '',
    this.club = '',
    this.league = '',
    this.position = '',
    this.potential = 0,
    this.currentRating = 0,
    this.marketValue = '',
    this.valueMK = 0,
    this.priority = 'B',
    this.status = 'new',
    this.aiScore = 0,
    this.injuryRisk = 0,
    this.foot = '',
    this.height = 0,
    this.weight = 0,
    this.goals = 0,
    this.assists = 0,
    this.matches = 0,
    this.speed = 0,
    this.dribble = 0,
    this.passing = 0,
    this.defense = 0,
    this.physical = 0,
    this.mental = 0,
    this.contractEnd = '',
    this.agent,
    this.addedDate = '',
    this.notes = const [],
    this.inWatchlist = false,
    this.note,
    this.photoUrl,
    this.season,
  });

  final String id;
  final String? legacyId;
  final int? apiSportsId;
  final String name;
  final int age;
  final String nationality;
  final String flag;
  final String club;
  final String league;
  final String position;
  final int potential;
  final int currentRating;
  final String marketValue;
  final double valueMK;
  final String priority;
  final String status;
  final int aiScore;
  final int injuryRisk;
  final String foot;
  final int height;
  final int weight;
  final int goals;
  final int assists;
  final int matches;
  final int speed;
  final int dribble;
  final int passing;
  final int defense;
  final int physical;
  final int mental;
  final String contractEnd;
  final String? agent;
  final String addedDate;
  final List<ScoutNote> notes;
  final bool inWatchlist;
  final String? note;
  final String? photoUrl;
  final String? season;

  factory ScoutProspect.fromJson(Map<String, dynamic> json) {
    final notesRaw = json['notes'] as List<dynamic>? ?? [];
    return ScoutProspect(
      id: json['id']?.toString() ?? '',
      legacyId: json['legacyId']?.toString(),
      apiSportsId: (json['apiSportsId'] as num?)?.toInt(),
      name: json['name']?.toString() ?? 'Prospect',
      age: (json['age'] as num?)?.toInt() ?? 0,
      nationality: json['nationality']?.toString() ?? '',
      flag: json['flag']?.toString() ?? '',
      club: json['club']?.toString() ?? '',
      league: json['league']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      potential: (json['potential'] as num?)?.toInt() ?? 0,
      currentRating: (json['currentRating'] as num?)?.toInt() ?? 0,
      marketValue: json['marketValue']?.toString() ?? '',
      valueMK: (json['valueMK'] as num?)?.toDouble() ?? 0,
      priority: json['priority']?.toString() ?? 'B',
      status: json['status']?.toString() ?? 'new',
      aiScore: (json['aiScore'] as num?)?.toInt() ?? 0,
      injuryRisk: (json['injuryRisk'] as num?)?.toInt() ?? 0,
      foot: json['foot']?.toString() ?? '',
      height: (json['height'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
      assists: (json['assists'] as num?)?.toInt() ?? 0,
      matches: (json['matches'] as num?)?.toInt() ?? 0,
      speed: (json['speed'] as num?)?.toInt() ?? 0,
      dribble: (json['dribble'] as num?)?.toInt() ?? 0,
      passing: (json['passing'] as num?)?.toInt() ?? 0,
      defense: (json['defense'] as num?)?.toInt() ?? 0,
      physical: (json['physical'] as num?)?.toInt() ?? 0,
      mental: (json['mental'] as num?)?.toInt() ?? 0,
      contractEnd: json['contractEnd']?.toString() ?? '',
      agent: json['agent']?.toString(),
      addedDate: json['addedDate']?.toString() ?? '',
      notes: notesRaw
          .whereType<Map<String, dynamic>>()
          .map(ScoutNote.fromJson)
          .toList(),
      inWatchlist: json['inWatchlist'] == true,
      note: json['note']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      season: json['season']?.toString(),
    );
  }

  ScoutProspect copyWith({
    String? priority,
    String? status,
    bool? inWatchlist,
    List<ScoutNote>? notes,
  }) {
    return ScoutProspect(
      id: id,
      legacyId: legacyId,
      apiSportsId: apiSportsId,
      name: name,
      age: age,
      nationality: nationality,
      flag: flag,
      club: club,
      league: league,
      position: position,
      potential: potential,
      currentRating: currentRating,
      marketValue: marketValue,
      valueMK: valueMK,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      aiScore: aiScore,
      injuryRisk: injuryRisk,
      foot: foot,
      height: height,
      weight: weight,
      goals: goals,
      assists: assists,
      matches: matches,
      speed: speed,
      dribble: dribble,
      passing: passing,
      defense: defense,
      physical: physical,
      mental: mental,
      contractEnd: contractEnd,
      agent: agent,
      addedDate: addedDate,
      notes: notes ?? this.notes,
      inWatchlist: inWatchlist ?? this.inWatchlist,
      note: note,
      photoUrl: photoUrl,
      season: season,
    );
  }
}

class ScoutDashboardKpis {
  const ScoutDashboardKpis({
    this.totalProspects = 0,
    this.watchlistCount = 0,
    this.reportsCount = 0,
    this.validatedCount = 0,
    this.inProgress = 0,
    this.avgPotential = 0,
    this.avgAge = 0,
    this.priorityABudget = 0,
  });

  final int totalProspects;
  final int watchlistCount;
  final int reportsCount;
  final int validatedCount;
  final int inProgress;
  final double avgPotential;
  final double avgAge;
  final double priorityABudget;

  factory ScoutDashboardKpis.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScoutDashboardKpis();
    return ScoutDashboardKpis(
      totalProspects: (json['totalProspects'] as num?)?.toInt() ?? 0,
      watchlistCount: (json['watchlistCount'] as num?)?.toInt() ?? 0,
      reportsCount: (json['reportsCount'] as num?)?.toInt() ?? 0,
      validatedCount: (json['validatedCount'] as num?)?.toInt() ?? 0,
      inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
      avgPotential: (json['avgPotential'] as num?)?.toDouble() ?? 0,
      avgAge: (json['avgAge'] as num?)?.toDouble() ?? 0,
      priorityABudget: (json['priorityABudget'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ScoutAiRec {
  const ScoutAiRec({
    required this.id,
    required this.name,
    this.pos = '',
    this.age = 0,
    this.club = '',
    this.flag = '',
    this.score = 0,
    this.budget = '',
    this.reasons = const [],
    this.photoUrl,
  });

  final String id;
  final String name;
  final String pos;
  final int age;
  final String club;
  final String flag;
  final int score;
  final String budget;
  final List<String> reasons;
  final String? photoUrl;

  factory ScoutAiRec.fromJson(Map<String, dynamic> json) => ScoutAiRec(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        pos: json['pos']?.toString() ?? '',
        age: (json['age'] as num?)?.toInt() ?? 0,
        club: json['club']?.toString() ?? '',
        flag: json['flag']?.toString() ?? '',
        score: (json['score'] as num?)?.toInt() ?? 0,
        budget: json['budget']?.toString() ?? '',
        reasons: (json['reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        photoUrl: json['photoUrl']?.toString(),
      );
}

class ScoutDashboard {
  const ScoutDashboard({
    this.clubName,
    this.season,
    this.kpis = const ScoutDashboardKpis(),
    this.workflowCounts = const {},
    this.priorityCounts = const {},
    this.aiRecs = const [],
    this.recentReports = const [],
    this.upcomingMissions = const [],
    this.byPosition = const [],
  });

  final String? clubName;
  final String? season;
  final ScoutDashboardKpis kpis;
  final Map<String, int> workflowCounts;
  final Map<String, int> priorityCounts;
  final List<ScoutAiRec> aiRecs;
  final List<ScoutRecentReport> recentReports;
  final List<ScoutMission> upcomingMissions;
  final List<({String name, int v})> byPosition;

  factory ScoutDashboard.fromJson(Map<String, dynamic> json) {
    final wf = <String, int>{};
    final rawWf = json['workflowCounts'];
    if (rawWf is Map) {
      rawWf.forEach((k, v) => wf[k.toString()] = (v as num?)?.toInt() ?? 0);
    }
    final pr = <String, int>{};
    final rawPr = json['priorityCounts'];
    if (rawPr is Map) {
      rawPr.forEach((k, v) => pr[k.toString()] = (v as num?)?.toInt() ?? 0);
    }
    return ScoutDashboard(
      clubName: json['clubName']?.toString(),
      season: json['season']?.toString(),
      kpis: ScoutDashboardKpis.fromJson(json['kpis'] as Map<String, dynamic>?),
      workflowCounts: wf,
      priorityCounts: pr,
      aiRecs: (json['aiRecs'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ScoutAiRec.fromJson)
              .toList() ??
          [],
      recentReports: (json['recentReports'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ScoutRecentReport.fromJson)
              .toList() ??
          [],
      upcomingMissions: (json['upcomingMissions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ScoutMission.fromJson)
              .toList() ??
          [],
      byPosition: (json['byPosition'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => (name: e['name']?.toString() ?? '', v: (e['v'] as num?)?.toInt() ?? 0))
              .toList() ??
          [],
    );
  }
}

class ScoutRecentReport {
  const ScoutRecentReport({
    required this.id,
    required this.prospectName,
    this.aiScore,
    this.decision = '',
    this.createdAt = '',
  });

  final String id;
  final String prospectName;
  final int? aiScore;
  final String decision;
  final String createdAt;

  factory ScoutRecentReport.fromJson(Map<String, dynamic> json) => ScoutRecentReport(
        id: json['id']?.toString() ?? '',
        prospectName: json['prospectName']?.toString() ?? '',
        aiScore: (json['aiScore'] as num?)?.toInt(),
        decision: json['decision']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class ScoutReport {
  const ScoutReport({
    required this.id,
    this.prospectId,
    required this.prospectName,
    this.scoutName = '',
    this.matchDate,
    this.matchObserved,
    this.opponent,
    this.technique = 50,
    this.physique = 50,
    this.mental = 50,
    this.tactique = 50,
    this.vitesse = 50,
    this.strengths,
    this.weaknesses,
    this.recommendation,
    this.decision = 'observe',
    this.aiScore,
    this.status = '',
    this.createdAt = '',
  });

  final String id;
  final String? prospectId;
  final String prospectName;
  final String scoutName;
  final String? matchDate;
  final String? matchObserved;
  final String? opponent;
  final int technique;
  final int physique;
  final int mental;
  final int tactique;
  final int vitesse;
  final String? strengths;
  final String? weaknesses;
  final String? recommendation;
  final String decision;
  final int? aiScore;
  final String status;
  final String createdAt;

  factory ScoutReport.fromJson(Map<String, dynamic> json) => ScoutReport(
        id: json['id']?.toString() ?? '',
        prospectId: json['prospectId']?.toString(),
        prospectName: json['prospectName']?.toString() ?? '',
        scoutName: json['scoutName']?.toString() ?? '',
        matchDate: json['matchDate']?.toString(),
        matchObserved: json['matchObserved']?.toString(),
        opponent: json['opponent']?.toString(),
        technique: (json['technique'] as num?)?.toInt() ?? 50,
        physique: (json['physique'] as num?)?.toInt() ?? 50,
        mental: (json['mental'] as num?)?.toInt() ?? 50,
        tactique: (json['tactique'] as num?)?.toInt() ?? 50,
        vitesse: (json['vitesse'] as num?)?.toInt() ?? 50,
        strengths: json['strengths']?.toString(),
        weaknesses: json['weaknesses']?.toString(),
        recommendation: json['recommendation']?.toString(),
        decision: json['decision']?.toString() ?? 'observe',
        aiScore: (json['aiScore'] as num?)?.toInt(),
        status: json['status']?.toString() ?? '',
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class ScoutMission {
  const ScoutMission({
    required this.id,
    required this.title,
    required this.date,
    this.time,
    this.location,
    this.notes,
    this.extra,
  });

  final String id;
  final String title;
  final String date;
  final String? time;
  final String? location;
  final String? notes;
  final dynamic extra;

  factory ScoutMission.fromJson(Map<String, dynamic> json) => ScoutMission(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString(),
        location: json['location']?.toString(),
        notes: json['notes']?.toString(),
        extra: json['extra'],
      );
}

class ScoutProfile {
  const ScoutProfile({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.clubName = '',
    this.country = '',
    this.league = '',
    this.role = 'Scout',
    this.specialization = '',
    this.regions = const [],
    this.positions = const [],
    this.budgetMax = '25',
    this.ageMin = '16',
    this.ageMax = '25',
    this.notifyNewProspect = true,
    this.notifyShortlist = true,
    this.notifyMissionReminder = true,
    this.language = 'fr',
    this.season = '2026-2027',
    this.avatarUrl = '',
    this.stats = const ScoutProfileStats(),
  });

  final String fullName;
  final String email;
  final String phone;
  final String clubName;
  final String country;
  final String league;
  final String role;
  final String specialization;
  final List<String> regions;
  final List<String> positions;
  final String budgetMax;
  final String ageMin;
  final String ageMax;
  final bool notifyNewProspect;
  final bool notifyShortlist;
  final bool notifyMissionReminder;
  final String language;
  final String season;
  final String avatarUrl;
  final ScoutProfileStats stats;

  factory ScoutProfile.fromJson(Map<String, dynamic> json) => ScoutProfile(
        fullName: json['fullName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        clubName: json['clubName']?.toString() ?? '',
        country: json['country']?.toString() ?? '',
        league: json['league']?.toString() ?? '',
        role: json['role']?.toString() ?? 'Scout',
        specialization: json['specialization']?.toString() ?? '',
        regions: (json['regions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        positions: (json['positions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        budgetMax: json['budgetMax']?.toString() ?? '25',
        ageMin: json['ageMin']?.toString() ?? '16',
        ageMax: json['ageMax']?.toString() ?? '25',
        notifyNewProspect: json['notifyNewProspect'] != false,
        notifyShortlist: json['notifyShortlist'] != false,
        notifyMissionReminder: json['notifyMissionReminder'] != false,
        language: json['language']?.toString() ?? 'fr',
        season: json['season']?.toString() ?? '2026-2027',
        avatarUrl: json['avatarUrl']?.toString() ?? '',
        stats: ScoutProfileStats.fromJson(json['stats'] as Map<String, dynamic>?),
      );

  Map<String, dynamic> toUpdateBody() => {
        'fullName': fullName.trim(),
        'phone': phone.trim(),
        'specialization': specialization.trim(),
        'regions': regions,
        'positions': positions,
        'budgetMax': budgetMax,
        'ageMin': ageMin,
        'ageMax': ageMax,
        'notifyNewProspect': notifyNewProspect,
        'notifyShortlist': notifyShortlist,
        'notifyMissionReminder': notifyMissionReminder,
        'language': language,
      };

  ScoutProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? clubName,
    String? country,
    String? league,
    String? role,
    String? specialization,
    List<String>? regions,
    List<String>? positions,
    String? budgetMax,
    String? ageMin,
    String? ageMax,
    bool? notifyNewProspect,
    bool? notifyShortlist,
    bool? notifyMissionReminder,
    String? language,
    String? season,
    String? avatarUrl,
    ScoutProfileStats? stats,
  }) {
    return ScoutProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      clubName: clubName ?? this.clubName,
      country: country ?? this.country,
      league: league ?? this.league,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      regions: regions ?? this.regions,
      positions: positions ?? this.positions,
      budgetMax: budgetMax ?? this.budgetMax,
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      notifyNewProspect: notifyNewProspect ?? this.notifyNewProspect,
      notifyShortlist: notifyShortlist ?? this.notifyShortlist,
      notifyMissionReminder: notifyMissionReminder ?? this.notifyMissionReminder,
      language: language ?? this.language,
      season: season ?? this.season,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      stats: stats ?? this.stats,
    );
  }
}

class ScoutProfileStats {
  const ScoutProfileStats({
    this.missionsThisMonth = 0,
    this.reportsSubmitted = 0,
    this.reportsThisMonth = 0,
    this.prospectsFollowed = 0,
    this.prospectsTotal = 0,
    this.conversionRate = 0,
  });

  final int missionsThisMonth;
  final int reportsSubmitted;
  final int reportsThisMonth;
  final int prospectsFollowed;
  final int prospectsTotal;
  final double conversionRate;

  factory ScoutProfileStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScoutProfileStats();
    return ScoutProfileStats(
      missionsThisMonth: (json['missionsThisMonth'] as num?)?.toInt() ?? 0,
      reportsSubmitted: (json['reportsSubmitted'] as num?)?.toInt() ?? 0,
      reportsThisMonth: (json['reportsThisMonth'] as num?)?.toInt() ?? 0,
      prospectsFollowed: (json['prospectsFollowed'] as num?)?.toInt() ?? 0,
      prospectsTotal: (json['prospectsTotal'] as num?)?.toInt() ?? 0,
      conversionRate: (json['conversionRate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ScoutMapContinent {
  const ScoutMapContinent({
    required this.id,
    required this.name,
    this.icon = '',
    this.color = '#FF7A00',
    this.countries = 0,
    this.prospects = 0,
    this.teams = 0,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final int countries;
  final int prospects;
  final int teams;

  factory ScoutMapContinent.fromJson(Map<String, dynamic> json) => ScoutMapContinent(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        icon: json['icon']?.toString() ?? '',
        color: json['color']?.toString() ?? '#FF7A00',
        countries: (json['countries'] as num?)?.toInt() ?? 0,
        prospects: (json['prospects'] as num?)?.toInt() ?? 0,
        teams: (json['teams'] as num?)?.toInt() ?? 0,
      );
}

class ScoutMapCountry {
  const ScoutMapCountry({
    required this.id,
    required this.name,
    this.flag = '',
    this.teamCount = 0,
    this.prospects = 0,
    this.leagues = const [],
    this.leagueId,
    this.leagueLogoUrl,
  });

  final String id;
  final String name;
  final String flag;
  final int teamCount;
  final int prospects;
  final List<String> leagues;
  final String? leagueId;
  final String? leagueLogoUrl;

  factory ScoutMapCountry.fromJson(Map<String, dynamic> json) => ScoutMapCountry(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        flag: json['flag']?.toString() ?? '',
        teamCount: (json['teamCount'] as num?)?.toInt() ?? 0,
        prospects: (json['prospects'] as num?)?.toInt() ?? 0,
        leagues: (json['leagues'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        leagueId: json['leagueId']?.toString(),
        leagueLogoUrl: json['leagueLogoUrl']?.toString(),
      );
}

class ScoutMapTeam {
  const ScoutMapTeam({
    required this.id,
    required this.name,
    this.league = '',
    this.city = '',
    this.playerCount = 0,
    this.avgPotential = 0,
    this.logoUrl,
    this.dbProspects = 0,
  });

  final String id;
  final String name;
  final String league;
  final String city;
  final int playerCount;
  final int avgPotential;
  final String? logoUrl;
  final int dbProspects;

  factory ScoutMapTeam.fromJson(Map<String, dynamic> json) => ScoutMapTeam(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        league: json['league']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        playerCount: (json['playerCount'] as num?)?.toInt() ?? 0,
        avgPotential: (json['avgPotential'] as num?)?.toInt() ?? 0,
        logoUrl: json['logoUrl']?.toString(),
        dbProspects: (json['dbProspects'] as num?)?.toInt() ?? 0,
      );
}

class ScoutSquadPlayer {
  const ScoutSquadPlayer({
    required this.id,
    required this.name,
    this.position = '',
    this.age = 0,
    this.nationality = '',
    this.flag = '',
    this.potential = 0,
    this.currentRating = 0,
    this.marketValue = '',
    this.source = 'ai',
    this.inDatabase = false,
    this.prospectId,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String position;
  final int age;
  final String nationality;
  final String flag;
  final int potential;
  final int currentRating;
  final String marketValue;
  final String source;
  final bool inDatabase;
  final String? prospectId;
  final String? photoUrl;

  factory ScoutSquadPlayer.fromJson(Map<String, dynamic> json) => ScoutSquadPlayer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        position: json['position']?.toString() ?? '',
        age: (json['age'] as num?)?.toInt() ?? 0,
        nationality: json['nationality']?.toString() ?? '',
        flag: json['flag']?.toString() ?? '',
        potential: (json['potential'] as num?)?.toInt() ?? 0,
        currentRating: (json['currentRating'] as num?)?.toInt() ?? 0,
        marketValue: json['marketValue']?.toString() ?? '',
        source: json['source']?.toString() ?? 'ai',
        inDatabase: json['inDatabase'] == true,
        prospectId: json['prospectId']?.toString(),
        photoUrl: json['photoUrl']?.toString(),
      );
}

class ScoutSearchFilters {
  const ScoutSearchFilters({
    this.position,
    this.country,
    this.ageBand,
    this.potentialBand,
    this.budgetBand,
    this.query = '',
  });

  final String? position;
  final String? country;
  final String? ageBand;
  final String? potentialBand;
  final String? budgetBand;
  final String query;

  Map<String, dynamic> toJson() => {
        if (position != null && position!.isNotEmpty) 'position': position,
        if (country != null && country!.isNotEmpty) 'country': country,
        if (ageBand != null && ageBand!.isNotEmpty) 'age': ageBand,
        if (potentialBand != null && potentialBand!.isNotEmpty) 'potential': potentialBand,
        if (budgetBand != null && budgetBand!.isNotEmpty) 'budget': budgetBand,
        if (query.isNotEmpty) 'query': query,
      };

  ScoutSearchFilters copyWith({
    String? position,
    String? country,
    String? ageBand,
    String? potentialBand,
    String? budgetBand,
    String? query,
    bool clearPosition = false,
    bool clearCountry = false,
    bool clearAge = false,
    bool clearPotential = false,
    bool clearBudget = false,
  }) {
    return ScoutSearchFilters(
      position: clearPosition ? null : (position ?? this.position),
      country: clearCountry ? null : (country ?? this.country),
      ageBand: clearAge ? null : (ageBand ?? this.ageBand),
      potentialBand: clearPotential ? null : (potentialBand ?? this.potentialBand),
      budgetBand: clearBudget ? null : (budgetBand ?? this.budgetBand),
      query: query ?? this.query,
    );
  }
}

class ScoutSearchResult {
  const ScoutSearchResult({
    required this.id,
    required this.name,
    this.club = '',
    this.position = '',
    this.age = 0,
    this.potential = 0,
    this.flag = '',
    this.aiScore = 0,
    this.inDatabase = false,
    this.source = 'database',
    this.photoUrl,
    this.marketValue = '',
  });

  final String id;
  final String name;
  final String club;
  final String position;
  final int age;
  final int potential;
  final String flag;
  final int aiScore;
  final bool inDatabase;
  final String source;
  final String? photoUrl;
  final String marketValue;

  factory ScoutSearchResult.fromJson(Map<String, dynamic> json) => ScoutSearchResult(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        club: json['club']?.toString() ?? '',
        position: json['position']?.toString() ?? '',
        age: (json['age'] as num?)?.toInt() ?? 0,
        potential: (json['potential'] as num?)?.toInt() ?? 0,
        flag: json['flag']?.toString() ?? '',
        aiScore: (json['aiScore'] as num?)?.toInt() ?? 0,
        inDatabase: json['inDatabase'] == true,
        source: json['source']?.toString() ?? 'database',
        photoUrl: json['photoUrl']?.toString(),
        marketValue: json['marketValue']?.toString() ?? '',
      );
}

class ScoutSearchResponse {
  const ScoutSearchResponse({
    this.summary = '',
    this.results = const [],
    this.aiEnabled = false,
    this.model = '',
  });

  final String summary;
  final List<ScoutSearchResult> results;
  final bool aiEnabled;
  final String model;

  factory ScoutSearchResponse.fromJson(Map<String, dynamic> json) => ScoutSearchResponse(
        summary: json['summary']?.toString() ?? '',
        results: (json['results'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(ScoutSearchResult.fromJson)
                .toList() ??
            [],
        aiEnabled: json['aiEnabled'] == true,
        model: json['model']?.toString() ?? '',
      );
}

class ScoutAiHit {
  const ScoutAiHit({
    required this.id,
    required this.name,
    this.rank = 0,
    this.club = '',
    this.position = '',
    this.age = 0,
    this.potential = 0,
    this.flag = '',
    this.aiScore = 0,
    this.compatibility = 0,
    this.reasoning = const [],
    this.recommendation = '',
    this.inDatabase = false,
    this.photoUrl,
  });

  final String id;
  final String name;
  final int rank;
  final String club;
  final String position;
  final int age;
  final int potential;
  final String flag;
  final int aiScore;
  final int compatibility;
  final List<String> reasoning;
  final String recommendation;
  final bool inDatabase;
  final String? photoUrl;

  factory ScoutAiHit.fromJson(Map<String, dynamic> json) => ScoutAiHit(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        club: json['club']?.toString() ?? '',
        position: json['position']?.toString() ?? '',
        age: (json['age'] as num?)?.toInt() ?? 0,
        potential: (json['potential'] as num?)?.toInt() ?? 0,
        flag: json['flag']?.toString() ?? '',
        aiScore: (json['aiScore'] as num?)?.toInt() ?? 0,
        compatibility: (json['compatibility'] as num?)?.toInt() ?? 0,
        reasoning: (json['reasoning'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        recommendation: json['recommendation']?.toString() ?? '',
        inDatabase: json['inDatabase'] == true,
        photoUrl: json['photoUrl']?.toString(),
      );
}

class ScoutAgent {
  const ScoutAgent({
    required this.id,
    required this.name,
    this.agency = '',
    this.email = '',
    this.phone = '',
    this.country = '',
    this.flag = '',
    this.rating = 0,
    this.deals = 0,
    this.status = 'actif',
    this.aiNotes,
  });

  final String id;
  final String name;
  final String agency;
  final String email;
  final String phone;
  final String country;
  final String flag;
  final double rating;
  final int deals;
  final String status;
  final String? aiNotes;

  factory ScoutAgent.fromJson(Map<String, dynamic> json) => ScoutAgent(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        agency: json['agency']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        country: json['country']?.toString() ?? '',
        flag: json['flag']?.toString() ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        deals: (json['deals'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'actif',
        aiNotes: json['aiNotes']?.toString(),
      );
}
