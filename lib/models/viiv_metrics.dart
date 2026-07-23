class ViivSleepStages {
  const ViivSleepStages({
    this.awake = 0,
    this.light = 0,
    this.sws = 0,
    this.rem = 0,
  });

  final double awake;
  final double light;
  final double sws;
  final double rem;

  factory ViivSleepStages.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ViivSleepStages();
    double v(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return ViivSleepStages(awake: v('awake'), light: v('light'), sws: v('sws'), rem: v('rem'));
  }
}

class ViivSyncEvent {
  const ViivSyncEvent({
    required this.time,
    required this.type,
    required this.status,
  });

  final String time;
  final String type;
  final String status;

  factory ViivSyncEvent.fromJson(Map<String, dynamic> json) {
    return ViivSyncEvent(
      time: json['time'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? 'ok',
    );
  }
}

class ViivWeeklyPoint {
  const ViivWeeklyPoint({required this.day, required this.strain, required this.recovery});
  final String day;
  final double strain;
  final double recovery;

  factory ViivWeeklyPoint.fromJson(Map<String, dynamic> json) {
    return ViivWeeklyPoint(
      day: json['day'] as String? ?? '',
      strain: (json['strain'] as num?)?.toDouble() ?? 0,
      recovery: (json['recovery'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ViivHrZone {
  const ViivHrZone({required this.zone, required this.minutes, required this.color});
  final String zone;
  final int minutes;
  final String color;

  factory ViivHrZone.fromJson(Map<String, dynamic> json) {
    return ViivHrZone(
      zone: json['zone'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.round() ?? 0,
      color: json['color'] as String? ?? '#64748B',
    );
  }
}

class ViivHourlyHr {
  const ViivHourlyHr({required this.hour, required this.bpm});
  final String hour;
  final int bpm;

  factory ViivHourlyHr.fromJson(Map<String, dynamic> json) {
    return ViivHourlyHr(
      hour: json['hour'] as String? ?? '',
      bpm: (json['bpm'] as num?)?.round() ?? 0,
    );
  }
}

class ViivMetrics {
  const ViivMetrics({
    this.deviceModel = 'Viiv GX17',
    this.deviceId = '',
    this.firmware = 'Viiv OS 2.4',
    this.connected = false,
    this.lastSync = '—',
    this.lastSyncAt = '',
    this.battery = 0,
    this.recovery = 0,
    this.recoveryDelta = 0,
    this.strain = 0,
    this.strainTarget = 15,
    this.viivEnergy = 0,
    this.sleepHours = 0,
    this.sleepPerformance = 0,
    this.sleepNeed = 8,
    this.sleepStages = const ViivSleepStages(),
    this.hrv = 0,
    this.hrvBaseline = 0,
    this.restingHr = 0,
    this.skinTemp = 36.5,
    this.respiratoryRate = 14,
    this.spo2 = 98,
    this.stress = 0,
    this.calories = 0,
    this.steps = 0,
    this.vo2Max = 0,
    this.gpsActivity = '—',
    this.readiness = 'Modéré',
    this.injuryRisk = 'Low',
    this.fitnessScore = 0,
    this.fitToPlay = true,
    this.weeklyStrain = const [],
    this.hourlyHr = const [],
    this.zones = const [],
    this.syncLog = const [],
    this.aiInsight = '',
    this.aiRecommendations = const [],
    this.aiConfidence = 0,
    this.todayGoals = const [],
  });

  final String deviceModel;
  final String deviceId;
  final String firmware;
  final bool connected;
  final String lastSync;
  final String lastSyncAt;
  final int battery;
  final int recovery;
  final int recoveryDelta;
  final double strain;
  final double strainTarget;
  final int viivEnergy;
  final double sleepHours;
  final int sleepPerformance;
  final double sleepNeed;
  final ViivSleepStages sleepStages;
  final int hrv;
  final int hrvBaseline;
  final int restingHr;
  final double skinTemp;
  final double respiratoryRate;
  final int spo2;
  final int stress;
  final int calories;
  final int steps;
  final double vo2Max;
  final String gpsActivity;
  final String readiness;
  final String injuryRisk;
  final int fitnessScore;
  final bool fitToPlay;
  final List<ViivWeeklyPoint> weeklyStrain;
  final List<ViivHourlyHr> hourlyHr;
  final List<ViivHrZone> zones;
  final List<ViivSyncEvent> syncLog;
  final String aiInsight;
  final List<String> aiRecommendations;
  final int aiConfidence;
  final List<String> todayGoals;

  ViivMetrics copyWith({
    bool? connected,
    String? lastSync,
    String? lastSyncAt,
    int? battery,
    List<ViivSyncEvent>? syncLog,
  }) {
    return ViivMetrics(
      deviceModel: deviceModel,
      deviceId: deviceId,
      firmware: firmware,
      connected: connected ?? this.connected,
      lastSync: lastSync ?? this.lastSync,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      battery: battery ?? this.battery,
      recovery: recovery,
      recoveryDelta: recoveryDelta,
      strain: strain,
      strainTarget: strainTarget,
      viivEnergy: viivEnergy,
      sleepHours: sleepHours,
      sleepPerformance: sleepPerformance,
      sleepNeed: sleepNeed,
      sleepStages: sleepStages,
      hrv: hrv,
      hrvBaseline: hrvBaseline,
      restingHr: restingHr,
      skinTemp: skinTemp,
      respiratoryRate: respiratoryRate,
      spo2: spo2,
      stress: stress,
      calories: calories,
      steps: steps,
      vo2Max: vo2Max,
      gpsActivity: gpsActivity,
      readiness: readiness,
      injuryRisk: injuryRisk,
      fitnessScore: fitnessScore,
      fitToPlay: fitToPlay,
      weeklyStrain: weeklyStrain,
      hourlyHr: hourlyHr,
      zones: zones,
      syncLog: syncLog ?? this.syncLog,
      aiInsight: aiInsight,
      aiRecommendations: aiRecommendations,
      aiConfidence: aiConfidence,
      todayGoals: todayGoals,
    );
  }

  factory ViivMetrics.fromJson(Map<String, dynamic> json) {
    return ViivMetrics(
      deviceModel: json['deviceModel'] as String? ?? 'Viiv GX17',
      deviceId: json['deviceId'] as String? ?? '',
      firmware: json['firmware'] as String? ?? 'Viiv OS 2.4',
      connected: json['connected'] as bool? ?? false,
      lastSync: json['lastSync'] as String? ?? '—',
      lastSyncAt: json['lastSyncAt'] as String? ?? '',
      battery: (json['battery'] as num?)?.round() ?? 0,
      recovery: (json['recovery'] as num?)?.round() ?? 0,
      recoveryDelta: (json['recoveryDelta'] as num?)?.round() ?? 0,
      strain: (json['strain'] as num?)?.toDouble() ?? 0,
      strainTarget: (json['strainTarget'] as num?)?.toDouble() ?? 15,
      viivEnergy: (json['viivEnergy'] as num?)?.round() ?? 0,
      sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0,
      sleepPerformance: (json['sleepPerformance'] as num?)?.round() ?? 0,
      sleepNeed: (json['sleepNeed'] as num?)?.toDouble() ?? 8,
      sleepStages: ViivSleepStages.fromJson(json['sleepStages'] as Map<String, dynamic>?),
      hrv: (json['hrv'] as num?)?.round() ?? 0,
      hrvBaseline: (json['hrvBaseline'] as num?)?.round() ?? 0,
      restingHr: (json['restingHr'] as num?)?.round() ?? 0,
      skinTemp: (json['skinTemp'] as num?)?.toDouble() ?? 36.5,
      respiratoryRate: (json['respiratoryRate'] as num?)?.toDouble() ?? 14,
      spo2: (json['spo2'] as num?)?.round() ?? 98,
      stress: (json['stress'] as num?)?.round() ?? 0,
      calories: (json['calories'] as num?)?.round() ?? 0,
      steps: (json['steps'] as num?)?.round() ?? 0,
      vo2Max: (json['vo2Max'] as num?)?.toDouble() ?? 0,
      gpsActivity: json['gpsActivity'] as String? ?? '—',
      readiness: json['readiness'] as String? ?? 'Modéré',
      injuryRisk: json['injuryRisk'] as String? ?? 'Low',
      fitnessScore: (json['fitnessScore'] as num?)?.round() ?? 0,
      fitToPlay: json['fitToPlay'] as bool? ?? true,
      weeklyStrain: (json['weeklyStrain'] as List<dynamic>?)
              ?.map((e) => ViivWeeklyPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      hourlyHr: (json['hourlyHr'] as List<dynamic>?)
              ?.map((e) => ViivHourlyHr.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      zones: (json['zones'] as List<dynamic>?)
              ?.map((e) => ViivHrZone.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      syncLog: (json['syncLog'] as List<dynamic>?)
              ?.map((e) => ViivSyncEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      aiInsight: json['aiInsight'] as String? ?? '',
      aiRecommendations: (json['aiRecommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      aiConfidence: (json['aiConfidence'] as num?)?.round() ?? 0,
      todayGoals: (json['todayGoals'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
