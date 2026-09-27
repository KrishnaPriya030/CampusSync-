import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/organizer.dart';
import '../models/bulk_student_import_response.dart';

class AdminOrganizerService {
  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Organizer>> getAllOrganizers(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/organizers'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load organizers: ${response.statusCode}\n${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid organizers response');
    }

    return decoded
        .map((item) => Organizer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Organizer> getOrganizerById(int id, String token) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/organizers/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load organizer: ${response.statusCode}\n${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid organizer response');
    }

    return Organizer.fromJson(decoded);
  }

  Future<BulkStudentImportResponse> importOrganizers(
    List<int> fileBytes,
    String fileName,
    String token,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/admin/organizers/import'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Failed to import organizers: ${response.statusCode}\n${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid organizer import response');
    }

    return BulkStudentImportResponse.fromJson(decoded);
  }

  Future<Organizer> blockOrganizer(int id, String token) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/organizers/$id/block'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to block organizer: ${response.statusCode}\n${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid block response');
    }

    return Organizer.fromJson(decoded);
  }

  Future<Organizer> activateOrganizer(int id, String token) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/organizers/$id/activate'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to activate organizer: ${response.statusCode}\n${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid activate response');
    }

    return Organizer.fromJson(decoded);
  }

  Future<void> resetOrganizerPassword({
    required int id,
    required String newPassword,
    required String confirmPassword,
    required String token,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/admin/organizers/$id/reset-password'),
      headers: _headers(token),
      body: jsonEncode({
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reset organizer password: ${response.statusCode}\n${response.body}');
    }
  }
}
