import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/api_config.dart';

import '../models/organizer.dart';
import '../models/activate_organizer_request.dart';
import '../config/api_config.dart';

class CreateOrganizerRequest {
  final String name;
  final String email;
  final String? phoneNumber;
  final int organizationId;
  final String designation;

  const CreateOrganizerRequest({
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.organizationId,
    required this.designation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'organizationId': organizationId,
      'designation': designation,
    };
  }
}

class CreateOrganizerResponse {
  final int userId;
  final int organizerId;
  final String name;
  final String email;
  final String activationLink;
  final String organizationName;
  final String designation;

  const CreateOrganizerResponse({
    required this.userId,
    required this.organizerId,
    required this.name,
    required this.email,
    required this.activationLink,
    required this.organizationName,
    required this.designation,
  });

  factory CreateOrganizerResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreateOrganizerResponse(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      organizerId:
          (json['organizerId'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      activationLink:
          json['activationLink']?.toString() ?? '',
      organizationName:
          json['organizationName']?.toString() ?? '',
      designation:
          json['designation']?.toString() ?? '',
    );
  }
}

class AdminOrganizerService {
  
  // ============================================================
  // JSON HEADERS
  // ============================================================

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET ALL ORGANIZERS
  // GET /api/admin/organizers
  // ============================================================

  Future<List<Organizer>> getAllOrganizers(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/organizers',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load organizers: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception(
        'Invalid organizers response',
      );
    }

    return decoded
        .map(
          (item) => Organizer.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // GET ORGANIZER BY ID
  // GET /api/admin/organizers/{id}
  // ============================================================

  Future<Organizer> getOrganizerById(
    int id,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/organizers/$id',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load organizer: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid organizer response',
      );
    }

    return Organizer.fromJson(decoded);
  }

  // ============================================================
  // CREATE ORGANIZER
  // POST /api/admin/organizers
  // ============================================================

  Future<CreateOrganizerResponse> createOrganizer(
    CreateOrganizerRequest request,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/organizers',
      ),
      headers: _headers(token),
      body: jsonEncode(
        request.toJson(),
      ),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Failed to create organizer: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid create organizer response',
      );
    }

    return CreateOrganizerResponse.fromJson(
      decoded,
    );
  }

  // ============================================================
  // ADMIN ACTIVATE ORGANIZER
  // PUT /api/admin/organizers/{id}/activate
  // ============================================================

  Future<Organizer> activateOrganizer(
    int id,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/organizers/$id/activate',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to activate organizer: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid activation response',
      );
    }

    return Organizer.fromJson(decoded);
  }

  // ============================================================
  // ADMIN DEACTIVATE / BLOCK ORGANIZER
  // PUT /api/admin/organizers/{id}/block
  // ============================================================

  Future<Organizer> deactivateOrganizer(
    int id,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$ApiConfig.baseUrl/api/admin/organizers/$id/block',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to deactivate organizer: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid deactivation response',
      );
    }

    return Organizer.fromJson(decoded);
  }

  // ============================================================
  // ORGANIZER ACCOUNT ACTIVATION
  // POST /api/auth/organizer/activate
  //
  // This is NOT the same as the Admin activate button above.
  //
  // Admin activate:
  // PUT /api/admin/organizers/{id}/activate
  //
  // Organizer activation link:
  // POST /api/auth/organizer/activate
  // ============================================================

  Future<void> activateAccount(
    ActivateOrganizerRequest request,
  ) async {
    final response = await http.post(
      Uri.parse(
        '$ApiConfig.baseUrl/api/auth/organizer/activate',
      ),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        request.toJson(),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to activate organizer account: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }
  }
}