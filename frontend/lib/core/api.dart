import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiClient {
  // En Docker: Uri.base.origin (nginx mismo origen)
  // En dev local: API_BASE = http://localhost:8080  (--dart-define)
  static const String _apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: '',
  );

  String get _base => _apiBase.isNotEmpty ? _apiBase : Uri.base.origin;

  final Map<String, String> _headers = {'X-API-Key': apiKey};

  Future<dynamic> getJson(String path) async {
    final res = await http.get(
      Uri.parse('$_base$path'),
      headers: _headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$path -> ${res.statusCode}');
    }
    return jsonDecode(res.body);
  }

  Future<dynamic> postJson(String path) async {
    final res = await http.post(
      Uri.parse('$_base$path'),
      headers: _headers,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$path -> ${res.statusCode}');
    }
    return jsonDecode(res.body);
  }
}
