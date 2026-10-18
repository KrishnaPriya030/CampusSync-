import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

/// HTTP client for Organizer operations whose routes are present in the
/// supplied CampusSync backend controllers.
class OrganizerOperationsService {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: query);
    final headers = await _headers(jsonBody: body != null);
    late http.Response response;
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(uri, headers: headers,
            body: body == null ? null : jsonEncode(body));
        break;
      case 'PUT':
        response = await http.put(uri, headers: headers,
            body: body == null ? null : jsonEncode(body));
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          message = (decoded['message'] ?? decoded['error'] ?? message).toString();
        } else if (response.body.trim().isNotEmpty) {
          message = response.body;
        }
      } catch (_) {
        if (response.body.trim().isNotEmpty) message = response.body;
      }
      throw Exception(message);
    }
    if (response.statusCode == 204 || response.body.trim().isEmpty) return null;
    return jsonDecode(response.body);
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (value is Map && value['content'] is List) {
      return _list(value['content']);
    }
    return <Map<String, dynamic>>[];
  }

  Future<List<Map<String, dynamic>>> getPayments() async =>
      _list(await _send('GET', '/api/organizer/payments'));
  Future<dynamic> approvePayment(int id) =>
      _send('PUT', '/api/organizer/payments/$id/approve');
  Future<dynamic> rejectPayment(int id) =>
      _send('PUT', '/api/organizer/payments/$id/reject');

  Future<List<Map<String, dynamic>>> getRefunds() async =>
      _list(await _send('GET', '/api/organizer/refunds'));
  Future<dynamic> approveRefund(int id, {String note = ''}) =>
      _send('PUT', '/api/organizer/refunds/$id/approve', query: {'note': note});
  Future<dynamic> rejectRefund(int id, {String note = ''}) =>
      _send('PUT', '/api/organizer/refunds/$id/reject', query: {'note': note});

  Future<List<Map<String, dynamic>>> getNotifications() async =>
      _list(await _send('GET', '/api/notifications'));
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async =>
      _list(await _send('GET', '/api/notifications/unread'));
  Future<int> getUnreadCount() async {
    final value = await _send('GET', '/api/notifications/unread-count');
    if (value is num) return value.toInt();
    if (value is Map && value['count'] is num) return (value['count'] as num).toInt();
    return int.tryParse('$value') ?? 0;
  }
  Future<dynamic> markNotificationRead(int id) =>
      _send('PUT', '/api/notifications/$id/read');
  Future<dynamic> markAllNotificationsRead() =>
      _send('PUT', '/api/notifications/read-all');

  Future<List<Map<String, dynamic>>> getRegistrations(int eventId) async =>
      _list(await _send('GET', '/api/organizer/events/$eventId/registrations'));
  Future<List<Map<String, dynamic>>> getAttendance(int eventId) async =>
      _list(await _send('GET', '/api/organizer/events/$eventId/attendance'));
  Future<dynamic> markAttendance(int eventId, int registrationId, String status) =>
      _send('PUT', '/api/organizer/events/$eventId/attendance/$registrationId',
          body: {'status': status});

  Future<List<Map<String, dynamic>>> getCertificates(int eventId) async =>
      _list(await _send('GET', '/api/organizer/events/$eventId/certificates'));
  Future<dynamic> issueCertificate(int eventId, int studentId) =>
      _send('POST', '/api/organizer/events/$eventId/certificates/$studentId');
}
