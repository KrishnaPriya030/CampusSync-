import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class CertificateTemplateService {
  static const String _path = '/api/organizer/certificate-templates';

  Future<String> _token() async {
    final token = await TokenStorage().getToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    return token;
  }

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      };

  Future<List<Map<String, dynamic>>> getTemplates() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$_path'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Could not load certificate templates (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw Exception('Invalid certificate template response.');
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> saveTemplate(
    Map<String, dynamic> template, {
    int? id,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_path${id == null ? '' : '/$id'}');
    final response = id == null
        ? await http.post(uri, headers: await _headers(), body: jsonEncode(template))
        : await http.put(uri, headers: await _headers(), body: jsonEncode(template));
    final expected = id == null ? 201 : 200;
    if (response.statusCode != expected) {
      throw Exception('Could not save certificate template (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw Exception('Invalid saved template response.');
    return Map<String, dynamic>.from(decoded);
  }
}
