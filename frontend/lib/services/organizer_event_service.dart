import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/event.dart';
import '../storage/token_storage.dart';

/// Client for the verified /api/organizer/events backend routes.
/// This service intentionally does not call unverified participant/analytics routes.
class OrganizerEventService {
  final TokenStorage _tokenStorage = TokenStorage();
  static const String _basePath = '/api/organizer/events';

  Future<String> _requireToken() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found. Please log in again.');
    }
    return token;
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  String _message(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    } catch (_) {}
    return fallback;
  }

  Never _throwResponse(http.Response response, String action) {
    final fallback = '$action failed (${response.statusCode}).';
    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }
    if (response.statusCode == 403) {
      throw Exception('You do not have permission to $action.');
    }
    if (response.statusCode == 404) {
      throw Exception('The requested event was not found.');
    }
    throw Exception(_message(response.body, fallback));
  }

  Future<List<Event>> getMyEvents() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$_basePath'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) _throwResponse(response, 'Load events');
    final decoded = jsonDecode(response.body);
    if (decoded is! List) throw Exception('Unexpected events response from server.');
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Event.fromJson)
        .toList();
  }

  Future<Event> getEvent(int eventId) async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$_basePath/$eventId'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) _throwResponse(response, 'Load event');
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    final token = await _requireToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$_basePath'),
      headers: _headers(token),
      body: jsonEncode(eventData),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      _throwResponse(response, 'Create event');
    }
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Event> updateEvent(int eventId, Map<String, dynamic> eventData) async {
    final token = await _requireToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}$_basePath/$eventId'),
      headers: _headers(token),
      body: jsonEncode(eventData),
    );
    if (response.statusCode != 200) _throwResponse(response, 'Update event');
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Event> submitForApproval(int eventId) =>
      _eventAction(eventId, 'submit', 'Submit event for approval');

  Future<Event> publishEvent(int eventId) =>
      _eventAction(eventId, 'publish', 'Publish event');

  Future<Event> cancelEvent(int eventId) =>
      _eventAction(eventId, 'cancel', 'Cancel event');

  Future<Event> _eventAction(int eventId, String action, String label) async {
    final token = await _requireToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}$_basePath/$eventId/$action'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) _throwResponse(response, label);
    return Event.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteEvent(int eventId) async {
    final token = await _requireToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$_basePath/$eventId'),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      _throwResponse(response, 'Delete event');
    }
  }

  Future<Map<String, dynamic>> getOrganizerProfile() async {
    final token = await _requireToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/organizer/me'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) _throwResponse(response, 'Load organizer profile');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
