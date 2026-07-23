import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? token}) : _client = client ?? http.Client() {
    _token = token;
  }

  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> _headers({bool json = true, Map<String, String>? extra}) {
    return {
      if (json) 'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
      ...?extra,
    };
  }

  Future<dynamic> get(String path) async {
    final res = await _client.get(
      Uri.parse('$kApiBaseUrl$path'),
      headers: _headers(),
    );
    return _parse(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await _client.post(
      Uri.parse('$kApiBaseUrl$path'),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parse(res);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final res = await _client.patch(
      Uri.parse('$kApiBaseUrl$path'),
      headers: _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _parse(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _client.delete(
      Uri.parse('$kApiBaseUrl$path'),
      headers: _headers(),
    );
    return _parse(res);
  }

  Future<dynamic> getWithTimeout(String path, {int timeoutMs = 25000}) async {
    final res = await _client
        .get(
          Uri.parse('$kApiBaseUrl$path'),
          headers: _headers(),
        )
        .timeout(Duration(milliseconds: timeoutMs));
    return _parse(res);
  }

  dynamic _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(res.body);
    }
    String message = 'Erreur serveur (${res.statusCode})';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      if (m is List && m.isNotEmpty) {
        message = m.first.toString();
      } else if (m is String) {
        message = m;
      } else if (data['error'] != null) {
        message = data['error'].toString();
      }
    } catch (_) {}
    throw ApiException(message, res.statusCode);
  }
}
