import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/bulk_student_import_response.dart';
import '../models/department_head.dart';

class AdminDepartmentHeadService {
  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<DepartmentHead>> getAllDepartmentHeads(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/department-heads',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load department heads: '
        '${response.statusCode}\n${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw Exception('Invalid department heads response');
    }

    return decoded
        .map(
          (item) => DepartmentHead.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<DepartmentHead> getDepartmentHeadById(
    int id,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/department-heads/$id',
      ),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load department head: '
        '${response.statusCode}\n${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid department head response');
    }

    return DepartmentHead.fromJson(decoded);
  }

  Future<DepartmentHead> activateDepartmentHead(
    int id,
    String token,
  ) async {
    return _changeStatus(
      id,
      token,
      'activate',
      'activate department head',
    );
  }

  Future<DepartmentHead> blockDepartmentHead(
    int id,
    String token,
  ) async {
    return _changeStatus(
      id,
      token,
      'block',
      'block department head',
    );
  }

  Future<DepartmentHead> _changeStatus(
    int id,
    String token,
    String action,
    String description,
  ) async {
    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/admin/department-heads/$id/$action',
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

    return DepartmentHead.fromJson(decoded);
  }

  Future<BulkStudentImportResponse> importDepartmentHeads(
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
        '${ApiConfig.baseUrl}/api/admin/department-heads/import',
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
        'Failed to import department heads: '
        '${response.statusCode}\n${response.body}',
      );
    }

    if (response.body.isEmpty) {
      throw Exception('Empty department head import response');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid department head import response');
    }

    return BulkStudentImportResponse.fromJson(decoded);
  }
  Future<void> resetPassword(
  int id,
  String newPassword,
  String confirmPassword,
  String token,
) async {
  final response = await http.put(
    Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/department-heads/$id/reset-password',
    ),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(
      response.body.isNotEmpty
          ? response.body
          : 'Failed to reset password',
    );
  }
}
}
