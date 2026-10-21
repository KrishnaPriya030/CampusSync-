import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class AdminEventService {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please sign in again.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/events'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load events (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw Exception('Invalid admin events response. Expected a JSON list.');
    return decoded.map((item) {
      if (item is! Map) throw Exception('Invalid event item in admin events response.');
      return Map<String, dynamic>.from(item);
    }).toList();
  }
}
