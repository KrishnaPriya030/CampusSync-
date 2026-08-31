import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/organization.dart';

class AdminOrganizationService {
  static const String baseUrl =
      'http://127.0.0.1:8080';

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // GET ALL ORGANIZATIONS
  // GET /api/admin/organizations
  // ============================================================

  Future<List<Organization>> getAllOrganizations(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/organizations'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load organizations: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw Exception(
        'Invalid organizations response',
      );
    }

    return decoded
        .map(
          (item) => Organization.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // ============================================================
  // GET ORGANIZATION BY ID
  // GET /api/admin/organizations/{id}
  // ============================================================

  Future<Organization> getOrganizationById(
    int id,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/admin/organizations/$id',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load organization: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid organization response',
      );
    }

    return Organization.fromJson(decoded);
  }

  // ============================================================
  // CREATE ORGANIZATION
  // POST /api/admin/organizations
  // ============================================================

  Future<Organization> createOrganization(
    Map<String, dynamic> request,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/organizations'),
      headers: _headers(token),
      body: jsonEncode(request),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Failed to create organization: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid create organization response',
      );
    }

    return Organization.fromJson(decoded);
  }

  // ============================================================
  // UPDATE ORGANIZATION
  // PUT /api/admin/organizations/{id}
  // ============================================================

  Future<Organization> updateOrganization(
    int id,
    Map<String, dynamic> request,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/api/admin/organizations/$id',
      ),
      headers: _headers(token),
      body: jsonEncode(request),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update organization: '
        '${response.statusCode}\n'
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid update organization response',
      );
    }

    return Organization.fromJson(decoded);
  }

  // ============================================================
  // ACTIVATE ORGANIZATION
  // PUT /api/admin/organizations/{id}/activate
  // ============================================================

  Future<Organization> activateOrganization(
    int id,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/api/admin/organizations/$id/activate',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to activate organization: '
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

    return Organization.fromJson(decoded);
  }

  // ============================================================
  // DEACTIVATE ORGANIZATION
  // PUT /api/admin/organizations/{id}/deactivate
  // ============================================================

  Future<Organization> deactivateOrganization(
    int id,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/api/admin/organizations/$id/deactivate',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to deactivate organization: '
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

    return Organization.fromJson(decoded);
  }
  
}