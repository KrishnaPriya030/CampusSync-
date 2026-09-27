import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/bulk_student_import_response.dart';
import '../models/organization_head.dart';

class AdminOrganizationHeadService {
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<OrganizationHead>> getAllOrganizationHeads(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/organization-heads',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load organization heads: '
        '${response.statusCode}\n${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid organization heads response');
    }

    return decoded
        .map(
          (item) => OrganizationHead.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<OrganizationHead> getOrganizationHeadById(
    int id,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/organization-heads/$id',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load organization head: '
        '${response.statusCode}\n${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid organization head response');
    }

    return OrganizationHead.fromJson(decoded);
  }

  Future<OrganizationHead> activateOrganizationHead(
    int id,
    String token,
  ) async {
    return _changeStatus(
      id,
      token,
      'activate',
      'activate organization head',
    );
  }

  Future<OrganizationHead> blockOrganizationHead(
    int id,
    String token,
  ) async {
    return _changeStatus(
      id,
      token,
      'block',
      'block organization head',
    );
  }

  Future<OrganizationHead> _changeStatus(
    int id,
    String token,
    String action,
    String description,
  ) async {
    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/organization-heads/$id/$action',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to $description: '
        '${response.statusCode}\n${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid status response');
    }

    return OrganizationHead.fromJson(decoded);
  }

  Future<BulkStudentImportResponse> importOrganizationHeads(
    List<int> fileBytes,
    String fileName,
    String token,
  ) async {
    if (fileBytes.isEmpty) {
      throw Exception('Selected file is empty');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/organization-heads/import',
      ),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(
      streamedResponse,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to import organization heads: '
        '${response.statusCode}\n${response.body}',
      );
    }

    if (response.body.isEmpty) {
      throw Exception('Empty organization head import response');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid organization head import response');
    }

    return BulkStudentImportResponse.fromJson(decoded);
  }
}
