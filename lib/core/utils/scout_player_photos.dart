import 'dart:convert';
import 'package:http/http.dart' as http;

/// Catalogue cutouts TheSportsDB (aligné web `ScoutPlayerPhoto.tsx`).
const _starPhotos = <String, String>{
  'kylian mbappe': 'https://media.api-sports.io/football/players/278.png',
  'erling haaland': 'https://media.api-sports.io/football/players/1100.png',
  'jude bellingham': 'https://media.api-sports.io/football/players/284222.png',
  'vinicius junior': 'https://media.api-sports.io/football/players/762.png',
  'vinicius jr': 'https://media.api-sports.io/football/players/762.png',
  'lamine yamal': 'https://media.api-sports.io/football/players/386826.png',
  'robert lewandowski': 'https://media.api-sports.io/football/players/521.png',
  'harry kane': 'https://media.api-sports.io/football/players/184.png',
  'mohamed salah': 'https://media.api-sports.io/football/players/306.png',
  'kevin de bruyne': 'https://media.api-sports.io/football/players/629.png',
  'rodri': 'https://media.api-sports.io/football/players/2493.png',
  'bukayo saka': 'https://media.api-sports.io/football/players/1460.png',
  'phil foden': 'https://media.api-sports.io/football/players/18494.png',
  'pedri': 'https://media.api-sports.io/football/players/538.png',
  'gavi': 'https://media.api-sports.io/football/players/276.png',
  'florian wirtz': 'https://media.api-sports.io/football/players/26296.png',
  'bruno fernandes': 'https://media.api-sports.io/football/players/1485.png',
  'marcus rashford': 'https://media.api-sports.io/football/players/909.png',
  'leny yoro': 'https://media.api-sports.io/football/players/342863.png',
  'ayden heaven': 'https://media.api-sports.io/football/players/456298.png',
};

/// IDs api-sports pour fallback photo (si cutout / URL principale échoue).
const _apiSportsPlayerIds = <String, int>{
  'bukayo saka': 1460,
  'lamine yamal': 386826,
  'ayden heaven': 456298,
  'kylian mbappe': 278,
  'erling haaland': 1100,
  'jude bellingham': 284222,
  'bruno fernandes': 1485,
  'marcus rashford': 909,
  'leny yoro': 342863,
  'phil foden': 18494,
};

String? apiSportsPhotoUrl(String name) {
  final key = normalizePhotoKey(name);
  final id = _apiSportsPlayerIds[key];
  if (id == null) return null;
  return 'https://media.api-sports.io/football/players/$id.png';
}

final _photoCache = <String, String?>{};
final _inflight = <String, Future<String?>>{};

String normalizePhotoKey(String name) {
  const accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y', 'ñ': 'n', 'ç': 'c',
  };
  final lower = name.toLowerCase().trim();
  final buf = StringBuffer();
  for (final code in lower.runes) {
    final ch = String.fromCharCode(code);
    buf.write(accents[ch] ?? ch);
  }
  return buf.toString();
}

String? lookupLocalPhoto(String name) {
  final key = normalizePhotoKey(name);
  if (_starPhotos.containsKey(key)) return _starPhotos[key];
  final api = apiSportsPhotoUrl(name);
  if (api != null) return api;
  final parts = key.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final last = parts.last;
    for (final entry in _starPhotos.entries) {
      final catalogParts = entry.key.split(' ');
      final catalogLast = catalogParts.last;
      if (catalogLast == last || entry.key.endsWith(' $last')) {
        if (catalogParts.first.isNotEmpty &&
            parts.first.isNotEmpty &&
            catalogParts.first[0] == parts.first[0]) {
          return entry.value;
        }
      }
    }
  }
  return null;
}

String? resolveScoutPhotoUrl(
  String name, {
  String? direct,
  List<({String name, String? photoUrl})>? catalog,
}) {
  final d = direct?.trim();
  if (d != null && d.isNotEmpty) return d;
  if (catalog != null) {
    for (final p in catalog) {
      if (p.name.toLowerCase() == name.toLowerCase() &&
          p.photoUrl != null &&
          p.photoUrl!.isNotEmpty) {
        return p.photoUrl;
      }
    }
  }
  return lookupLocalPhoto(name);
}

Future<String?> fetchScoutPlayerPhoto(String name) async {
  final key = normalizePhotoKey(name);
  if (_photoCache.containsKey(key)) return _photoCache[key];

  final local = lookupLocalPhoto(name);
  if (local != null) {
    _photoCache[key] = local;
    return local;
  }

  final pending = _inflight[key];
  if (pending != null) return pending;

  final task = () async {
    try {
      final uri = Uri.parse(
        'https://www.thesportsdb.com/api/v1/json/3/searchplayers.php?p=${Uri.encodeComponent(name)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final players = json['player'] as List<dynamic>?;
      if (players == null || players.isEmpty) return null;
      final player = players.first as Map<String, dynamic>;
      final url = (player['strCutout'] ?? player['strRender'] ?? player['strThumb'])
          ?.toString();
      return (url != null && url.isNotEmpty) ? url : null;
    } catch (_) {
      return null;
    }
  }();

  _inflight[key] = task;
  try {
    final url = await task;
    _photoCache[key] = url;
    return url;
  } finally {
    _inflight.remove(key);
  }
}
