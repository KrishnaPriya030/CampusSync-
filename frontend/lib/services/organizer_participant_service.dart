
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';

class EventParticipant {
  final int registrationId;
  final int eventId;
  final int studentId;
  final String name;
  final String email;
  final String phoneNumber;
  final String registerNumber;
  final String departmentName;
  final String branchName;
  final String programme;
  final int? admissionYear;
  final int? semester;
  final String status;
  final DateTime? registeredAt;

  const EventParticipant({
    required this.registrationId,
    required this.eventId,
    required this.studentId,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.registerNumber,
    required this.departmentName,
    required this.branchName,
    required this.programme,
    required this.admissionYear,
    required this.semester,
    required this.status,
    required this.registeredAt,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      registrationId: (json['registrationId'] as num?)?.toInt() ?? 0,
      eventId: (json['eventId'] as num?)?.toInt() ?? 0,
      studentId: (json['studentId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Unknown student',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      registerNumber: json['registerNumber']?.toString() ?? '',
      departmentName: json['departmentName']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      programme: json['programme']?.toString() ?? '',
      admissionYear: (json['admissionYear'] as num?)?.toInt(),
      semester: (json['semester'] as num?)?.toInt(),
      status: json['status']?.toString() ?? 'REGISTERED',
      registeredAt: DateTime.tryParse(
        json['registeredAt']?.toString() ?? '',
      ),
    );
  }
}

class OrganizerParticipantService {
  // For Flutter Web on the same computer.
  // For a physical phone, use your computer's LAN IP address.
  static const String baseUrl = 'http://127.0.0.1:8080';

  final http.Client _client;

  OrganizerParticipantService({http.Client? client})
      : _client = client ?? http.Client();

  Future<List<EventParticipant>> getParticipants(int eventId) async {
    final token = await TokenStorage().getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }

    final uri = Uri.parse(
      '$baseUrl/api/organizer/events/$eventId/registrations',
    );

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Unexpected participant response from server.');
      }

      return decoded.map((item) {
        return EventParticipant.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception(
        'You are not authorized to view these participants.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception('Event not found.');
    }

    throw Exception(
      'Failed to load participants (HTTP ${response.statusCode}).',
    );
  }

  void dispose() {
    _client.close();
  }
}
