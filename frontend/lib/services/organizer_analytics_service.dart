
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/organizer_analytics.dart';

class OrganizerAnalyticsService {
  // Flutter Web on the same computer.
  // For a physical Android phone, use your computer's LAN IPv4 address.
  static const String baseUrl = 'http://127.0.0.1:8080';

  final Future<String?> Function() getToken;
  final http.Client _client;

  OrganizerAnalyticsService({
    required this.getToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<OrganizerAnalytics> fetchAnalytics() async {
    final token = await getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception(
        'Your session has expired. Please log in again.',
      );
    }

    final uri = Uri.parse(
      '$baseUrl/api/organizer/events/analytics',
    );

    late final http.Response response;

    try {
      response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${token.trim()}',
        },
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Could not connect to the analytics API. '
        'Check that the backend is running at $baseUrl. Details: $e',
      );
    } catch (e) {
      throw Exception(
        'Unexpected error while requesting analytics: $e',
      );
    }

    if (response.statusCode == 200) {
      try {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw const FormatException(
            'Expected a JSON object from the analytics API.',
          );
        }

        return OrganizerAnalytics.fromJson(decoded);
      } on FormatException catch (e) {
        throw Exception(
          'The analytics API returned invalid JSON: $e',
        );
      } catch (e) {
        throw Exception(
          'Could not parse the analytics response. Details: $e',
        );
      }
    }

    final body = response.body.trim();
    final errorBody = body.isEmpty ? '(empty response body)' : body;

    switch (response.statusCode) {
      case 400:
        throw Exception(
          'Bad Request (HTTP 400) from the analytics API.\n'
          'URL: $uri\n'
          'Backend response: $errorBody',
        );

      case 401:
        throw Exception(
          'Unauthorized (HTTP 401). Your session may have expired. '
          'Please log in again.\n'
          'Backend response: $errorBody',
        );

      case 403:
        throw Exception(
          'Forbidden (HTTP 403). Your account may not have permission '
          'to view organizer analytics.\n'
          'Backend response: $errorBody',
        );

      case 404:
        throw Exception(
          'Analytics endpoint not found (HTTP 404).\n'
          'Check whether the backend defines GET $uri.',
        );

      case 500:
        throw Exception(
          'Internal server error (HTTP 500) in the backend analytics API.\n'
          'Backend response: $errorBody',
        );

      default:
        throw Exception(
          'Could not load analytics.\n'
          'HTTP status: ${response.statusCode}\n'
          'URL: $uri\n'
          'Backend response: $errorBody',
        );
    }
  }

  void dispose() {
    _client.close();
  }
}
