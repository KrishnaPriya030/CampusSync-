
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class AttendanceService {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = await _headers();

    final response = method == 'GET'
        ? await http.get(uri, headers: headers)
        : await http.put(
            uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          );

    dynamic data;

    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }

    final message = data is Map
        ? data['message'] ?? data['error']
        : null;

    throw Exception(
      message?.toString() ??
          'Attendance request failed (${response.statusCode}).',
    );
  }

  Future<List<Map<String, dynamic>>> getEventAttendance(
    int eventId,
  ) async {
    if (eventId <= 0) throw ArgumentError('Invalid event ID.');

    final data = await _send(
      'GET',
      '/api/organizer/events/$eventId/attendance',
    );

    if (data is! List) {
      throw Exception('Unexpected attendance response from server.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> markAttendance({
    required int eventId,
    required int registrationId,
    required String status,
  }) async {
    if (eventId <= 0 || registrationId <= 0) {
      throw ArgumentError('Invalid event or registration ID.');
    }

    final normalizedStatus = status.toUpperCase();

    if (!{'PRESENT', 'ABSENT'}.contains(normalizedStatus)) {
      throw ArgumentError('Attendance status must be PRESENT or ABSENT.');
    }

    final data = await _send(
      'PUT',
      '/api/organizer/events/$eventId/attendance/$registrationId',
      body: {'status': normalizedStatus},
    );

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Unexpected response after marking attendance.');
  }

  Future<Map<String, dynamic>> getMyAttendance(
    int registrationId,
  ) async {
    if (registrationId <= 0) {
      throw ArgumentError('Invalid registration ID.');
    }

    final data = await _send(
      'GET',
      '/api/student/registrations/$registrationId/attendance',
    );

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Unexpected student attendance response.');
  }
}
