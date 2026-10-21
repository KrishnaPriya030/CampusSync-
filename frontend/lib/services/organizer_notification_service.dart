import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';

class OrganizerNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final String? eventTitle;

  const OrganizerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.eventTitle,
  });

  factory OrganizerNotification.fromJson(Map<String, dynamic> json) {
    final dynamic eventValue = json['event'];
    String? eventTitle;
    if (eventValue is Map) {
      final value = eventValue['title'];
      if (value != null) eventTitle = value.toString();
    }

    final dynamic readValue = json['read'] ?? json['isRead'] ?? json['readStatus'];
    final bool read = readValue == true || readValue?.toString().toLowerCase() == 'true';
    final dynamic dateValue = json['createdAt'] ?? json['created_at'];

    return OrganizerNotification(
      id: _toInt(json['id'] ?? json['notificationId']),
      title: (json['title'] ?? 'Notification').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? 'GENERAL').toString(),
      isRead: read,
      createdAt: dateValue == null ? null : DateTime.tryParse(dateValue.toString()),
      eventTitle: eventTitle,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class OrganizerNotificationService {
  static const String baseUrl = 'http://127.0.0.1:8080';
  final http.Client _client;

  OrganizerNotificationService({http.Client? client})
      : _client = client ?? http.Client();

  Future<String> _authorizationHeader() async {
    final token = await TokenStorage().getToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('Your session has expired. Please log in again.');
    }
    return 'Bearer ${token.trim()}';
  }

  Future<List<OrganizerNotification>> getNotifications() async {
    final auth = await _authorizationHeader();
    final response = await _client.get(
      Uri.parse('$baseUrl/api/notifications'),
      headers: {'Accept': 'application/json', 'Authorization': auth},
    );
    _checkResponse(response, const {200});
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('The notifications API returned an unexpected format.');
    }
    return decoded
        .whereType<Map>()
        .map((item) => OrganizerNotification.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final auth = await _authorizationHeader();
    final response = await _client.get(
      Uri.parse('$baseUrl/api/notifications/unread-count'),
      headers: {'Accept': 'application/json', 'Authorization': auth},
    );
    _checkResponse(response, const {200});
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is int) return decoded;
    return int.tryParse(decoded.toString()) ?? 0;
  }

  Future<void> markAsRead(int notificationId) async {
    final auth = await _authorizationHeader();
    final response = await _client.put(
      Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
      headers: {'Accept': 'application/json', 'Authorization': auth},
    );
    _checkResponse(response, const {200});
  }

  Future<void> markAllAsRead() async {
    final auth = await _authorizationHeader();
    final response = await _client.put(
      Uri.parse('$baseUrl/api/notifications/read-all'),
      headers: {'Accept': 'application/json', 'Authorization': auth},
    );
    _checkResponse(response, const {204, 200});
  }

  void _checkResponse(http.Response response, Set<int> accepted) {
    if (accepted.contains(response.statusCode)) return;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('You are not authorized to view these notifications '
          '(HTTP ${response.statusCode}). Please log in again.');
    }
    throw Exception('Notification request failed (HTTP ${response.statusCode}): '
        '${response.body.isEmpty ? 'No response details.' : response.body}');
  }

  void dispose() => _client.close();
}
