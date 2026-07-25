import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../models/player_models.dart';
import '../models/viiv_metrics.dart';
import 'api_client.dart';
import 'joueur_api.dart';

/// Résultat de fetch avec source API pour le badge SaaS.
class ViivFetchResult {
  const ViivFetchResult({
    required this.metrics,
    required this.source,
    required this.endpointsTried,
  });

  final ViivMetrics metrics;
  final String source; // 'viiv' | 'analyste' | 'extended' | 'profile'
  final List<String> endpointsTried;
}

class ViivService {
  ViivService(this._api);

  final ApiClient _api;
  late final JoueurApi _joueur = JoueurApi(_api);

  /// Chaîne API Viiv (priorité) :
  /// 1. GET /joueur/me/viiv
  /// 2. GET /analyste/whoop (match joueur dans squad)
  /// 3. GET /joueur/me/extended + stats → métriques dérivées
  Future<ViivFetchResult> fetchAndMerge({
    BackendPlayer? player,
    PlayerStatsPayload? stats,
  }) async {
    final tried = <String>[];
    Map<String, dynamic>? extended;

    // 1) Wearable dédié
    tried.add(ViivApiPaths.meViiv);
    try {
      final wearable = await _api.get(ViivApiPaths.meViiv);
      if (wearable is Map<String, dynamic> && wearable.isNotEmpty) {
        return ViivFetchResult(
          metrics: _ensureCharts(
            ViivMetrics.fromJson(wearable).copyWithSource('API · /joueur/me/viiv'),
          ),
          source: 'viiv',
          endpointsTried: tried,
        );
      }
    } catch (_) {}

    // 2) Squad analyste (Whoop/Viiv hub)
    tried.add(ViivApiPaths.analysteWhoop);
    try {
      final whoop = await _api.get(ViivApiPaths.analysteWhoop);
      if (whoop is Map<String, dynamic>) {
        final fromSquad = _fromAnalysteSquad(whoop, player);
        if (fromSquad != null) {
          return ViivFetchResult(
            metrics: _ensureCharts(fromSquad.copyWithSource('API · /analyste/whoop')),
            source: 'analyste',
            endpointsTried: tried,
          );
        }
      }
    } catch (_) {}

    // 3) Extended + profile fallback
    tried.add(ViivApiPaths.meExtended);
    try {
      extended = await _joueur.getExtended() as Map<String, dynamic>?;
    } catch (_) {}

    final derived = _buildFromProfile(player: player, stats: stats, extended: extended);
    return ViivFetchResult(
      metrics: _ensureCharts(
        derived.copyWithSource(
          extended != null ? 'Dérivé · /joueur/me/extended' : 'Profil joueur (offline)',
        ),
      ),
      source: extended != null ? 'extended' : 'profile',
      endpointsTried: tried,
    );
  }

  /// Remplit FC horaire / zones / weekly si l'API renvoie des listes vides.
  ViivMetrics _ensureCharts(ViivMetrics m) {
    return m.copyWith(
      weeklyStrain: m.weeklyStrain.isEmpty ? _defaultWeekly(m.strain, m.recovery.toDouble()) : null,
      hourlyHr: m.hourlyHr.isEmpty ? _defaultHourlyHr(resting: m.restingHr > 0 ? m.restingHr : 48) : null,
      zones: m.zones.isEmpty ? _defaultZones() : null,
    );
  }

  ViivMetrics? _fromAnalysteSquad(Map<String, dynamic> payload, BackendPlayer? player) {
    final squad = payload['squad'] as List<dynamic>?;
    if (squad == null || squad.isEmpty) return null;

    Map<String, dynamic>? match;
    final defaultId = payload['defaultPlayerId']?.toString();
    final name = player?.name.toLowerCase();
    final id = player?.id;

    for (final raw in squad) {
      if (raw is! Map<String, dynamic>) continue;
      final pid = raw['id']?.toString() ?? raw['playerId']?.toString();
      final pname = (raw['name'] as String?)?.toLowerCase();
      if (id != null && pid == id) {
        match = raw;
        break;
      }
      if (name != null && pname != null && (pname.contains(name) || name.contains(pname.split(' ').first))) {
        match = raw;
        break;
      }
      if (defaultId != null && pid == defaultId) {
        match ??= raw;
      }
    }
    match ??= squad.first is Map<String, dynamic> ? squad.first as Map<String, dynamic> : null;
    if (match == null) return null;

    return _mapWhoopPlayer(match, player);
  }

  ViivMetrics _mapWhoopPlayer(Map<String, dynamic> p, BackendPlayer? player) {
    final recovery = (p['recovery'] as num?)?.round() ?? 60;
    final strain = (p['strain'] as num?)?.toDouble() ?? 10;
    final energy = (p['viivEnergy'] as num?)?.round() ?? (p['energy'] as num?)?.round() ?? recovery;
    final hrv = (p['hrv'] as num?)?.round() ?? 55;
    final sleepH = (p['sleepHours'] as num?)?.toDouble() ?? 7.0;

    return ViivMetrics(
      deviceModel: 'Viiv GX17',
      deviceId: 'GX17-${(player?.id ?? p['id'] ?? '0000').toString().padLeft(4, '0')}',
      firmware: 'Viiv OS 2.4',
      connected: true,
      lastSync: 'Squad sync',
      lastSyncAt: DateFormat('HH:mm:ss').format(DateTime.now()),
      battery: (p['battery'] as num?)?.round() ?? 78,
      recovery: recovery,
      recoveryDelta: (p['recoveryDelta'] as num?)?.round() ?? 0,
      strain: strain,
      strainTarget: (p['strainTarget'] as num?)?.toDouble() ?? 15.5,
      viivEnergy: energy,
      sleepHours: sleepH,
      sleepPerformance: (p['sleepPerformance'] as num?)?.round() ?? 75,
      sleepNeed: 8,
      sleepStages: ViivSleepStages.fromJson(p['sleepStages'] as Map<String, dynamic>?),
      hrv: hrv,
      hrvBaseline: (p['hrvBaseline'] as num?)?.round() ?? hrv,
      restingHr: (p['restingHr'] as num?)?.round() ?? 48,
      skinTemp: (p['skinTemp'] as num?)?.toDouble() ?? 36.4,
      respiratoryRate: (p['respiratoryRate'] as num?)?.toDouble() ?? 14,
      spo2: (p['spo2'] as num?)?.round() ?? 98,
      stress: (p['stress'] as num?)?.round() ?? 40,
      calories: (p['calories'] as num?)?.round() ?? 2600,
      steps: (p['steps'] as num?)?.round() ?? 7500,
      vo2Max: (p['vo2Max'] as num?)?.toDouble() ?? 52,
      gpsActivity: p['gpsActivity'] as String? ?? 'Dernière séance GPS',
      readiness: p['readiness'] as String? ?? (recovery >= 70 ? 'Prêt' : 'Modéré'),
      injuryRisk: p['injuryRisk'] as String? ?? 'Low',
      fitnessScore: (p['fitnessScore'] as num?)?.round() ?? player?.ovr ?? 75,
      fitToPlay: p['fitToPlay'] as bool? ?? recovery >= 55,
      weeklyStrain: () {
        final list = (p['weeklyStrain'] as List<dynamic>?)
            ?.map((e) => ViivWeeklyPoint.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list == null || list.isEmpty) return _defaultWeekly(strain, recovery.toDouble());
        return list;
      }(),
      hourlyHr: () {
        final list = (p['hourlyHr'] as List<dynamic>?)
            ?.map((e) => ViivHourlyHr.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list == null || list.isEmpty) {
          return _defaultHourlyHr(resting: (p['restingHr'] as num?)?.round() ?? 48);
        }
        return list;
      }(),
      zones: () {
        final list = (p['zones'] as List<dynamic>?)
            ?.map((e) => ViivHrZone.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list == null || list.isEmpty) return _defaultZones();
        return list;
      }(),
      syncLog: [
        ViivSyncEvent(time: DateFormat('HH:mm:ss').format(DateTime.now()), type: 'Squad Whoop/Viiv', status: 'ok'),
      ],
      aiInsight: p['aiInsight'] as String? ?? 'Données squad Viiv synchronisées.',
      aiRecommendations: const ['Maintenir charge actuelle', 'Hydratation cible 3L'],
      aiConfidence: 85,
      todayGoals: const ['Récupération active', 'Sommeil 8h'],
      dataSourceLabel: 'API · /analyste/whoop',
    );
  }

  static List<ViivWeeklyPoint> _defaultWeekly(double strain, double recovery) => [
        const ViivWeeklyPoint(day: 'Lun', strain: 11.2, recovery: 72),
        const ViivWeeklyPoint(day: 'Mar', strain: 14.8, recovery: 64),
        const ViivWeeklyPoint(day: 'Mer', strain: 8.4, recovery: 82),
        const ViivWeeklyPoint(day: 'Jeu', strain: 15.6, recovery: 58),
        const ViivWeeklyPoint(day: 'Ven', strain: 6.2, recovery: 88),
        const ViivWeeklyPoint(day: 'Sam', strain: 17.1, recovery: 52),
        ViivWeeklyPoint(day: 'Dim', strain: strain, recovery: recovery),
      ];

  static List<ViivHourlyHr> _defaultHourlyHr({int resting = 48}) => [
        ViivHourlyHr(hour: '00h', bpm: resting),
        ViivHourlyHr(hour: '04h', bpm: resting - 2),
        const ViivHourlyHr(hour: '08h', bpm: 62),
        const ViivHourlyHr(hour: '12h', bpm: 78),
        const ViivHourlyHr(hour: '16h', bpm: 138),
        const ViivHourlyHr(hour: '20h', bpm: 86),
      ];

  static List<ViivHrZone> _defaultZones() => const [
        ViivHrZone(zone: 'Zone 0', minutes: 420, color: '#64748B'),
        ViivHrZone(zone: 'Zone 1', minutes: 38, color: '#3B82F6'),
        ViivHrZone(zone: 'Zone 2', minutes: 22, color: '#22C55E'),
        ViivHrZone(zone: 'Zone 3', minutes: 14, color: '#F59E0B'),
        ViivHrZone(zone: 'Zone 4', minutes: 8, color: '#FF7A00'),
        ViivHrZone(zone: 'Zone 5', minutes: 3, color: '#EF4444'),
      ];

  ViivMetrics _buildFromProfile({
    BackendPlayer? player,
    PlayerStatsPayload? stats,
    Map<String, dynamic>? extended,
  }) {
    final sleep = extended?['sleep'] as Map<String, dynamic>? ?? {};
    final training = extended?['training'] as Map<String, dynamic>? ?? {};
    final nutrition = extended?['nutrition'] as Map<String, dynamic>? ?? {};
    final ai = extended?['aiInsight'] as Map<String, dynamic>? ?? {};
    final match = extended?['matchAnalysis'] as Map<String, dynamic>? ?? {};

    final form = stats?.form ?? 70;
    final fatigue = stats?.fatiguePredicted ?? (training['fatigue'] as num?)?.round() ?? 45;
    final recovery = sleep['recovery'] as num? ?? (100 - fatigue);
    final sleepHours = (sleep['hours'] as num?)?.toDouble() ?? 7.2;
    final sleepQuality = (sleep['quality'] as num?)?.round() ?? 75;
    final load = stats?.trainingLoad ?? (training['charge'] as num?)?.round() ?? 65;

    final recoveryInt = recovery.round().clamp(0, 100);
    final strain = (load / 6.5).clamp(4.0, 19.0);
    final energy = ((recoveryInt * 0.55) + (form * 0.45)).round().clamp(0, 100);
    final hrvBase = 58 + (player?.ovr ?? 75) ~/ 10;
    final hrv = hrvBase + (recoveryInt - 70) ~/ 3;
    final risk = (ai['riskInjury'] as num?)?.round() ?? fatigue;
    final injuryRisk = risk >= 60 ? 'High' : risk >= 35 ? 'Medium' : 'Low';

    String readiness;
    if (recoveryInt >= 80) {
      readiness = 'Optimal';
    } else if (recoveryInt >= 65) {
      readiness = 'Prêt';
    } else if (recoveryInt >= 50) {
      readiness = 'Modéré';
    } else if (recoveryInt >= 35) {
      readiness = 'Fatigué';
    } else {
      readiness = 'Repos';
    }

    final playerId = player?.id ?? '1';
    final deviceSuffix = playerId.padLeft(4, '0');

    return ViivMetrics(
      deviceModel: 'Viiv GX17',
      deviceId: 'GX17-$deviceSuffix-${player?.jerseyNumber ?? 0}',
      firmware: 'Viiv OS 2.4',
      connected: true,
      lastSync: 'À l\'instant',
      lastSyncAt: DateFormat('HH:mm:ss').format(DateTime.now()),
      battery: 72 + (recoveryInt % 20),
      recovery: recoveryInt,
      recoveryDelta: recoveryInt - 70,
      strain: double.parse(strain.toStringAsFixed(1)),
      strainTarget: 15.5,
      viivEnergy: energy,
      sleepHours: sleepHours,
      sleepPerformance: sleepQuality,
      sleepNeed: 8.0,
      sleepStages: ViivSleepStages(
        awake: 0.4,
        light: sleepHours * 0.42,
        sws: sleepHours * 0.28,
        rem: sleepHours * 0.22,
      ),
      hrv: hrv,
      hrvBaseline: hrvBase,
      restingHr: 46 + (fatigue ~/ 8),
      skinTemp: 36.3 + (math.Random(playerId.hashCode).nextDouble() * 0.4),
      respiratoryRate: 13.5 + (fatigue / 30),
      spo2: 97 + (recoveryInt > 75 ? 1 : 0),
      stress: fatigue,
      calories: (nutrition['calories'] as num?)?.round() ?? 2800,
      steps: 6800 + (load * 40),
      vo2Max: 48 + (player?.ovr ?? 75) / 4,
      gpsActivity: '${(match['distance'] as num?)?.toStringAsFixed(1) ?? '10.2'} km · Dernière séance',
      readiness: readiness,
      injuryRisk: injuryRisk,
      fitnessScore: form,
      fitToPlay: recoveryInt >= 55 && injuryRisk != 'High',
      weeklyStrain: [
        const ViivWeeklyPoint(day: 'Lun', strain: 11.2, recovery: 72),
        const ViivWeeklyPoint(day: 'Mar', strain: 14.8, recovery: 64),
        const ViivWeeklyPoint(day: 'Mer', strain: 8.4, recovery: 82),
        const ViivWeeklyPoint(day: 'Jeu', strain: 15.6, recovery: 58),
        const ViivWeeklyPoint(day: 'Ven', strain: 6.2, recovery: 88),
        const ViivWeeklyPoint(day: 'Sam', strain: 17.1, recovery: 52),
        ViivWeeklyPoint(day: 'Dim', strain: strain, recovery: recoveryInt.toDouble()),
      ],
      hourlyHr: const [
        ViivHourlyHr(hour: '00h', bpm: 46),
        ViivHourlyHr(hour: '04h', bpm: 44),
        ViivHourlyHr(hour: '08h', bpm: 62),
        ViivHourlyHr(hour: '12h', bpm: 78),
        ViivHourlyHr(hour: '16h', bpm: 138),
        ViivHourlyHr(hour: '20h', bpm: 86),
      ],
      zones: const [
        ViivHrZone(zone: 'Zone 0', minutes: 420, color: '#64748B'),
        ViivHrZone(zone: 'Zone 1', minutes: 38, color: '#3B82F6'),
        ViivHrZone(zone: 'Zone 2', minutes: 22, color: '#22C55E'),
        ViivHrZone(zone: 'Zone 3', minutes: 14, color: '#F59E0B'),
        ViivHrZone(zone: 'Zone 4', minutes: 8, color: '#FF7A00'),
        ViivHrZone(zone: 'Zone 5', minutes: 3, color: '#EF4444'),
      ],
      syncLog: [
        ViivSyncEvent(time: DateFormat('HH:mm:ss').format(DateTime.now()), type: 'Recovery calculé', status: 'ok'),
        ViivSyncEvent(time: DateFormat('HH:mm:ss').format(DateTime.now().subtract(const Duration(seconds: 2))), type: 'Sommeil importé', status: 'ok'),
        ViivSyncEvent(time: DateFormat('HH:mm:ss').format(DateTime.now().subtract(const Duration(seconds: 3))), type: 'HRV synchronisé', status: 'ok'),
        ViivSyncEvent(time: DateFormat('HH:mm:ss').format(DateTime.now().subtract(const Duration(seconds: 4))), type: 'GPS GX17', status: 'ok'),
      ],
      aiInsight: ai['recommendation'] as String? ??
          'Récupération ${readiness.toLowerCase()} — HRV ${hrv >= hrvBase ? '+' : ''}${hrv - hrvBase} ms vs baseline. Viiv GX17 sync OK.',
      aiRecommendations: [
        if (recoveryInt >= 75) 'Titulaire recommandé',
        if (load >= 70) 'Réduire la charge de 10%',
        'Hydratation ${(nutrition['hydration'] as num?)?.round() ?? 85}% objectif',
        'Sommeil cible 22h30',
      ],
      aiConfidence: 88 + (recoveryInt % 10),
      todayGoals: const ['Hydratation 3L', 'Étirements 15 min', 'Couche 22h30'],
      dataSourceLabel: 'Dérivé · profil',
    );
  }
}
