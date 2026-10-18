
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class NotificationService {
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

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/notifications$path',
    );
    final headers = await _headers();

    late http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
        break;
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }

    if (response.statusCode == 204) return null;

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

    if (response.statusCode == 403) {
      throw Exception('You do not have permission to access notifications.');
    }

    final message = data is Map
        ? data['message'] ?? data['error']
        : null;

    throw Exception(
      message?.toString() ??
          'Notification request failed (${response.statusCode}).',
    );
  }

  Future<List<Map<String, dynamic>>> getMyNotifications() async {
    final data = await _request('GET', '');

    if (data is! List) {
      throw Exception('Unexpected notifications response from server.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final data = await _request('GET', '/unread');

    if (data is! List) {
      throw Exception('Unexpected unread notifications response.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final data = await _request('GET', '/unread-count');

    if (data is num) return data.toInt();

    if (data is String) {
      return int.tryParse(data) ?? 0;
    }

    throw Exception('Unexpected unread notification count.');
  }

  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    if (notificationId <= 0) {
      throw ArgumentError('Invalid notification ID.');
    }

    final data = await _request(
      'PUT',
      '/$notificationId/read',
    );

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  Future<void> markAllAsRead() async {
    await _request('PUT', '/read-all');
  }
}
