import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiClient {
  String get _base => Uri.base.origin;

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
