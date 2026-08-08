import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/joueur_api.dart';

/// Notifie GoRouter uniquement quand l'état connecté change (évite reload login).
class AuthSessionNotifier extends ChangeNotifier {
  AuthSessionNotifier(AuthProvider auth) {
    _auth = auth;
    _wasAuthenticated = auth.isAuthenticated;
    auth.addListener(_onAuthChanged);
  }

  late final AuthProvider _auth;
  late bool _wasAuthenticated;

  void _onAuthChanged() {
    final now = _auth.isAuthenticated;
    if (now != _wasAuthenticated) {
      _wasAuthenticated = now;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}

class AuthProvider extends ChangeNotifier {
  AuthProvider() : _api = ApiClient() {
    _auth = AuthService(_api);
  }

  final ApiClient _api;
  late final AuthService _auth;

  OdinUser? _user;
  bool _initializing = false;
  bool _loggingIn = false;
  String? _error;

  OdinUser? get user => _user;
  bool get initializing => _initializing;
  bool get loggingIn => _loggingIn;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  ApiClient get api => _api;

  Future<void> init() async {
    if (_initializing) return;
    _initializing = true;
    notifyListeners();
    try {
      _user = await _auth.restoreSession();
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    _loggingIn = true;
    notifyListeners();
    try {
      _user = await _auth.login(email, password);
      if (!_user!.canAccessPlayerApp) {
        await logout();
        _error = 'Cette application est réservée aux comptes club (joueurs & staff).';
        return false;
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
      return false;
    } finally {
      _loggingIn = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) {
    return _auth.changePassword(currentPassword, newPassword);
  }
}

class JoueurDataProvider extends ChangeNotifier {
  JoueurDataProvider(this._api);

  final ApiClient _api;
  late final ClubApi _club = ClubApi(_api);
  late final JoueurApi _joueur = JoueurApi(_api);

  BackendPlayer? myPlayer;
  String? myPlayerId;
  List<BackendPlayer> squadPlayers = [];
  PlayerStatsPayload? playerStats;
  List<BackendMatchStat> matchStats = [];
  List<BackendAward> awards = [];
  List<BackendDocument> documents = [];
  List<BackendTransfer> transfers = [];
  List<BackendChemistry> chemistry = [];
  List<BackendCalendarEvent> calendarEvents = [];
  List<BackendInjury> injuries = [];
  OrgProfile? orgProfile;
  BackendContract? myContract;
  bool loading = false;
  String? error;

  Future<void> load(OdinUser user) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      orgProfile = await _club.getProfile().catchError((_) => const OrgProfile());
      squadPlayers = await _club.getPlayers();
      myPlayer = squadPlayers.cast<BackendPlayer?>().firstWhere(
            (p) => p!.id == user.playerId,
            orElse: () => squadPlayers.cast<BackendPlayer?>().firstWhere(
                  (p) =>
                      p!.name.trim().toLowerCase() ==
                      (user.fullName ?? '').trim().toLowerCase(),
                  orElse: () => squadPlayers.isNotEmpty ? squadPlayers.first : null,
                ),
          );
      myPlayerId = myPlayer?.id;

      if (myPlayerId != null) {
        final pid = myPlayerId!;
        final playerName = myPlayer?.name ?? user.fullName ?? '';

        final results = await Future.wait([
          _club.getPlayerStats(pid).catchError((_) => const PlayerStatsPayload()),
          _club.getMatchStats(pid).catchError((_) => <BackendMatchStat>[]),
          _club.getAwards(pid).catchError((_) => <BackendAward>[]),
          _club.getDocuments(pid).catchError((_) => <BackendDocument>[]),
          _joueur.getCalendar().catchError((_) => <dynamic>[]),
          _joueur.getInjuries().catchError((_) => <dynamic>[]),
          _club.getTransfers().catchError((_) => <BackendTransfer>[]),
          _club.getChemistry().catchError((_) => <BackendChemistry>[]),
          _club.getPlayerContract(pid).catchError((_) => const BackendContract(id: '')),
        ]);

        playerStats = results[0] as PlayerStatsPayload;
        matchStats = results[1] as List<BackendMatchStat>;
        awards = results[2] as List<BackendAward>;
        documents = results[3] as List<BackendDocument>;
        calendarEvents = _filterCalendar(
          (results[4] as List<dynamic>)
              .map((e) => BackendCalendarEvent.fromJson(e as Map<String, dynamic>))
              .toList(),
          [playerName, user.fullName ?? ''],
        );
        injuries = (results[5] as List<dynamic>)
            .map((e) => BackendInjury.fromJson(e as Map<String, dynamic>))
            .toList();
        transfers = results[6] as List<BackendTransfer>;
        chemistry = results[7] as List<BackendChemistry>;
        myContract = results[8] as BackendContract;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<BackendCalendarEvent> _filterCalendar(
    List<BackendCalendarEvent> events,
    List<String> playerNames,
  ) {
    final names = playerNames
        .map((n) => n.trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();
    return events.where((ev) {
      final type = ev.eventType.toUpperCase();
      if (type != 'MEDICAL') return true;
      if (names.isEmpty) return false;
      final title = ev.title.toLowerCase();
      return names.any(title.contains);
    }).toList();
  }

  Future<void> refreshPlayerStats() async {
    if (myPlayerId == null) return;
    final pid = myPlayerId!;
    final results = await Future.wait([
      _club.getPlayerStats(pid).catchError((_) => const PlayerStatsPayload()),
      _club.getMatchStats(pid).catchError((_) => <BackendMatchStat>[]),
    ]);
    playerStats = results[0] as PlayerStatsPayload;
    matchStats = results[1] as List<BackendMatchStat>;
    notifyListeners();
  }

  Future<void> refetchDocuments() async {
    if (myPlayerId == null) return;
    documents = await _club.getDocuments(myPlayerId!);
    notifyListeners();
  }

  Future<void> refetchMedical() async {
    if (myPlayerId == null) return;
    final cal = await _joueur.getCalendar();
    final inj = await _joueur.getInjuries();
    calendarEvents = _filterCalendar(
      cal.map((e) => BackendCalendarEvent.fromJson(e as Map<String, dynamic>)).toList(),
      [myPlayer?.name ?? ''],
    );
    injuries = inj
        .map((e) => BackendInjury.fromJson(e as Map<String, dynamic>))
        .toList();
    playerStats = await _club.getPlayerStats(myPlayerId!);
    notifyListeners();
  }
}

class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _load();
  }

  static const _key = 'odin_locale';

  String _locale = 'fr';
  bool _ready = false;

  String get locale => _locale;
  bool get ready => _ready;
  Locale get flutterLocale => Locale(_locale);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == 'en' || raw == 'ar' || raw == 'fr') {
        _locale = raw!;
      }
    } catch (_) {}
    _ready = true;
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    if (_locale == locale) return;
    if (locale != 'fr' && locale != 'en' && locale != 'ar') return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale);
    } catch (_) {}
  }
}
