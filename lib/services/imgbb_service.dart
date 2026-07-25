import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Upload d’images vers ImgBB (https://api.imgbb.com/).
class ImgbbService {
  static const _prefsKey = 'imgbb_api_key';
  static const _endpoint = 'https://api.imgbb.com/1/upload';

  /// Clé: dart-define → sinon SharedPreferences (saisie in-app).
  static Future<String?> resolveApiKey() async {
    if (kImgbbApiKey.trim().isNotEmpty) return kImgbbApiKey.trim();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey)?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return null;
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key.trim());
  }

  /// Upload bytes → URL publique ImgBB (`display_url`).
  static Future<String> uploadBytes(List<int> bytes, {String? name}) async {
    final key = await resolveApiKey();
    if (key == null || key.isEmpty) {
      throw ImgbbException(
        'Clé ImgBB manquante. Ajoutez-la via dart-define ou dans l’app.',
        needsApiKey: true,
      );
    }

    final res = await http.post(
      Uri.parse(_endpoint),
      body: {
        'key': key,
        'image': base64Encode(bytes),
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );

    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ImgbbException('Réponse ImgBB invalide (${res.statusCode})');
    }

    if (res.statusCode >= 400 || json['success'] != true) {
      final err = json['error'];
      final msg = err is Map
          ? (err['message']?.toString() ?? 'Upload échoué')
          : (json['status_txt']?.toString() ?? 'Upload échoué (${res.statusCode})');
      throw ImgbbException(msg, needsApiKey: res.statusCode == 400);
    }

    final data = json['data'] as Map<String, dynamic>?;
    final url = data?['display_url']?.toString() ?? data?['url']?.toString();
    if (url == null || url.isEmpty) {
      throw ImgbbException('URL image manquante dans la réponse ImgBB');
    }
    return url;
  }
}

class ImgbbException implements Exception {
  ImgbbException(this.message, {this.needsApiKey = false});
  final String message;
  final bool needsApiKey;

  @override
  String toString() => message;
}
