import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/event.dart';
import '../storage/token_storage.dart';

class StudentEventService {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<List<Event>> getPublishedEvents() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/student/events'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => Event.fromJson(json))
          .toList();
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    }

    if (response.statusCode == 403) {
      throw Exception('You do not have access to student events.');
    }

    throw Exception(
      'Failed to load events (${response.statusCode})',
    );
  }

  Future<Event> getPublishedEvent(int eventId) async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/student/events/$eventId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Event.fromJson(
        jsonDecode(response.body),
      );
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please login again.');
    }

    if (response.statusCode == 403) {
      throw Exception('You do not have access to this event.');
    }

    if (response.statusCode == 404) {
      throw Exception('Event not found.');
    }

    throw Exception(
      'Failed to load event (${response.statusCode})',
    );
  }
}