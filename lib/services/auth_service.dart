import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_models.dart';
import 'api_client.dart';

class AuthService {
  static const _tokenKey = 'odin_token';
  static const _userKey = 'odin_user';

  AuthService(this._api);

  final ApiClient _api;

  Future<OdinUser> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {
      'email': email.trim().toLowerCase(),
      'password': password,
    }) as Map<String, dynamic>;

    final token = data['accessToken'] as String;
    final userJson = data['user'] as Map<String, dynamic>;
    final org = data['organization'] as Map<String, dynamic>?;

    final user = OdinUser.fromJson({
      ...userJson,
      if (org != null) 'organization': org,
    });

    await _persist(token, user);
    _api.setToken(token);
    return user;
  }

  Future<OdinUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userRaw = prefs.getString(_userKey);
    if (token == null || userRaw == null) return null;
    _api.setToken(token);
    return OdinUser.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _api.setToken(null);
  }

  Future<void> _persist(String token, OdinUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}
