class CoachPlayer {
  CoachPlayer({
    required this.id,
    required this.fullName,
    required this.position,
    required this.status,
    this.number = 0,
    this.forme = 75,
    this.fatigue = 30,
  });

  factory CoachPlayer.fromJson(Map<String, dynamic> j) {
    final stats = j['stats'];
    final formFromStats = stats is Map ? (stats['form'] as num?)?.toInt() : null;
    return CoachPlayer(
      id: j['id'] as String? ?? '',
      fullName: j['fullName'] as String? ?? j['name'] as String? ?? '—',
      position: (j['position'] as String? ?? j['positionFull'] as String? ?? '—')
          .toUpperCase(),
      status: j['availability'] as String? ?? j['status'] as String? ?? '—',
      number: (j['jerseyNumber'] as num?)?.toInt() ??
          (j['number'] as num?)?.toInt() ??
          0,
      forme: formFromStats ?? 75,
      fatigue: 30,
    );
  }

  final String id;
  final String fullName;
  final String position;
  final String status;
  final int number;
  int forme;
  int fatigue;

  String get shortName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}. ${parts.last}';
    return fullName.length > 10 ? '${fullName.substring(0, 9)}…' : fullName;
  }

  /// Aligné web: Disponibles + Surveillance (LIMITE)
  bool get canPlay {
    final s = _norm(status);
    return s.contains('DISPONIBLE') ||
        s.contains('SURVEILLANCE') ||
        s.contains('LIMITE') ||
        s == 'AVAILABLE';
  }

  bool get isInjured {
    final s = _norm(status);
    return s.contains('BLESS') || s == 'INJURED';
  }

  bool get isSuspended {
    final s = _norm(status);
    return s.contains('SUSPEND') || s.contains('FIN_CONTRAT');
  }

  bool get isUnavailable => isInjured || isSuspended;

  bool get isAvailable {
    final s = _norm(status);
    return s.contains('DISPONIBLE') || s == 'AVAILABLE';
  }

  bool get isLimite {
    final s = _norm(status);
    return s.contains('LIMITE') || s.contains('SURVEILLANCE');
  }

  String get lineupStatusLabel {
    if (isInjured) return 'Blessé';
    if (isSuspended) return 'Suspendu';
    if (isLimite) return 'Surveillance';
    if (isAvailable) return 'Disponible';
    return status;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  static String _norm(String s) => s
      .toUpperCase()
      .replaceAll('É', 'E')
      .replaceAll('È', 'E')
      .replaceAll('Ê', 'E');
}

class CoachSession {
  CoachSession({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    required this.eventType,
    this.notes,
  });

  factory CoachSession.fromJson(Map<String, dynamic> j) => CoachSession(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? j['name'] as String? ?? 'Séance',
        eventDate: j['eventDate'] as String? ?? j['date'] as String? ?? '',
        eventTime: j['eventTime'] as String? ?? j['time'] as String? ?? '',
        location: j['location'] as String? ?? '',
        eventType: j['eventType'] as String? ?? j['type'] as String? ?? '',
        notes: j['notes'] as String? ?? j['description'] as String?,
      );

  final String id;
  final String title;
  final String eventDate;
  final String eventTime;
  final String location;
  final String eventType;
  final String? notes;

  String get dateKey {
    if (eventDate.length >= 10) return eventDate.substring(0, 10);
    return eventDate;
  }

  bool get isTraining {
    final t = eventType.toUpperCase();
    return t.contains('ENTR') || t.contains('TRAIN');
  }

  bool get isMatch {
    final t = eventType.toUpperCase();
    return t.contains('MATCH');
  }
}

class CoachMatch {
  CoachMatch({
    required this.id,
    required this.opponent,
    required this.competition,
    required this.matchDate,
    required this.matchDateISO,
    required this.homeAwayLabel,
    this.score,
    this.resultLabel,
  });

  factory CoachMatch.fromJson(Map<String, dynamic> j) => CoachMatch(
        id: j['id'] as String? ?? '',
        opponent: j['opponent'] as String? ?? 'Adversaire',
        competition: j['competition'] as String? ?? '',
        matchDate: j['matchDate'] as String? ?? '',
        matchDateISO:
            j['matchDateISO'] as String? ?? j['matchDate'] as String? ?? '',
        homeAwayLabel:
            j['homeAwayLabel'] as String? ?? j['homeAway'] as String? ?? '',
        score: j['score'] as String?,
        resultLabel: j['resultLabel'] as String?,
      );

  final String id;
  final String opponent;
  final String competition;
  final String matchDate;
  final String matchDateISO;
  final String homeAwayLabel;
  final String? score;
  final String? resultLabel;

  int? get daysUntil {
    final d = DateTime.tryParse(matchDateISO);
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day)
        .difference(DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ))
        .inDays;
  }
}

class CoachContact {
  CoachContact({
    required this.memberId,
    required this.name,
    required this.role,
    this.preview = '',
    this.time = '',
    this.unread = 0,
  });

  factory CoachContact.fromJson(Map<String, dynamic> j) => CoachContact(
        memberId: j['memberId'] as String? ?? j['id'] as String? ?? '',
        name: j['name'] as String? ?? j['fullName'] as String? ?? 'Contact',
        role: j['role'] as String? ?? '',
        preview: j['preview'] as String? ?? j['lastMessage'] as String? ?? '',
        time: j['time'] as String? ?? '',
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );

  final String memberId;
  final String name;
  final String role;
  final String preview;
  final String time;
  final int unread;
}

class CoachChatMessage {
  CoachChatMessage({
    required this.id,
    required this.text,
    required this.sent,
    required this.time,
  });

  factory CoachChatMessage.fromJson(Map<String, dynamic> j) => CoachChatMessage(
        id: j['id'] as String? ?? '',
        text: j['text'] as String? ?? j['body'] as String? ?? '',
        sent: j['sent'] as bool? ?? false,
        time: j['time'] as String? ?? '',
      );

  final String id;
  final String text;
  final bool sent;
  final String time;
}

/// Compatibilité de postes (comme POSITION_GROUPS web)
const kPositionGroups = <String, List<String>>{
  'GK': ['GK', 'G', 'GARDIEN'],
  'DC': ['DC', 'CB', 'DEF', 'CENTRAL'],
  'LB': ['LB', 'AG', 'LATERAL', 'G'],
  'RB': ['RB', 'AD', 'LATERAL', 'D'],
  'MDF': ['MDF', 'CDM', 'MC', 'MILIEU'],
  'MC': ['MC', 'CM', 'MDF', 'MOC', 'MILIEU'],
  'MOC': ['MOC', 'CAM', 'MC', 'MILIEU'],
  'AG': ['AG', 'LW', 'AI', 'ATT'],
  'AD': ['AD', 'RW', 'AD', 'ATT'],
  'BU': ['BU', 'ST', 'CF', 'ATT', 'ATTAQUANT'],
  'ST': ['ST', 'BU', 'CF', 'ATT'],
};
