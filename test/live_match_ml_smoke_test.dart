import 'dart:convert';
import 'dart:io';

import 'package:erp_club_player/models/analyste_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Smoke test: ML API → parse contrat Live Match (sans UI).
///
/// Prérequis: uvicorn sur le port défini par ANALYSTE_ML_URL
void main() {
  const mlBase = String.fromEnvironment(
    'ANALYSTE_ML_URL',
    defaultValue: 'http://127.0.0.1:8093',
  );

  test('GET /analyste/live-match returns real 2026/27 squad + ML fields', () async {
    final health = await http.get(Uri.parse('$mlBase/health'));
    expect(
      health.statusCode,
      200,
      reason: 'ML API must be running on $mlBase — start uvicorn first',
    );

    final uri = Uri.parse(
      '$mlBase/analyste/live-match?home=Real%20Madrid&away=Al%20Nassr',
    );
    final res = await http.get(uri);
    expect(res.statusCode, 200);

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final match = AnalysteLiveMatch.fromJson(json);

    expect(match.homeTeam, 'Real Madrid');
    expect(match.awayTeam, 'Al Nassr');
    expect(match.minute, greaterThan(0));
    expect(match.minuteData, isNotEmpty);
    expect(match.players, isNotEmpty);

    final names = match.players.map((p) => p.name).toSet();
    expect(names.contains('Jude Bellingham') || names.contains('Vinícius Júnior'), isTrue);
    expect(names.contains('Ali Mansouri'), isFalse);
    expect(names.contains('Karim Dridi'), isFalse);

    // ML fields present & in range
    for (final p in match.players) {
      expect(p.fatigue, inInclusiveRange(0, 100));
      expect(p.risk, inInclusiveRange(0, 100));
    }

    final topRisk = match.players.reduce((a, b) => a.risk >= b.risk ? a : b);
    expect(topRisk.risk, greaterThan(40), reason: 'high-load mid should elevate risk');

    final flagged = match.players.where((p) => p.shouldSub).map((p) => p.name).toList();
    stdout.writeln(
      '${match.homeTeam} vs ${match.awayTeam} · '
      '${match.homeScore}-${match.awayScore} · min ${match.minute} · '
      'topRisk=${topRisk.name} ${topRisk.risk}% · shouldSub=$flagged',
    );
  });
}
