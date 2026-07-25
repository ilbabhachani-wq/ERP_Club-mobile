import 'package:flutter/material.dart';
import '../data/world_clubs.dart';
import '../theme/odin_colors.dart';

export '../data/world_clubs.dart' show kSelectableClubs, clubLogoTeamIds, kWorldClubs, WorldClub;

/// Résout l’URL du crest (logo org → CDN api-sports par nom de club).
String? resolveClubLogoUrl(String? logoUrl, String clubName) {
  final direct = logoUrl?.trim();
  if (direct != null && direct.isNotEmpty) return direct;

  final key = _norm(clubName);
  if (key.isEmpty) return null;

  for (final c in kWorldClubs) {
    if (_norm(c.name) == key) {
      return 'https://media.api-sports.io/football/teams/${c.sportsId}.png';
    }
  }

  final id = clubLogoTeamIds[key] ?? clubLogoTeamIds[_aliases[key] ?? ''];
  if (id == null) return null;
  return 'https://media.api-sports.io/football/teams/$id.png';
}

String _norm(String name) {
  const accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ñ': 'n', 'ç': 'c', 'ş': 's', 'ğ': 'g',
  };
  final lower = name.toLowerCase().trim();
  final buf = StringBuffer();
  for (final code in lower.runes) {
    final ch = String.fromCharCode(code);
    buf.write(accents[ch] ?? ch);
  }
  return buf
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9\s&-]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class ClubLogo extends StatelessWidget {
  const ClubLogo({
    super.key,
    required this.clubName,
    this.logoUrl,
    this.size = 28,
    this.radius = 8,
    this.backgroundColor,
    this.padding = 4,
  });

  final String clubName;
  final String? logoUrl;
  final double size;
  final double radius;
  final Color? backgroundColor;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final url = resolveClubLogoUrl(logoUrl, clubName);
    final initials = _initials(clubName);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w800,
                  color: OdinColors.accent,
                ),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w800,
                    color: OdinColors.accent,
                  ),
                ),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: size * 0.35,
                    height: size * 0.35,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: OdinColors.accent.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return w.substring(0, w.length.clamp(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.elementAt(1)[0]}'.toUpperCase();
  }
}

const _aliases = {
  'man u': 'manchester united',
  'man utd': 'manchester united',
  'man united': 'manchester united',
  'mufc': 'manchester united',
  'man city': 'manchester city',
  'spurs': 'tottenham',
  'ca': 'club africain',
  'css': 'cs sfaxien',
  'est': 'esperance de tunis',
  'ess': 'etoile du sahel',
  'st': 'stade tunisien',
  'ob': 'olympique beja',
};
