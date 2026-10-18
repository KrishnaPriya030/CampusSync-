import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

/// Student endpoints confirmed in the supplied CampusSync backend controllers.
class StudentPortalService {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please sign in again.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<dynamic> _get(String path) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response, 'Request failed (${response.statusCode})'));
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<dynamic> _put(String path) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_message(response, 'Request failed (${response.statusCode})'));
    }
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(response.body);
  }

  String _message(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return (decoded['message'] ?? decoded['error'] ?? fallback).toString();
      }
    } catch (_) {}
    return response.body.trim().isEmpty ? fallback : response.body;
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (value is Map && value['content'] is List) return _asList(value['content']);
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getMyCertificates() async =>
      _asList(await _get('/api/student/certificates'));

  Future<Map<String, dynamic>> getMyAttendance(int registrationId) async {
    final value = await _get('/api/student/registrations/$registrationId/attendance');
    if (value is Map) return Map<String, dynamic>.from(value);
    throw Exception('Unexpected attendance response.');
  }

  Future<List<Map<String, dynamic>>> getNotifications() async =>
      _asList(await _get('/api/notifications'));

  Future<int> getUnreadCount() async {
    final value = await _get('/api/notifications/unread-count');
    if (value is num) return value.toInt();
    if (value is Map && value['count'] is num) return (value['count'] as num).toInt();
    return int.tryParse('$value') ?? 0;
  }

  Future<void> markNotificationRead(int id) async {
    await _put('/api/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _put('/api/notifications/read-all');
  }
}
