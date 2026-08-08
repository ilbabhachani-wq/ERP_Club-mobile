import 'api_client.dart';

class ValidationRequest {
  ValidationRequest({
    required this.id,
    required this.type,
    required this.title,
    required this.from,
    required this.detail,
    required this.priority,
    required this.status,
    required this.date,
    this.amount,
  });

  final String id;
  final String type;
  final String title;
  final String from;
  final String detail;
  final String priority;
  final String status;
  final String date;
  final String? amount;

  factory ValidationRequest.fromJson(Map<String, dynamic> j) => ValidationRequest(
        id: '${j['id'] ?? ''}',
        type: '${j['type'] ?? ''}',
        title: '${j['title'] ?? ''}',
        from: '${j['from'] ?? ''}',
        detail: '${j['detail'] ?? ''}',
        priority: '${j['priority'] ?? 'Normale'}',
        status: '${j['status'] ?? 'En attente'}',
        date: '${j['date'] ?? ''}',
        amount: j['amount']?.toString(),
      );
}

class ClubNotificationItem {
  ClubNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.date,
    required this.read,
    this.path,
    this.level,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String date;
  final bool read;
  final String? path;
  final String? level;

  factory ClubNotificationItem.fromJson(Map<String, dynamic> j) => ClubNotificationItem(
        id: '${j['id'] ?? ''}',
        title: '${j['title'] ?? ''}',
        body: '${j['body'] ?? j['description'] ?? ''}',
        type: '${j['type'] ?? 'Info'}',
        date: '${j['date'] ?? j['createdAt'] ?? ''}',
        read: j['read'] == true || j['isRead'] == true,
        path: j['path']?.toString(),
        level: j['level']?.toString(),
      );
}

class TeamCard {
  TeamCard({
    required this.category,
    required this.name,
    required this.playerCount,
    required this.coach,
    required this.ranking,
    required this.calendar,
    required this.staff,
  });

  final String category;
  final String name;
  final int playerCount;
  final String coach;
  final String ranking;
  final String calendar;
  final String staff;
}

class ResponsableDashboardData {
  ResponsableDashboardData({
    required this.execKpis,
    required this.secondaryKpis,
    required this.validationQueue,
    required this.notifications,
    this.clubName = 'Club',
  });

  final List<Map<String, String>> execKpis;
  final List<Map<String, String>> secondaryKpis;
  final List<ValidationRequest> validationQueue;
  final List<ClubNotificationItem> notifications;
  final String clubName;
}

class ResponsableApi {
  ResponsableApi(this._api);
  final ApiClient _api;

  Future<List<ValidationRequest>> getValidation() async {
    final raw = await _api.get('/responsable/validation');
    List list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map && raw['requests'] is List) {
      list = raw['requests'] as List;
    } else if (raw is Map && raw['items'] is List) {
      list = raw['items'] as List;
    } else {
      list = const [];
    }
    return list
        .whereType<Map>()
        .map((e) => ValidationRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> decideValidation(String id, String action, {String? comment}) async {
    await _api.patch(
      '/responsable/validation/$id/decide',
      body: {
        'action': action,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }

  Future<List<ClubNotificationItem>> getNotifications() async {
    final raw = await _api.get('/club/notifications');
    final list = raw is List
        ? raw
        : (raw is Map && raw['items'] is List)
            ? raw['items'] as List
            : const [];
    return list
        .whereType<Map>()
        .map((e) => ClubNotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> markNotificationsRead([List<String>? ids]) async {
    await _api.patch('/club/notifications/read', body: {'ids': ids});
  }

  Future<void> clearReadNotifications() async {
    await _api.delete('/club/notifications/read');
  }

  Future<Map<String, dynamic>?> getOrgDashboard(String orgId) async {
    try {
      final raw = await _api.get('/organizations/$orgId/dashboard');
      return raw is Map ? Map<String, dynamic>.from(raw) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPlayers() async {
    final raw = await _api.get('/club/players');
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getStaff() async {
    final raw = await _api.get('/club/staff');
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getCalendar() async {
    final raw = await _api.get('/club/calendar');
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (raw is Map && raw['events'] is List) {
      return (raw['events'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final raw = await _api.get('/club/profile');
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  Future<List<TeamCard>> getTeams() async {
    final results = await Future.wait([
      getPlayers(),
      getStaff(),
      getCalendar(),
      getProfile(),
    ]);
    final players = results[0] as List<Map<String, dynamic>>;
    final staff = results[1] as List<Map<String, dynamic>>;
    final events = results[2] as List<Map<String, dynamic>>;
    final profile = results[3] as Map<String, dynamic>?;
    final clubName = '${profile?['clubName'] ?? 'Club'}';

    String ageCategory(int age) {
      if (age >= 21) return 'Seniors';
      if (age >= 18) return 'U21';
      if (age >= 15) return 'U18';
      return 'U15';
    }

    final now = DateTime.now();
    const cats = ['Seniors', 'U21', 'U18', 'U15'];
    return cats.map((cat) {
      final catPlayers = players.where((p) {
        final age = (p['age'] as num?)?.toInt() ?? 0;
        return ageCategory(age) == cat;
      }).toList();

      final coaches = staff.where((s) {
        final role = '${s['role'] ?? ''}'.toLowerCase();
        return role.contains('coach') || role.contains('entraineur') || role.contains('entraîneur');
      }).toList();

      String coach = '—';
      if (coaches.isNotEmpty) {
        final byDept = coaches.where((c) {
          return '${c['department'] ?? ''}'.toLowerCase().contains(cat.toLowerCase());
        });
        coach = '${(byDept.isNotEmpty ? byDept.first : coaches.first)['fullName'] ?? '—'}';
      }

      final matchCount = events.where((e) {
        final type = '${e['eventType'] ?? e['type'] ?? ''}'.toUpperCase();
        if (!type.contains('MATCH')) return false;
        final dateRaw = '${e['eventDate'] ?? e['date'] ?? ''}';
        final d = DateTime.tryParse(dateRaw);
        if (d == null) return false;
        return d.month == now.month && d.year == now.year;
      }).length;

      final analysts = staff.where((s) {
        final role = '${s['role'] ?? ''}'.toLowerCase();
        return role.contains('analyste') ||
            role.contains('scout') ||
            role.contains('préparateur') ||
            role.contains('preparateur') ||
            role.contains('assistant');
      }).toList();

      final count = catPlayers.length;
      return TeamCard(
        category: cat,
        name: '$clubName ${cat == 'Seniors' ? '— Équipe A' : cat}',
        playerCount: count,
        coach: coach,
        ranking: count > 0 ? '${(5 - (count ~/ 6)).clamp(1, 4)}ème' : '—',
        calendar: '$matchCount match${matchCount != 1 ? 's' : ''} ce mois',
        staff: analysts.isNotEmpty
            ? analysts.take(2).map((s) => '${s['role'] ?? ''}').join(' / ')
            : '—',
      );
    }).toList();
  }

  Future<ResponsableDashboardData> getDashboard(String? orgId) async {
    final playersFuture = getPlayers();
    final validationFuture = getValidation();
    final notifsFuture = getNotifications();
    final orgFuture = orgId != null && orgId.isNotEmpty ? getOrgDashboard(orgId) : Future.value(null);
    final profileFuture = getProfile();

    final players = await playersFuture;
    final validation = await validationFuture;
    final notifs = await notifsFuture;
    final org = await orgFuture;
    final profile = await profileFuture;

    double parseMarket(String v) {
      final s = v.replaceAll(RegExp(r'\s'), '').toUpperCase();
      final m = RegExp(r'([\d.,]+)\s*(M|K)?').firstMatch(s);
      if (m == null) return 0;
      var n = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
      if (m.group(2) == 'M') n *= 1e6;
      if (m.group(2) == 'K') n *= 1e3;
      return n;
    }

    final totalValue = players.fold<double>(
      0,
      (sum, p) => sum + parseMarket('${p['marketValue'] ?? ''}'),
    );
    final available = players.where((p) {
      final a = '${p['availability'] ?? p['status'] ?? ''}'.toLowerCase();
      return a.contains('dispo') || a.contains('available') || a == 'actif' || a == 'active';
    }).length;
    final pending = validation.where((v) => v.status == 'En attente').length;

    String fmtValue(double total) {
      if (total >= 1e6) return '${(total / 1e6).toStringAsFixed(1)} M DT';
      if (total >= 1e3) return '${(total / 1e3).round()} K DT';
      return '${total.round()} DT';
    }

    final clubName = '${profile?['clubName'] ?? org?['clubName'] ?? 'Club'}';

    return ResponsableDashboardData(
      clubName: clubName,
      execKpis: [
        {
          'label': 'Effectif',
          'value': '${players.length}',
          'trend': '$available dispo',
          'tone': 'info',
        },
        {
          'label': 'Valeur',
          'value': fmtValue(totalValue),
          'trend': 'Marché',
          'tone': 'success',
        },
        {
          'label': 'Validations',
          'value': '$pending',
          'trend': 'En attente',
          'tone': pending > 0 ? 'warning' : 'success',
        },
        {
          'label': 'Alertes',
          'value': '${notifs.where((n) => !n.read).length}',
          'trend': 'Non lues',
          'tone': 'danger',
        },
      ],
      secondaryKpis: [
        {
          'label': 'Seniors',
          'value': '${players.where((p) => ((p['age'] as num?)?.toInt() ?? 0) >= 21).length}',
          'note': 'Joueurs',
        },
        {
          'label': 'Jeunes',
          'value': '${players.where((p) => ((p['age'] as num?)?.toInt() ?? 0) < 21).length}',
          'note': 'U21 / U18 / U15',
        },
        {
          'label': 'OVR moyen',
          'value': players.isEmpty
              ? '—'
              : (players.fold<int>(0, (s, p) => s + ((p['ovr'] as num?)?.toInt() ?? 0)) /
                      players.length)
                  .round()
                  .toString(),
          'note': 'Équipe',
        },
      ],
      validationQueue: validation.where((v) => v.status == 'En attente').take(6).toList(),
      notifications: notifs.take(6).toList(),
    );
  }
}
