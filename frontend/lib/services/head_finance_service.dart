import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../storage/token_storage.dart';

class HeadFinanceService {
  final TokenStorage _tokens = TokenStorage();
  final String role; // department-head or organization-head
  HeadFinanceService({required this.role}) {
    if (role != 'department-head' && role != 'organization-head') {
      throw ArgumentError.value(role, 'role');
    }
  }

  Future<List<Map<String, dynamic>>> _getList(String resource) async {
    final token = await _tokens.getToken();
    if (token == null || token.isEmpty) throw Exception('Authentication token not found. Please sign in again.');
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/$role/finance/$resource'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Unable to load $resource (${response.statusCode}): ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw Exception('Invalid $resource response. Expected a JSON list.');
    return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getPayments() => _getList('payments');
  Future<List<Map<String, dynamic>>> getRefunds() => _getList('refunds');
}
