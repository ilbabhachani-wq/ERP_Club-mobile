import 'package:latlong2/latlong.dart';

/// Coordonnées alignées sur le web (`scoutGeoCoords.ts`).
const continentCoords = <String, LatLng>{
  'afrique': LatLng(4, 20),
  'europe': LatLng(50, 15),
  'asie': LatLng(32, 95),
  'am-nord': LatLng(42, -98),
  'am-sud': LatLng(-12, -58),
  'oceanie': LatLng(-22, 135),
};

const countryCoords = <String, LatLng>{
  'tn': LatLng(34, 9.5),
  'dz': LatLng(28.5, 3),
  'ma': LatLng(33.5, -6.8),
  'ci': LatLng(7.5, -5.3),
  'sn': LatLng(14.7, -17.4),
  'ng': LatLng(9.5, 8),
  'eg': LatLng(30, 31),
  'fr': LatLng(46.5, 2.5),
  'es': LatLng(40.4, -3.7),
  'pt': LatLng(39.5, -8.6),
  'gb': LatLng(52.5, -1.5),
  'de': LatLng(51, 10.5),
  'it': LatLng(42.5, 12.5),
  'nl': LatLng(52.2, 5.5),
  'be': LatLng(50.8, 4.5),
  'br': LatLng(-15.8, -47.9),
  'ar': LatLng(-34.6, -58.4),
  'tr': LatLng(41.01, 28.97),
  'sa': LatLng(24.71, 46.72),
  'ae': LatLng(24.45, 54.37),
  'jp': LatLng(35.68, 139.69),
  'kr': LatLng(37.55, 127.03),
  'us': LatLng(34.05, -118.24),
  'mx': LatLng(19.43, -99.13),
  'ca': LatLng(43.65, -79.38),
  'au': LatLng(-33.87, 151.21),
  'nz': LatLng(-36.85, 174.76),
};

const teamCoords = <String, LatLng>{
  'est': LatLng(35.83, 10.64),
  'ca': LatLng(36.8, 10.18),
  'css': LatLng(34.74, 10.76),
  'st': LatLng(36.8, 10.18),
  'psg': LatLng(48.86, 2.35),
  'ol': LatLng(45.76, 4.84),
  'om': LatLng(43.3, 5.37),
  'rm': LatLng(40.42, -3.7),
  'barca': LatLng(41.38, 2.17),
  'atm': LatLng(40.42, -3.7),
  'city': LatLng(53.48, -2.28),
  'arsenal': LatLng(51.56, -0.13),
  'liverpool': LatLng(53.41, -2.99),
  'manu': LatLng(53.46, -2.29),
  'chelsea': LatLng(51.48, -0.19),
  'bayern': LatLng(48.14, 11.58),
  'dortmund': LatLng(51.49, 7.47),
  'inter': LatLng(45.46, 9.19),
  'milan': LatLng(45.48, 9.12),
  'juve': LatLng(45.11, 7.64),
  'napoli': LatLng(40.86, 14.27),
  // PL coords by name slug
  'manchester city': LatLng(53.48, -2.28),
  'manchester united': LatLng(53.46, -2.29),
  'tottenham': LatLng(51.60, -0.07),
  'tottenham hotspur': LatLng(51.60, -0.07),
  'west ham': LatLng(51.54, 0.02),
  'west ham united': LatLng(51.54, 0.02),
  'newcastle': LatLng(54.98, -1.62),
  'newcastle united': LatLng(54.98, -1.62),
  'aston villa': LatLng(52.51, -1.88),
  'everton': LatLng(53.44, -2.97),
  'brighton': LatLng(50.86, -0.08),
  'crystal palace': LatLng(51.40, -0.09),
  'fulham': LatLng(51.47, -0.22),
  'brentford': LatLng(51.49, -0.29),
  'bournemouth': LatLng(50.74, -1.84),
  'wolves': LatLng(52.59, -2.13),
  'wolverhampton wanderers': LatLng(52.59, -2.13),
  'nottingham forest': LatLng(52.94, -1.13),
  'leicester': LatLng(52.62, -1.14),
  'leicester city': LatLng(52.62, -1.14),
  'southampton': LatLng(50.91, -1.39),
  'leeds': LatLng(53.78, -1.57),
  'leeds united': LatLng(53.78, -1.57),
};

const continentViews = <String, (LatLng, double)>{
  'afrique': (LatLng(5, 15), 3.5),
  'europe': (LatLng(52, 5), 4.2),
  'asie': (LatLng(35, 90), 3.2),
  'am-nord': (LatLng(45, -100), 3.4),
  'am-sud': (LatLng(-15, -58), 3.6),
  'oceanie': (LatLng(-22, 140), 3.8),
};

const countryViews = <String, (LatLng, double)>{
  'tn': (LatLng(34, 9.5), 6.5),
  'dz': (LatLng(28, 3), 5.5),
  'ma': (LatLng(32, -6.5), 5.8),
  'fr': (LatLng(46.5, 2.5), 5.8),
  'es': (LatLng(40, -3.5), 5.8),
  'gb': (LatLng(53.5, -2), 6.0),
  'de': (LatLng(51, 10.5), 5.8),
  'it': (LatLng(42.5, 12.5), 5.8),
  'br': (LatLng(-14, -52), 4.2),
  'ar': (LatLng(-34, -64), 5.0),
  'us': (LatLng(39, -98), 4.0),
};

const worldView = (LatLng(12, 10), 1.6);

const continentLeagueIds = <String, int>{
  'afrique': 12,
  'europe': 2,
  'asie': 17,
  'am-nord': 16,
  'am-sud': 13,
  'oceanie': 188,
};

/// Pays → id ligue principale api-sports (comme web `LEAGUE_SPORTS_IDS` + COUNTRIES).
const countryLeagueIds = <String, int>{
  'tn': 202,
  'dz': 186,
  'ma': 200,
  'ci': 386,
  'sn': 204,
  'eg': 233,
  'ng': 287,
  'fr': 61,
  'es': 140,
  'pt': 94,
  'gb': 39,
  'de': 78,
  'it': 135,
  'nl': 88,
  'be': 144,
  'tr': 203,
  'br': 71,
  'ar': 128,
  'sa': 307,
  'ae': 301,
  'jp': 98,
  'kr': 292,
  'us': 253,
  'mx': 262,
  'ca': 253,
  'au': 188,
  'nz': 188,
};

/// leagueId string (API) → id api-sports
const leagueSportsIds = <String, int>{
  'l1-tun': 202,
  'l2-tun': 202,
  'l1-dz': 186,
  'botola': 200,
  'l1-ci': 386,
  'elite-sn': 204,
  'pl-eg': 233,
  'npfl': 287,
  'l1-fr': 61,
  'laliga': 140,
  'liga-pt': 94,
  'pl-eng': 39,
  'bundesliga': 78,
  'serie-a-it': 135,
  'eredivisie': 88,
  'pro-league-be': 144,
  'super-lig': 203,
  'serie-a-br': 71,
  'primera': 128,
  'spl': 307,
  'uae-pl': 301,
  'j-league': 98,
  'k-league': 292,
  'mls': 253,
  'liga-mx': 262,
  'a-league': 188,
};

LatLng mapNodeCoords(String id, String level, {String? parentId, String? name}) {
  if (level == 'continent') return continentCoords[id] ?? const LatLng(0, 0);
  if (level == 'country') return countryCoords[id] ?? const LatLng(0, 0);
  // team
  if (teamCoords.containsKey(id)) return teamCoords[id]!;
  final byName = name != null ? teamCoords[_normTeamKey(name)] : null;
  if (byName != null) return byName;
  if (id.contains('-')) {
    final slug = id.split('-').skip(1).join('-');
    if (teamCoords.containsKey(slug)) return teamCoords[slug]!;
    final asName = id.split('-').skip(1).join(' ');
    if (teamCoords.containsKey(asName)) return teamCoords[asName]!;
  }
  return (parentId != null ? countryCoords[parentId] : null) ?? const LatLng(0, 0);
}

(LatLng, double) resolveMapCamera({
  required int step,
  String? continentId,
  String? countryId,
}) {
  if (step == 2 && countryId != null && countryViews.containsKey(countryId)) {
    return countryViews[countryId]!;
  }
  if (step >= 1 && continentId != null && continentViews.containsKey(continentId)) {
    return continentViews[continentId]!;
  }
  return worldView;
}

String continentLogoUrl(String continentId) {
  final id = continentLeagueIds[continentId];
  if (id != null) return 'https://media.api-sports.io/football/leagues/$id.png';
  return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(continentId)}&background=FF7A00&color=fff&size=64&bold=true';
}

/// Logo du championnat (dawri) pour un pays — pas le drapeau.
String countryLeagueLogoUrl(String countryId, {String? leagueId, String? leagueName}) {
  if (leagueId != null && leagueSportsIds.containsKey(leagueId)) {
    return 'https://media.api-sports.io/football/leagues/${leagueSportsIds[leagueId]}.png';
  }
  final byCountry = countryLeagueIds[countryId.toLowerCase()];
  if (byCountry != null) {
    return 'https://media.api-sports.io/football/leagues/$byCountry.png';
  }
  final label = (leagueName ?? countryId).trim();
  final acronym = label
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0])
      .take(3)
      .join()
      .toUpperCase();
  return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(acronym.isEmpty ? countryId : acronym)}&background=FF7A00&color=fff&size=64&bold=true';
}

String flagCdnUrl(String countryId) =>
    'https://flagcdn.com/w80/${countryId.toLowerCase()}.png';

String leagueLogoUrl(String leagueId) {
  final id = leagueSportsIds[leagueId];
  if (id != null) return 'https://media.api-sports.io/football/leagues/$id.png';
  return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(leagueId)}&background=6366F1&color=fff&size=64&bold=true';
}

/// IDs catalogue courts (web `TEAM_SPORTS_IDS`).
const teamSportsIds = <String, int>{
  'est': 990, 'ca': 988, 'css': 983, 'st': 991, 'mon': 992, 'ari': 21435,
  'kab': 918, 'mc': 906, 'wyd': 968, 'raj': 976, 'asec': 1698,
  'gen': 4133, 'jaraaf': 4134, 'ahly': 1577, 'zamalek': 1040, 'pyramids': 10397,
  'enyimba': 2620, 'rivers': 2621,
  'psg': 85, 'ol': 80, 'om': 81, 'rm': 541, 'barca': 529, 'atm': 530,
  'benfica': 211, 'porto': 212,
  'city': 50, 'arsenal': 42, 'liverpool': 40, 'manu': 33, 'chelsea': 49,
  'bayern': 157, 'dortmund': 165, 'leverkusen': 168,
  'inter': 505, 'milan': 489, 'juve': 496, 'napoli': 492,
  'ajax': 194, 'psv': 197, 'feyenoord': 198, 'brugge': 569, 'anderlecht': 554,
  'flamengo': 127, 'palmeiras': 121, 'boca': 451, 'river': 435,
};

/// Noms normalisés → id api-sports (PL + top 5 + clubs majeurs).
const teamNameSportsIds = <String, int>{
  'arsenal': 42,
  'aston villa': 66,
  'bournemouth': 35,
  'brentford': 55,
  'brighton': 51,
  'brighton & hove albion': 51,
  'chelsea': 49,
  'crystal palace': 52,
  'everton': 45,
  'fulham': 36,
  'ipswich town': 57,
  'ipswich': 57,
  'leicester city': 46,
  'leicester': 46,
  'liverpool': 40,
  'manchester city': 50,
  'man city': 50,
  'manchester united': 33,
  'man united': 33,
  'man utd': 33,
  'newcastle united': 34,
  'newcastle': 34,
  'nottingham forest': 65,
  'southampton': 41,
  'tottenham': 47,
  'tottenham hotspur': 47,
  'west ham': 48,
  'west ham united': 48,
  'wolves': 39,
  'wolverhampton': 39,
  'wolverhampton wanderers': 39,
  'leeds': 63,
  'leeds united': 63,
  'burnley': 44,
  'sunderland': 746,
  'real madrid': 541,
  'barcelona': 529,
  'fc barcelona': 529,
  'atletico madrid': 530,
  'psg': 85,
  'paris saint-germain': 85,
  'paris saint germain': 85,
  'lyon': 80,
  'olympique lyonnais': 80,
  'marseille': 81,
  'olympique de marseille': 81,
  'bayern munich': 157,
  'bayern munchen': 157,
  'borussia dortmund': 165,
  'inter': 505,
  'inter milan': 505,
  'ac milan': 489,
  'milan': 489,
  'juventus': 496,
  'napoli': 492,
};

String _normTeamKey(String name) {
  const accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ñ': 'n', 'ç': 'c',
  };
  final lower = name.toLowerCase().trim();
  final buf = StringBuffer();
  for (final code in lower.runes) {
    final ch = String.fromCharCode(code);
    buf.write(accents[ch] ?? ch);
  }
  return buf.toString().replaceAll(RegExp(r'[^a-z0-9\s&-]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

int? resolveTeamSportsId(String teamId, [String? teamName]) {
  final id = teamId.trim().toLowerCase();
  if (teamSportsIds.containsKey(id)) return teamSportsIds[id];

  if (teamName != null && teamName.trim().isNotEmpty) {
    final byName = teamNameSportsIds[_normTeamKey(teamName)];
    if (byName != null) return byName;
  }

  // ids type "gb-liverpool" / "eng-manchester-united"
  if (id.contains('-')) {
    final parts = id.split('-');
    if (parts.length >= 2) {
      final slug = parts.sublist(1).join('-');
      if (teamSportsIds.containsKey(slug)) return teamSportsIds[slug];
      final asName = parts.sublist(1).join(' ');
      final bySlugName = teamNameSportsIds[_normTeamKey(asName)];
      if (bySlugName != null) return bySlugName;
      // dernier mot (liverpool, chelsea…)
      final last = parts.last;
      if (teamNameSportsIds.containsKey(last)) return teamNameSportsIds[last];
      if (teamSportsIds.containsKey(last)) return teamSportsIds[last];
    }
  }

  // id numérique api-sports
  final asInt = int.tryParse(id);
  if (asInt != null && asInt > 0) return asInt;

  return null;
}

/// Crest club : logo API direct → catalogue id/nom → api-sports.
String resolveTeamLogoUrl(String teamId, {String? teamName, String? directLogo}) {
  final direct = directLogo?.trim();
  if (direct != null && direct.isNotEmpty && direct.startsWith('http')) return direct;

  final sportsId = resolveTeamSportsId(teamId, teamName);
  if (sportsId != null) {
    return 'https://media.api-sports.io/football/teams/$sportsId.png';
  }

  final label = (teamName ?? teamId).trim();
  final short = label.length > 12 ? label.substring(0, 12) : label;
  return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(short)}&background=FF7A00&color=fff&size=128&bold=true';
}