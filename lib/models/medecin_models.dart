class MedecinPlayer {
  MedecinPlayer({
    required this.id,
    required this.fullName,
    required this.position,
    required this.status,
  });

  factory MedecinPlayer.fromJson(
    Map<String, dynamic> j
  ) => MedecinPlayer(
    id: j['id'] as String? ?? '',
    fullName: j['fullName'] as String?
      ?? j['name'] as String? ?? '—',
    position: j['position'] as String? ?? '—',
    status: j['availability'] as String?
      ?? j['status'] as String? ?? '—',
  );

  final String id;
  final String fullName;
  final String position;
  final String status;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'
        .toUpperCase();
    }
    return fullName.isNotEmpty
      ? fullName[0].toUpperCase() : '?';
  }
}

class MedecinInjury {
  MedecinInjury({
    required this.id,
    required this.name,
    required this.injury,
    required this.bodyPart,
    required this.returnDate,
    required this.riskIA,
  });

  factory MedecinInjury.fromJson(
    Map<String, dynamic> j
  ) => MedecinInjury(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '—',
    injury: j['injury'] as String?
      ?? j['injuryType'] as String? ?? '—',
    bodyPart: j['bodyPart'] as String? ?? '—',
    returnDate: j['returnDate'] as String? ?? '—',
    riskIA: (j['riskIA'] as num?)?.toDouble() ?? 0,
  );

  final String id;
  final String name;
  final String injury;
  final String bodyPart;
  final String returnDate;
  final double riskIA;

  int get riskPercent => (riskIA * 10).round();

  int? get daysRemaining {
    if (returnDate == '—' || returnDate.isEmpty) {
      return null;
    }
    try {
      final parts = returnDate.split('/');
      DateTime date;
      if (parts.length == 3) {
        date = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      } else {
        date = DateTime.parse(returnDate);
      }
      return date.difference(DateTime.now()).inDays;
    } catch (_) {
      return null;
    }
  }

  String get statusLabel {
    final days = daysRemaining;
    if (days == null) return 'Active';
    if (days < 0) return 'En rééducation';
    return 'Active';
  }
}

class MedecinEvent {
  MedecinEvent({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    required this.eventType,
  });

  factory MedecinEvent.fromJson(
    Map<String, dynamic> j
  ) => MedecinEvent(
    id: j['id'] as String? ?? '',
    title: j['title'] as String?
      ?? j['name'] as String? ?? '—',
    eventDate: j['eventDate'] as String?
      ?? j['date'] as String? ?? '—',
    eventTime: j['eventTime'] as String?
      ?? j['time'] as String? ?? '',
    location: j['location'] as String? ?? '',
    eventType: j['eventType'] as String?
      ?? j['type'] as String? ?? '',
  );

  final String id;
  final String title;
  final String eventDate;
  final String eventTime;
  final String location;
  final String eventType;
}
